[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string]$ResourceGroup,
    
    [Parameter(Mandatory = $true)]
    [string]$ApimServiceName,
    
    [Parameter(Mandatory = $true)]
    [string]$KeyVaultName,
    
    [Parameter(Mandatory = $false)]
    [string]$GatewayHostname,
    
    [Parameter(Mandatory = $false)]
    [string]$PortalHostname,
    
    [Parameter(Mandatory = $false)]
    [string]$ManagementHostname,
    
    [Parameter(Mandatory = $false)]
    [string]$CertificateName,
    
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
$logFile = Join-Path $LogPath "apim-custom-domains-$timestamp.log"
Start-Transcript -Path $logFile -Append

Write-Host "Starting API Management custom domain configuration" -ForegroundColor Cyan
Write-Host "API Management: $ApimServiceName" -ForegroundColor Cyan
Write-Host "Key Vault: $KeyVaultName" -ForegroundColor Cyan

# Validate parameters
if (-not $GatewayHostname -and -not $PortalHostname -and -not $ManagementHostname) {
    Write-Error "At least one hostname (Gateway, Portal, or Management) must be specified"
    exit 1
}

if (-not $CertificateName) {
    Write-Error "Certificate name must be specified"
    exit 1
}

try {
    # Check if Key Vault exists
    Write-Host "Checking Key Vault..." -ForegroundColor Yellow
    $keyVault = az keyvault show --name $KeyVaultName --resource-group $ResourceGroup 2>$null
    
    if (-not $keyVault) {
        Write-Error "Key Vault $KeyVaultName not found in resource group $ResourceGroup"
        exit 1
    }
    
    # Check if certificate exists in Key Vault
    Write-Host "Checking certificate in Key Vault..." -ForegroundColor Yellow
    $certificate = az keyvault certificate show --name $CertificateName --vault-name $KeyVaultName 2>$null
    
    if (-not $certificate) {
        Write-Error "Certificate $CertificateName not found in Key Vault $KeyVaultName"
        exit 1
    }
    
    # Get API Management system-assigned managed identity
    Write-Host "Getting API Management managed identity..." -ForegroundColor Yellow
    $apimIdentity = az apim show --name $ApimServiceName --resource-group $ResourceGroup --query "identity.principalId" -o tsv
    
    if (-not $apimIdentity) {
        Write-Error "API Management $ApimServiceName does not have a system-assigned managed identity"
        exit 1
    }
    
    # Grant API Management access to Key Vault
    Write-Host "Granting API Management access to Key Vault..." -ForegroundColor Yellow
    az keyvault set-policy --name $KeyVaultName --object-id $apimIdentity --certificate-permissions get list --secret-permissions get list
    
    # Configure custom domains
    if ($GatewayHostname) {
        Write-Host "Configuring gateway custom domain: $GatewayHostname..." -ForegroundColor Yellow
        $gatewayResult = az apim hostname update --resource-group $ResourceGroup --name $ApimServiceName --hostname $GatewayHostname --type proxy --key-vault-id $(az keyvault secret show --vault-name $KeyVaultName --name $CertificateName --query "id" -o tsv)
        
        if ($gatewayResult) {
            Write-Host "Gateway custom domain configured successfully: $GatewayHostname" -ForegroundColor Green
        } else {
            Write-Error "Failed to configure gateway custom domain"
        }
    }
    
    if ($PortalHostname) {
        Write-Host "Configuring portal custom domain: $PortalHostname..." -ForegroundColor Yellow
        $portalResult = az apim hostname update --resource-group $ResourceGroup --name $ApimServiceName --hostname $PortalHostname --type portal --key-vault-id $(az keyvault secret show --vault-name $KeyVaultName --name $CertificateName --query "id" -o tsv)
        
        if ($portalResult) {
            Write-Host "Portal custom domain configured successfully: $PortalHostname" -ForegroundColor Green
        } else {
            Write-Error "Failed to configure portal custom domain"
        }
    }
    
    if ($ManagementHostname) {
        Write-Host "Configuring management custom domain: $ManagementHostname..." -ForegroundColor Yellow
        $managementResult = az apim hostname update --resource-group $ResourceGroup --name $ApimServiceName --hostname $ManagementHostname --type management --key-vault-id $(az keyvault secret show --vault-name $KeyVaultName --name $CertificateName --query "id" -o tsv)
        
        if ($managementResult) {
            Write-Host "Management custom domain configured successfully: $ManagementHostname" -ForegroundColor Green
        } else {
            Write-Error "Failed to configure management custom domain"
        }
    }
    
    Write-Host "Custom domain configuration completed successfully" -ForegroundColor Green
}
catch {
    Write-Error "Custom domain configuration failed: $_"
    exit 1
}
finally {
    # Stop transcript logging
    Stop-Transcript
}
