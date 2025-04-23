# Deploy-ExpressRoute.ps1
# This script deploys an ExpressRoute circuit using the Bicep template and parameter file

param (
    [Parameter(Mandatory = $false)]
    [string]$ResourceGroupName = "SAW-AE-PLT-CON-NET-RG001",

    [Parameter(Mandatory = $false)]
    [string]$TemplateFile = "../main.bicep",

    [Parameter(Mandatory = $false)]
    [string]$ParameterFile = "../config/ms.expressroute/parameters.bicepparam",

    [Parameter(Mandatory = $false)]
    [switch]$WhatIf
)

# Set up logging
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$logPath = "./logs"
if (-not (Test-Path $logPath)) {
    New-Item -Path $logPath -ItemType Directory -Force | Out-Null
}
$logFile = Join-Path $logPath "expressroute-deployment-$timestamp.log"
Start-Transcript -Path $logFile -Append

Write-Host "Starting ExpressRoute circuit deployment" -ForegroundColor Cyan
Write-Host "Resource Group: $ResourceGroupName" -ForegroundColor Cyan
Write-Host "Template File: $TemplateFile" -ForegroundColor Cyan
Write-Host "Parameter File: $ParameterFile" -ForegroundColor Cyan

try {
    # Check if resource group exists
    Write-Host "Checking resource group..." -ForegroundColor Yellow
    $resourceGroup = az group show --name $ResourceGroupName 2>$null

    if (-not $resourceGroup) {
        Write-Error "Resource group $ResourceGroupName not found"
        exit 1
    }

    # Validate the Bicep template
    Write-Host "Validating Bicep template..." -ForegroundColor Yellow
    az bicep build --file $TemplateFile

    if ($LASTEXITCODE -ne 0) {
        Write-Error "Bicep template validation failed"
        exit 1
    }

    # Verify current subscription context
    Write-Host "Verifying subscription context..." -ForegroundColor Yellow
    $subscriptionInfo = az account show | ConvertFrom-Json
    Write-Host "Using subscription: $($subscriptionInfo.name) ($($subscriptionInfo.id))" -ForegroundColor Yellow

    # Install the Bicep registry module
    Write-Host "Installing Azure Verified Module for ExpressRoute Circuit..." -ForegroundColor Yellow
    az bicep install-module --target-module-name avm/res/network/express-route-circuit --version 0.3.0

    # Deploy the ExpressRoute circuit
    if ($WhatIf) {
        Write-Host "Performing what-if deployment..." -ForegroundColor Yellow
        az deployment group what-if `
            --resource-group $ResourceGroupName `
            --template-file $TemplateFile `
            --parameters $ParameterFile
    } else {
        Write-Host "Deploying ExpressRoute circuit..." -ForegroundColor Yellow
        az deployment group create `
            --resource-group $ResourceGroupName `
            --template-file $TemplateFile `
            --parameters $ParameterFile

        if ($LASTEXITCODE -ne 0) {
            Write-Error "Deployment failed"
            exit 1
        }

        # Get the ExpressRoute circuit service key
        Write-Host "Getting ExpressRoute circuit service key..." -ForegroundColor Yellow
        $circuitName = (Get-Content $ParameterFile | Select-String "param circuitName = '(.+)'").Matches.Groups[1].Value
        $serviceKey = az network express-route show `
            --resource-group $ResourceGroupName `
            --name $circuitName `
            --query "serviceKey" `
            -o tsv

        Write-Host "ExpressRoute circuit service key: $serviceKey" -ForegroundColor Green
        Write-Host "Provide this service key to your service provider to complete the provisioning process." -ForegroundColor Green
    }

    Write-Host "Deployment completed successfully" -ForegroundColor Green
} catch {
    Write-Error "An error occurred during deployment: $_"
    exit 1
} finally {
    Stop-Transcript
}
