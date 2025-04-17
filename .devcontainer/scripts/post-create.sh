#!/bin/bash
set -e

# Ensure proper permissions for .vscode-server directory
sudo mkdir -p /home/vscode/.vscode-server/bin /home/vscode/.vscode-server/extensions
sudo touch /home/vscode/.vscode-server/first-run
sudo chown -R vscode:vscode /home/vscode/.vscode-server

# Create directory if it doesn't exist
mkdir -p ~/.devcontainer/scripts

# Check PowerShell version and update if needed
if command -v pwsh &> /dev/null; then
    PS_VERSION=$(pwsh -Command "\$PSVersionTable.PSVersion.ToString()")
    echo "Current PowerShell version: $PS_VERSION"

    # Check if version is less than 7.5.0
    if [[ "$PS_VERSION" < "7.5.0" ]]; then
        echo "Updating PowerShell to version 7.5.0..."
        # Download and install PowerShell 7.5.0
        ARCH=$(uname -m)
        if [ "$ARCH" = "aarch64" ]; then
            curl -L -o /tmp/powershell.tar.gz https://github.com/PowerShell/PowerShell/releases/download/v7.5.0/powershell-7.5.0-linux-arm64.tar.gz
        else
            curl -L -o /tmp/powershell.tar.gz https://github.com/PowerShell/PowerShell/releases/download/v7.5.0/powershell-7.5.0-linux-x64.tar.gz
        fi
        sudo mkdir -p /opt/microsoft/powershell/7
        sudo tar zxf /tmp/powershell.tar.gz -C /opt/microsoft/powershell/7
        sudo chmod +x /opt/microsoft/powershell/7/pwsh
        sudo ln -sf /opt/microsoft/powershell/7/pwsh /usr/bin/pwsh
        rm /tmp/powershell.tar.gz

        # Verify the update
        NEW_PS_VERSION=$(pwsh -Command "\$PSVersionTable.PSVersion.ToString()")
        echo "PowerShell updated to version: $NEW_PS_VERSION"
    fi
else
    echo "PowerShell not found. Installing PowerShell 7.5.0..."
    # Install PowerShell 7.5.0
    ARCH=$(uname -m)
    if [ "$ARCH" = "aarch64" ]; then
        curl -L -o /tmp/powershell.tar.gz https://github.com/PowerShell/PowerShell/releases/download/v7.5.0/powershell-7.5.0-linux-arm64.tar.gz
    else
        curl -L -o /tmp/powershell.tar.gz https://github.com/PowerShell/PowerShell/releases/download/v7.5.0/powershell-7.5.0-linux-x64.tar.gz
    fi
    sudo mkdir -p /opt/microsoft/powershell/7
    sudo tar zxf /tmp/powershell.tar.gz -C /opt/microsoft/powershell/7
    sudo chmod +x /opt/microsoft/powershell/7/pwsh
    sudo ln -sf /opt/microsoft/powershell/7/pwsh /usr/bin/pwsh
    rm /tmp/powershell.tar.gz
fi

# Install PowerShell modules for testing and linting if PowerShell is available
if command -v pwsh &> /dev/null; then
    echo "Installing PowerShell modules for testing and linting..."
    pwsh -Command "Install-Module -Name Pester -Force -Scope CurrentUser -SkipPublisherCheck"
    pwsh -Command "Install-Module -Name PSScriptAnalyzer -Force -Scope CurrentUser -SkipPublisherCheck"
    pwsh -Command "Install-Module -Name PSRule.Rules.Azure -Force -Scope CurrentUser -SkipPublisherCheck"
    pwsh -Command "Install-Module -Name Az.Tools.Predictor -Force -Scope CurrentUser -SkipPublisherCheck"
else
    echo "PowerShell not found. Skipping PowerShell module installation."
fi

# Install ARM-TTK (ARM Template Toolkit) if PowerShell is available
if command -v pwsh &> /dev/null; then
    echo "Installing ARM Template Toolkit..."
    git clone --depth 1 https://github.com/Azure/arm-ttk.git ~/arm-ttk
    chmod -R +x ~/arm-ttk
else
    echo "PowerShell not found. Skipping ARM-TTK installation."
fi

# Configure Azure CLI defaults if environment variables are set
if [ -n "$AZURE_DEFAULTS_GROUP" ]; then
    az configure --defaults group="$AZURE_DEFAULTS_GROUP"
fi

if [ -n "$AZURE_DEFAULTS_LOCATION" ]; then
    az configure --defaults location="$AZURE_DEFAULTS_LOCATION"
fi

# Setup instructions for Azure and Git credentials
printf "\n===== Azure and Git Authentication Setup =====\n"
echo "Since we're not mounting host credentials directly, you'll need to authenticate:"
echo "1. For Azure: Run 'az login' to authenticate with your Azure account"
echo "2. For GitHub: Run 'gh auth login' to authenticate with your GitHub account"
echo "3. For Git: Configure your Git identity with:"
echo "   git config --global user.name \"Your Name\""
echo "   git config --global user.email \"your.email@example.com\""
printf "================================================\n\n"

# Create PowerShell profile if PowerShell is available
if command -v pwsh &> /dev/null; then
    echo "Creating PowerShell profile..."
    mkdir -p ~/.config/powershell
    cat > ~/.config/powershell/Microsoft.PowerShell_profile.ps1 << 'EOF'
# Import modules
Import-Module Az.Tools.Predictor -ErrorAction SilentlyContinue
Import-Module PSRule.Rules.Azure -ErrorAction SilentlyContinue
Import-Module PSScriptAnalyzer -ErrorAction SilentlyContinue
Import-Module Pester -ErrorAction SilentlyContinue

# Set up ARM-TTK path
$env:PATH += ":$HOME/arm-ttk"

# Create functions for testing
function Test-BicepTemplate {
    param(
        [Parameter(Mandatory = $true)]
        [string]$TemplateFile
    )

    Write-Host "Building and validating Bicep template: $TemplateFile" -ForegroundColor Cyan

    # Build Bicep to ARM
    $armTemplateFile = [System.IO.Path]::ChangeExtension($TemplateFile, "json")
    bicep build $TemplateFile --outfile $armTemplateFile

    # Validate with ARM-TTK
    Write-Host "Running ARM-TTK tests..." -ForegroundColor Cyan
    & $HOME/arm-ttk/arm-ttk.ps1 Test-AzTemplate -TemplatePath $armTemplateFile

    # Validate with PSRule
    Write-Host "Running PSRule for Azure tests..." -ForegroundColor Cyan
    $rulePath = Join-Path -Path (Get-Module PSRule.Rules.Azure).ModuleBase -ChildPath 'rules'
    $result = $armTemplateFile | Assert-PSRule -Module PSRule.Rules.Azure -Path $rulePath
    $result | Format-Table -Property RuleName, Outcome

    # Validate with Azure CLI what-if
    Write-Host "To perform a what-if deployment, run:" -ForegroundColor Yellow
    Write-Host "az deployment group what-if --resource-group <resource-group-name> --template-file $armTemplateFile" -ForegroundColor Yellow
}

function Test-PowerShellScript {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ScriptPath
    )

    Write-Host "Analyzing PowerShell script: $ScriptPath" -ForegroundColor Cyan

    # Run PSScriptAnalyzer
    Write-Host "Running PSScriptAnalyzer..." -ForegroundColor Cyan
    Invoke-ScriptAnalyzer -Path $ScriptPath

    # Check for Pester tests
    $pesterTestPath = [System.IO.Path]::ChangeExtension($ScriptPath, ".Tests.ps1")
    if (Test-Path $pesterTestPath) {
        Write-Host "Running Pester tests..." -ForegroundColor Cyan
        Invoke-Pester -Path $pesterTestPath -PassThru
    } else {
        Write-Host "No Pester tests found for $ScriptPath" -ForegroundColor Yellow
    }
}

# Enable Azure CLI tab completion
Register-ArgumentCompleter -Native -CommandName az -ScriptBlock {
    param($commandName, $wordToComplete, $cursorPosition)
    $completion = $(az completion script | Out-String)
    $completions = @($completion | Invoke-Expression)
    $wordToComplete = $wordToComplete.Replace('"', '\"')
    $completions | Where-Object { $_ -like "*$wordToComplete*" } | ForEach-Object { '"' + $_ + '"' }
}

# Set PSReadLine options for better command history
if (Get-Module -Name PSReadLine -ListAvailable) {
    Set-PSReadLineOption -PredictionSource HistoryAndPlugin -ErrorAction SilentlyContinue
    Set-PSReadLineOption -PredictionViewStyle ListView -ErrorAction SilentlyContinue
    Set-PSReadLineOption -EditMode Windows -ErrorAction SilentlyContinue
}

# Set aliases
Set-Alias -Name g -Value git

# Welcome message
Write-Host "Welcome to Nucleus - Azure IaC Development Container" -ForegroundColor Green
Write-Host "Tools available:" -ForegroundColor Yellow
Write-Host " - Azure CLI with extensions" -ForegroundColor Yellow
Write-Host " - Bicep CLI" -ForegroundColor Yellow
Write-Host " - PowerShell Core with Azure modules" -ForegroundColor Yellow
Write-Host " - ARM Template Toolkit (ARM-TTK)" -ForegroundColor Yellow
Write-Host " - PSRule for Azure" -ForegroundColor Yellow
Write-Host " - Pester for PowerShell testing" -ForegroundColor Yellow
Write-Host " - PSScriptAnalyzer for PowerShell linting" -ForegroundColor Yellow
Write-Host " - GitHub CLI" -ForegroundColor Yellow
Write-Host "
Testing commands available:" -ForegroundColor Cyan
Write-Host " - Test-BicepTemplate -TemplateFile <path>" -ForegroundColor Cyan
Write-Host " - Test-PowerShellScript -ScriptPath <path>" -ForegroundColor Cyan
Write-Host " - Invoke-Pester -Path <path>" -ForegroundColor Cyan
Write-Host " - az deployment group what-if" -ForegroundColor Cyan
EOF

fi

# Create bash aliases
cat >> ~/.bashrc << 'EOF'

# Azure CLI aliases
alias azls='az resource list --output table'
alias azrg='az group list --output table'
alias azwhatif='az deployment group what-if'

# Git aliases
alias g='git'
alias gs='git status'
alias gl='git log --oneline --graph --decorate'

# ARM-TTK alias if PowerShell is available
if command -v pwsh &> /dev/null; then
    alias arm-ttk='pwsh -Command ~/arm-ttk/arm-ttk.ps1'
fi
EOF

# Source the updated bashrc
# shellcheck source=/dev/null
source ~/.bashrc

echo "Post-create setup complete!"
