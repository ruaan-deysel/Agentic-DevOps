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
    
    [Parameter(Mandatory = $false)]
    [string]$BackupName = "apim-backup-$(Get-Date -Format 'yyyyMMdd-HHmmss')",
    
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
$logFile = Join-Path $LogPath "apim-backup-$timestamp.log"
Start-Transcript -Path $logFile -Append

Write-Host "Starting API Management backup process" -ForegroundColor Cyan
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
    
    # Check if container exists, create if not
    Write-Host "Checking storage container..." -ForegroundColor Yellow
    $containerExists = az storage container exists --name $StorageContainerName --account-name $StorageAccountName --account-key $storageKey --query "exists" -o tsv
    
    if ($containerExists -ne "true") {
        Write-Host "Creating storage container $StorageContainerName..." -ForegroundColor Yellow
        az storage container create --name $StorageContainerName --account-name $StorageAccountName --account-key $storageKey
    }
    
    # Create SAS token for the container
    Write-Host "Creating SAS token..." -ForegroundColor Yellow
    $expiryTime = (Get-Date).AddHours(1).ToString("yyyy-MM-ddTHH:mm:ssZ")
    $sasToken = az storage container generate-sas --name $StorageContainerName --account-name $StorageAccountName --account-key $storageKey --permissions rwl --expiry $expiryTime -o tsv
    
    if (-not $sasToken) {
        Write-Error "Failed to generate SAS token for container $StorageContainerName"
        exit 1
    }
    
    # Create backup
    Write-Host "Creating API Management backup..." -ForegroundColor Yellow
    $backupResult = az apim backup --resource-group $ResourceGroup --name $ApimServiceName --backup-name $BackupName --storage-account-name $StorageAccountName --storage-account-container $StorageContainerName --storage-account-key $storageKey
    
    if ($backupResult) {
        Write-Host "API Management backup created successfully: $BackupName" -ForegroundColor Green
    } else {
        Write-Error "Failed to create API Management backup"
        exit 1
    }
    
    Write-Host "Backup process completed successfully" -ForegroundColor Green
}
catch {
    Write-Error "Backup process failed: $_"
    exit 1
}
finally {
    # Stop transcript logging
    Stop-Transcript
}
