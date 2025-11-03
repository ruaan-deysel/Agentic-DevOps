#!/bin/bash
set -e

echo "===== Starting Post-Create Setup ====="

# Ensure proper permissions for .vscode-server directory
sudo mkdir -p /home/vscode/.vscode-server/bin /home/vscode/.vscode-server/extensions
sudo touch /home/vscode/.vscode-server/first-run
sudo chown -R vscode:vscode /home/vscode/.vscode-server

# Create directory if it doesn't exist
mkdir -p ~/.devcontainer/scripts

# Verify installed tool versions
echo ""
echo "===== Verifying Installed Tools ====="
echo ""
echo "Core Tools:"
echo "  PowerShell: $(pwsh -Command "\$PSVersionTable.PSVersion.ToString()" 2>/dev/null || echo 'Not installed')"
echo "  Azure CLI: $(az version --query '"azure-cli"' -o tsv 2>/dev/null || echo 'Not installed')"
echo "  Python: $(python3 --version 2>/dev/null || echo 'Not installed')"
echo "  GitHub CLI: $(gh --version 2>/dev/null | head -n1 || echo 'Not installed')"
echo ""
echo "IaC Tools:"
echo "  Bicep: $(bicep --version 2>/dev/null || echo 'Not installed')"
echo "  Terraform: $(terraform version -json 2>/dev/null | grep -o '"version":"[^"]*' | cut -d'"' -f4 || echo 'Not installed')"
echo "  Ansible: $(ansible --version 2>/dev/null | head -n1 || echo 'Not installed')"
echo ""
echo "Security Scanning:"
echo "  Trivy: $(trivy --version 2>/dev/null | head -n1 || echo 'Not installed')"
echo "  Checkov: $(checkov --version 2>/dev/null || echo 'Not installed')"
echo "  Gitleaks: $(gitleaks version 2>/dev/null || echo 'Not installed')"
echo ""
echo "Kubernetes Tools:"
echo "  kubectl: $(kubectl version --client --short 2>/dev/null | head -n1 || echo 'Not installed')"
echo "  Helm: $(helm version --short 2>/dev/null || echo 'Not installed')"
echo "  k9s: $(k9s version --short 2>/dev/null || echo 'Not installed')"
echo ""
echo "DevOps Utilities:"
echo "  jq: $(jq --version 2>/dev/null || echo 'Not installed')"
echo "  yq: $(yq --version 2>/dev/null || echo 'Not installed')"
echo "  yamllint: $(yamllint --version 2>/dev/null || echo 'Not installed')"
echo "  shellcheck: $(shellcheck --version 2>/dev/null | head -n2 | tail -n1 || echo 'Not installed')"
echo "  pre-commit: $(pre-commit --version 2>/dev/null || echo 'Not installed')"
echo "  act: $(act --version 2>/dev/null || echo 'Not installed')"
echo "  git-lfs: $(git-lfs version 2>/dev/null | head -n1 || echo 'Not installed')"
echo ""
echo "======================================"
echo ""

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

# Install Azure CLI extensions for monitoring and diagnostics
echo ""
echo "Installing Azure CLI extensions..."
az extension add --name application-insights --only-show-errors 2>/dev/null || echo "application-insights extension already installed or failed"
az extension add --name log-analytics --only-show-errors 2>/dev/null || echo "log-analytics extension already installed or failed"
echo "Azure CLI extensions installed."

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
Write-Host "Welcome to Azure DevOps - IaC Development Container" -ForegroundColor Green
Write-Host ""
Write-Host "Core Tools:" -ForegroundColor Yellow
Write-Host " - Azure CLI with monitoring extensions (application-insights, log-analytics)" -ForegroundColor Yellow
Write-Host " - PowerShell Core with Azure modules" -ForegroundColor Yellow
Write-Host " - GitHub CLI" -ForegroundColor Yellow
Write-Host ""
Write-Host "IaC Tools:" -ForegroundColor Yellow
Write-Host " - Bicep CLI" -ForegroundColor Yellow
Write-Host " - Terraform $(terraform version -json 2>/dev/null | grep -o '"version":"[^"]*' | cut -d'"' -f4)" -ForegroundColor Yellow
Write-Host " - Ansible with ansible-lint" -ForegroundColor Yellow
Write-Host " - ARM Template Toolkit (ARM-TTK)" -ForegroundColor Yellow
Write-Host ""
Write-Host "Security Scanning:" -ForegroundColor Yellow
Write-Host " - Trivy (IaC security scanning)" -ForegroundColor Yellow
Write-Host " - Checkov (IaC security scanning)" -ForegroundColor Yellow
Write-Host " - Gitleaks (secret detection)" -ForegroundColor Yellow
Write-Host ""
Write-Host "Kubernetes Tools:" -ForegroundColor Yellow
Write-Host " - kubectl (Kubernetes CLI)" -ForegroundColor Yellow
Write-Host " - Helm (package manager)" -ForegroundColor Yellow
Write-Host " - k9s (terminal UI)" -ForegroundColor Yellow
Write-Host ""
Write-Host "DevOps Utilities:" -ForegroundColor Yellow
Write-Host " - jq/yq (JSON/YAML processors)" -ForegroundColor Yellow
Write-Host " - yamllint (YAML linter)" -ForegroundColor Yellow
Write-Host " - shellcheck (shell script linter)" -ForegroundColor Yellow
Write-Host " - pre-commit (git hooks framework)" -ForegroundColor Yellow
Write-Host " - act (GitHub Actions local runner)" -ForegroundColor Yellow
Write-Host " - git-lfs (large file storage)" -ForegroundColor Yellow
Write-Host ""
Write-Host "Testing & Validation Commands:" -ForegroundColor Cyan
Write-Host ""
Write-Host "Bicep/ARM:" -ForegroundColor Cyan
Write-Host " - Test-BicepTemplate -TemplateFile <path>" -ForegroundColor Cyan
Write-Host " - az bicep build --file <path>" -ForegroundColor Cyan
Write-Host " - az bicep lint --file <path>" -ForegroundColor Cyan
Write-Host " - az deployment group what-if" -ForegroundColor Cyan
Write-Host ""
Write-Host "Terraform:" -ForegroundColor Cyan
Write-Host " - terraform fmt -recursive" -ForegroundColor Cyan
Write-Host " - terraform validate" -ForegroundColor Cyan
Write-Host " - terraform plan" -ForegroundColor Cyan
Write-Host ""
Write-Host "Security Scanning:" -ForegroundColor Cyan
Write-Host " - trivy config <path>" -ForegroundColor Cyan
Write-Host " - checkov -d <path>" -ForegroundColor Cyan
Write-Host " - gitleaks detect --source ." -ForegroundColor Cyan
Write-Host " - gitleaks protect --staged" -ForegroundColor Cyan
Write-Host ""
Write-Host "YAML/Shell Validation:" -ForegroundColor Cyan
Write-Host " - yamllint <file>" -ForegroundColor Cyan
Write-Host " - shellcheck <script>" -ForegroundColor Cyan
Write-Host ""
Write-Host "Kubernetes:" -ForegroundColor Cyan
Write-Host " - kubectl apply --dry-run=client -f <manifest>" -ForegroundColor Cyan
Write-Host " - helm lint <chart>" -ForegroundColor Cyan
Write-Host " - k9s (interactive cluster UI)" -ForegroundColor Cyan
Write-Host ""
Write-Host "GitHub Actions:" -ForegroundColor Cyan
Write-Host " - act -l (list workflows)" -ForegroundColor Cyan
Write-Host " - act -n (dry run)" -ForegroundColor Cyan
Write-Host ""
Write-Host "PowerShell Testing:" -ForegroundColor Cyan
Write-Host " - Test-PowerShellScript -ScriptPath <path>" -ForegroundColor Cyan
Write-Host " - Invoke-Pester -Path <path>" -ForegroundColor Cyan
Write-Host ""
Write-Host "Use 'alias' command to see all available shortcuts!" -ForegroundColor Green
EOF

fi

# Create bash aliases
cat >> ~/.bashrc << 'EOF'

# Azure CLI aliases
alias azls='az resource list --output table'
alias azrg='az group list --output table'
alias azwhatif='az deployment group what-if'

# Terraform aliases
alias tf='terraform'
alias tfi='terraform init'
alias tfp='terraform plan'
alias tfa='terraform apply'
alias tfv='terraform validate'
alias tff='terraform fmt -recursive'

# Ansible aliases
alias ap='ansible-playbook'
alias al='ansible-lint'

# Security scanning aliases
alias trivy-scan='trivy config .'
alias checkov-scan='checkov -d .'
alias gitleaks-scan='gitleaks detect --source . --verbose'
alias gitleaks-protect='gitleaks protect --verbose --staged'

# Kubernetes aliases
alias k='kubectl'
alias kgp='kubectl get pods'
alias kgs='kubectl get services'
alias kgd='kubectl get deployments'
alias kgn='kubectl get nodes'
alias kga='kubectl get all'
alias kdp='kubectl describe pod'
alias kds='kubectl describe service'
alias kdd='kubectl describe deployment'
alias kl='kubectl logs'
alias kx='kubectl exec -it'
alias kctx='kubectl config current-context'
alias kns='kubectl config set-context --current --namespace'

# Helm aliases
alias h='helm'
alias hls='helm list'
alias hi='helm install'
alias hu='helm upgrade'
alias hd='helm delete'
alias hs='helm search'
alias hh='helm history'

# YAML/JSON processing aliases
alias yq-eval='yq eval'
alias jq-pretty='jq .'

# Git aliases
alias g='git'
alias gs='git status'
alias gl='git log --oneline --graph --decorate'
alias gp='git pull'
alias gpu='git push'

# ARM-TTK alias if PowerShell is available
if command -v pwsh &> /dev/null; then
    alias arm-ttk='pwsh -Command ~/arm-ttk/arm-ttk.ps1'
fi
EOF

# Source the updated bashrc
# shellcheck source=/dev/null
source ~/.bashrc

echo "Post-create setup complete!"
