# Test-BicepTemplates.ps1
# This script validates the Bicep templates and parameter files

param (
    [Parameter(Mandatory = $false)]
    [string]$TemplateFile = "../main.bicep",

    [Parameter(Mandatory = $false)]
    [string]$ParameterFile = "../config/ms.expressroute/parameters.bicepparam"
)

Write-Host "Starting Bicep template validation" -ForegroundColor Cyan
Write-Host "Template File: $TemplateFile" -ForegroundColor Cyan
Write-Host "Parameter File: $ParameterFile" -ForegroundColor Cyan

$success = $true

# Check if template file exists
if (Test-Path $TemplateFile) {
    Write-Host "✓ Template file exists" -ForegroundColor Green
} else {
    Write-Host "✗ Template file not found: $TemplateFile" -ForegroundColor Red
    $success = $false
}

# Check if parameter file exists
if (Test-Path $ParameterFile) {
    Write-Host "✓ Parameter file exists" -ForegroundColor Green
} else {
    Write-Host "✗ Parameter file not found: $ParameterFile" -ForegroundColor Red
    $success = $false
}

if (-not $success) {
    Write-Host "Validation failed: One or more files not found" -ForegroundColor Red
    exit 1
}

# Validate the Bicep template
Write-Host "Validating Bicep template..." -ForegroundColor Yellow
az bicep build --file $TemplateFile

if ($LASTEXITCODE -ne 0) {
    Write-Host "✗ Bicep template validation failed" -ForegroundColor Red
    exit 1
} else {
    Write-Host "✓ Bicep template validation successful" -ForegroundColor Green
}

# Check parameter file for required parameters
$requiredParameters = @(
    'circuitName',
    'location',
    'peeringLocation',
    'bandwidthInMbps',
    'skuTier',
    'skuFamily',
    'gatewayResourceGroupName',
    'gatewayName'
)

$paramContent = Get-Content -Path $ParameterFile -Raw

foreach ($param in $requiredParameters) {
    if (-not ($paramContent -match "param\s+$param\s*=")) {
        Write-Host "✗ Required parameter '$param' not found in $ParameterFile" -ForegroundColor Red
        $success = $false
    }
}

if ($success) {
    Write-Host "✓ All required parameters found in parameter file" -ForegroundColor Green
} else {
    Write-Host "✗ One or more required parameters missing from parameter file" -ForegroundColor Red
    exit 1
}

# Verify current subscription context
Write-Host "Verifying subscription context..." -ForegroundColor Yellow
$subscriptionInfo = az account show | ConvertFrom-Json
Write-Host "Using subscription: $($subscriptionInfo.name) ($($subscriptionInfo.id))" -ForegroundColor Yellow

# Perform a what-if deployment to validate the template with parameters
Write-Host "Performing what-if deployment to validate template with parameters..." -ForegroundColor Yellow
Write-Host "Note: This will not create any resources, it's just a validation" -ForegroundColor Yellow

az deployment group what-if `
    --resource-group "SAW-AE-PLT-CON-NET-RG001" `
    --template-file $TemplateFile `
    --parameters $ParameterFile `
    --no-pretty-print `
    --query "changes" `
    --output none

if ($LASTEXITCODE -ne 0) {
    Write-Host "✗ What-if deployment validation failed" -ForegroundColor Red
    exit 1
} else {
    Write-Host "✓ What-if deployment validation successful" -ForegroundColor Green
}

Write-Host "Validation completed successfully" -ForegroundColor Green
