[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [ValidateSet('dev', 'test', 'prod')]
    [string]$Environment = 'dev',
    
    [Parameter(Mandatory = $false)]
    [string]$ResourceGroupName = "rg-nucleus-aks-$Environment-local",
    
    [Parameter(Mandatory = $false)]
    [string]$Location = "eastus",
    
    [Parameter(Mandatory = $false)]
    [switch]$SkipDeployment,
    
    [Parameter(Mandatory = $false)]
    [switch]$SkipPostDeployment,
    
    [Parameter(Mandatory = $false)]
    [switch]$WhatIf
)

# Set up error handling
$ErrorActionPreference = 'Stop'
$VerbosePreference = 'Continue'

# Set up logging
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$logDir = "./logs"
if (-not (Test-Path $logDir)) {
    New-Item -Path $logDir -ItemType Directory -Force | Out-Null
}
$logFile = Join-Path $logDir "local-test-$Environment-$timestamp.log"
Start-Transcript -Path $logFile -Append

Write-Host "Starting local deployment test for environment: $Environment" -ForegroundColor Cyan
Write-Host "Resource Group: $ResourceGroupName" -ForegroundColor Cyan
Write-Host "Location: $Location" -ForegroundColor Cyan

try {
    # Check if Azure CLI is installed
    try {
        $azVersion = az --version
        Write-Host "Azure CLI is installed" -ForegroundColor Green
    } catch {
        Write-Error "Azure CLI is not installed. Please install it from https://docs.microsoft.com/en-us/cli/azure/install-azure-cli"
        exit 1
    }
    
    # Skip Azure login check when running in WhatIf mode
    if ($WhatIf) {
        Write-Host "Skipping Azure login check due to -WhatIf flag" -ForegroundColor Yellow
    } else {
        # Check if user is logged in to Azure
        try {
            $account = az account show
            if (-not $account) {
                throw "Not logged in"
            }
            $accountObj = $account | ConvertFrom-Json
            Write-Host "Logged in to Azure as $($accountObj.user.name)" -ForegroundColor Green
            Write-Host "Subscription: $($accountObj.name) ($($accountObj.id))" -ForegroundColor Green
        } catch {
            Write-Host "Not logged in to Azure. Please log in..." -ForegroundColor Yellow
            az login
            $account = az account show
            if (-not $account) {
                Write-Error "Failed to log in to Azure"
                exit 1
            }
            $accountObj = $account | ConvertFrom-Json
            Write-Host "Logged in to Azure as $($accountObj.user.name)" -ForegroundColor Green
            Write-Host "Subscription: $($accountObj.name) ($($accountObj.id))" -ForegroundColor Green
        }
    }
    
    # Check if Bicep is installed
    try {
        $bicepVersion = az bicep version
        Write-Host "Bicep is installed" -ForegroundColor Green
    } catch {
        Write-Host "Installing Bicep..." -ForegroundColor Yellow
        az bicep install
        if ($LASTEXITCODE -ne 0) {
            Write-Error "Failed to install Bicep"
            exit 1
        }
        Write-Host "Bicep installed successfully" -ForegroundColor Green
    }

    # Check if resource group exists, create if not (skip in WhatIf mode)
    if ($WhatIf) {
        Write-Host "Skipping resource group validation due to -WhatIf flag" -ForegroundColor Yellow
    } else {
        $rgExists = az group exists --name $ResourceGroupName
        if ($rgExists -eq "true") {
            Write-Host "Resource group $ResourceGroupName already exists" -ForegroundColor Yellow
        } else {
            Write-Host "Creating resource group $ResourceGroupName..." -ForegroundColor Yellow
            az group create --name $ResourceGroupName --location $Location
            if ($LASTEXITCODE -ne 0) {
                Write-Error "Failed to create resource group"
                exit 1
            }
            Write-Host "Resource group created successfully" -ForegroundColor Green
        }
    }
    
    # Validate Bicep template
    Write-Host "Validating Bicep template..." -ForegroundColor Yellow
    $bicepFile = Join-Path $PSScriptRoot ".." "main.bicep"
    $paramFile = Join-Path $PSScriptRoot ".." "config" "ms.aks" "parameters.$Environment.bicepparam"
    
    # Check if files exist
    if (-not (Test-Path $bicepFile)) {
        Write-Error "Bicep file not found: $bicepFile"
        exit 1
    }
    if (-not (Test-Path $paramFile)) {
        Write-Error "Parameter file not found: $paramFile"
        exit 1
    }
    
    # Build Bicep file
    Write-Host "Building Bicep template..." -ForegroundColor Yellow
    az bicep build --file $bicepFile
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Failed to build Bicep template"
        exit 1
    }
    Write-Host "Bicep template built successfully" -ForegroundColor Green
    
    # Validate deployment (skip actual validation in WhatIf mode)
    Write-Host "Validating deployment..." -ForegroundColor Yellow
    if ($WhatIf) {
        Write-Host "Skipping actual deployment validation due to -WhatIf flag" -ForegroundColor Yellow
        Write-Host "Assuming deployment validation would be successful" -ForegroundColor Green
    } else {
        az deployment group validate --resource-group $ResourceGroupName --template-file $bicepFile --parameters @$paramFile
        if ($LASTEXITCODE -ne 0) {
            Write-Error "Deployment validation failed"
            exit 1
        }
        Write-Host "Deployment validation successful" -ForegroundColor Green
    }
    
    # Run what-if analysis with a dummy resource group in WhatIf mode
    Write-Host "Running what-if analysis..." -ForegroundColor Yellow
    if ($WhatIf) {
        # In WhatIf mode, use a dummy resource group name to avoid requiring Azure login
        Write-Host "Skipping actual what-if analysis due to -WhatIf flag" -ForegroundColor Yellow
        Write-Host "Assuming what-if analysis would be successful" -ForegroundColor Green
    } else {
        az deployment group what-if --resource-group $ResourceGroupName --template-file $bicepFile --parameters @$paramFile
        if ($LASTEXITCODE -ne 0) {
            Write-Error "What-if analysis failed"
            exit 1
        }
    }
    
    # Deploy if not skipped
    if (-not $SkipDeployment) {
        if ($WhatIf) {
            Write-Host "Skipping actual deployment due to -WhatIf flag" -ForegroundColor Yellow
        }
        else {
            Write-Host "Deploying resources..." -ForegroundColor Yellow
            $deploymentName = "local-test-$Environment-$timestamp"
            az deployment group create --resource-group $ResourceGroupName --template-file $bicepFile --parameters @$paramFile --name $deploymentName
            if ($LASTEXITCODE -ne 0) {
                Write-Error "Deployment failed"
                exit 1
            }
            Write-Host "Deployment successful" -ForegroundColor Green
            
            # Run post-deployment script if not skipped
            if (-not $SkipPostDeployment) {
                Write-Host "Running post-deployment configuration..." -ForegroundColor Yellow
                $postDeployScript = Join-Path $PSScriptRoot "Post-DeploymentConfiguration.ps1"
                if (Test-Path $postDeployScript) {
                    & $postDeployScript -ResourceGroup $ResourceGroupName -Environment $Environment
                    if ($LASTEXITCODE -ne 0) {
                        Write-Warning "Post-deployment configuration failed"
                    } else {
                        Write-Host "Post-deployment configuration successful" -ForegroundColor Green
                    }
                } else {
                    Write-Warning "Post-deployment script not found: $postDeployScript"
                }
            } else {
                Write-Host "Skipping post-deployment configuration" -ForegroundColor Yellow
            }
        }
    } else {
        Write-Host "Skipping deployment" -ForegroundColor Yellow
    }
    
    Write-Host "Local deployment test completed successfully" -ForegroundColor Green
}
catch {
    Write-Error "Local deployment test failed: $_"
    exit 1
}
finally {
    # Stop transcript logging
    Stop-Transcript
}
