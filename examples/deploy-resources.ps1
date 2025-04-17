#Requires -Modules Az

[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string]$ResourceGroupName,

    [Parameter(Mandatory = $false)]
    [string]$Location = "eastus",

    [Parameter(Mandatory = $false)]
    [string]$StorageAccountName = "st$(Get-Random -Minimum 100000 -Maximum 999999)",

    [Parameter(Mandatory = $false)]
    [string]$TemplateFile = "./storage-account.bicep"
)

# Connect to Azure if not already connected
try {
    $context = Get-AzContext
    if (-not $context) {
        Connect-AzAccount
    }
}
catch {
    Write-Error "Failed to connect to Azure: $_"
    exit 1
}

# Create resource group if it doesn't exist
$resourceGroup = Get-AzResourceGroup -Name $ResourceGroupName -ErrorAction SilentlyContinue
if (-not $resourceGroup) {
    Write-Host "Creating resource group '$ResourceGroupName' in location '$Location'..."
    $resourceGroup = New-AzResourceGroup -Name $ResourceGroupName -Location $Location
}
else {
    Write-Host "Resource group '$ResourceGroupName' already exists."
}

# Deploy Bicep template
Write-Host "Deploying Bicep template '$TemplateFile' to resource group '$ResourceGroupName'..."
$deployment = New-AzResourceGroupDeployment `
    -ResourceGroupName $ResourceGroupName `
    -TemplateFile $TemplateFile `
    -storageAccountName $StorageAccountName `
    -Verbose

# Output deployment results
if ($deployment.ProvisioningState -eq "Succeeded") {
    Write-Host "Deployment succeeded!" -ForegroundColor Green
    Write-Host "Storage Account Name: $($deployment.Outputs.storageAccountName.Value)"
    Write-Host "Storage Account ID: $($deployment.Outputs.storageAccountId.Value)"
}
else {
    Write-Host "Deployment failed!" -ForegroundColor Red
    Write-Host $deployment.Error
}
