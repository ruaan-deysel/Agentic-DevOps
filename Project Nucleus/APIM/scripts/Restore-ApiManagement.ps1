[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string]$ResourceGroup,
    
    [Parameter(Mandatory = $true)]
    [string]$ApimServiceName,
    
    [Parameter(Mandatory = $true)]
    [string]$StorageAccountName,
    
    [Parameter(Mandatory = $true)]
    [string]$StorageContainerName,
    
    [Parameter(Mandatory = $true)]
    [string]$BackupName,
    
    [Parameter(Mandatory = $false)]
    [string]$LogPath = "./logs",
    
    [Parameter(Mandatory = $false)]
    [switch]$Force
)

# Set up error handling
$ErrorActionPreference = 'Stop'
$VerbosePreference = 'Continue'

# Create log directory if it doesn't exist
if (-not (Test-Path $LogPath)) {
    New-Item -Path $LogPath -ItemType Directory -Force | Out-Null
    Write-Verbose "Created log directory: $LogPath"
}

# Set up logging
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$logFile = Join-Path $LogPath "apim-restore-$timestamp.log"
Start-Transcript -Path $logFile -Append

Write-Host "Starting API Management restore process" -ForegroundColor Cyan
Write-Host "API Management: $ApimServiceName" -ForegroundColor Cyan
Write-Host "Storage Account: $StorageAccountName" -ForegroundColor Cyan
Write-Host "Container: $StorageContainerName" -ForegroundColor Cyan
Write-Host "Backup Name: $BackupName" -ForegroundColor Cyan

try {
    # Check if storage account exists
    Write-Host "Checking storage account..." -ForegroundColor Yellow
    $storageAccount = az storage account show --name $StorageAccountName --resource-group $ResourceGroup 2>$null
    
    if (-not $storageAccount) {
        Write-Error "Storage account $StorageAccountName not found in resource group $ResourceGroup"
        exit 1
    }
    
    # Get storage account key
    Write-Host "Getting storage account key..." -ForegroundColor Yellow
    $storageKey = az storage account keys list --account-name $StorageAccountName --resource-group $ResourceGroup --query "[0].value" -o tsv
    
    if (-not $storageKey) {
        Write-Error "Failed to get storage account key for $StorageAccountName"
        exit 1
    }
    
    # Check if container exists
    Write-Host "Checking storage container..." -ForegroundColor Yellow
    $containerExists = az storage container exists --name $StorageContainerName --account-name $StorageAccountName --account-key $storageKey --query "exists" -o tsv
    
    if ($containerExists -ne "true") {
        Write-Error "Storage container $StorageContainerName does not exist in storage account $StorageAccountName"
        exit 1
    }
    
    # Check if backup exists
    Write-Host "Checking if backup exists..." -ForegroundColor Yellow
    $backupExists = az storage blob exists --name "$BackupName.json" --container-name $StorageContainerName --account-name $StorageAccountName --account-key $storageKey --query "exists" -o tsv
    
    if ($backupExists -ne "true") {
        Write-Error "Backup $BackupName does not exist in container $StorageContainerName"
        exit 1
    }
    
    # Restore backup
    Write-Host "Restoring API Management from backup..." -ForegroundColor Yellow
    $restoreResult = az apim restore --resource-group $ResourceGroup --name $ApimServiceName --backup-name $BackupName --storage-account-name $StorageAccountName --storage-account-container $StorageContainerName --storage-account-key $storageKey
    
    if ($restoreResult) {
        Write-Host "API Management restored successfully from backup: $BackupName" -ForegroundColor Green
    } else {
        Write-Error "Failed to restore API Management from backup"
        exit 1
    }
    
    Write-Host "Restore process completed successfully" -ForegroundColor Green
}
catch {
    Write-Error "Restore process failed: $_"
    exit 1
}
finally {
    # Stop transcript logging
    Stop-Transcript
}
