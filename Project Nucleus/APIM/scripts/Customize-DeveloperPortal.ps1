[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string]$ResourceGroup,
    
    [Parameter(Mandatory = $true)]
    [string]$ApimServiceName,
    
    [Parameter(Mandatory = $false)]
    [string]$CustomizationPath = "./portal-customizations",
    
    [Parameter(Mandatory = $false)]
    [string]$LogoPath,
    
    [Parameter(Mandatory = $false)]
    [string]$FaviconPath,
    
    [Parameter(Mandatory = $false)]
    [string]$OrganizationName,
    
    [Parameter(Mandatory = $false)]
    [string]$OrganizationWebsite,
    
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
$logFile = Join-Path $LogPath "developer-portal-customization-$timestamp.log"
Start-Transcript -Path $logFile -Append

Write-Host "Starting Developer Portal customization" -ForegroundColor Cyan
Write-Host "API Management: $ApimServiceName" -ForegroundColor Cyan
Write-Host "Customization Path: $CustomizationPath" -ForegroundColor Cyan

try {
    # Check if API Management exists
    Write-Host "Checking API Management service..." -ForegroundColor Yellow
    $apim = az apim show --name $ApimServiceName --resource-group $ResourceGroup 2>$null
    
    if (-not $apim) {
        Write-Error "API Management service $ApimServiceName not found in resource group $ResourceGroup"
        exit 1
    }
    
    # Update organization details if provided
    if ($OrganizationName -or $OrganizationWebsite) {
        Write-Host "Updating organization details..." -ForegroundColor Yellow
        
        $params = @()
        if ($OrganizationName) {
            $params += "--publisher-name", $OrganizationName
        }
        if ($OrganizationWebsite) {
            $params += "--publisher-email", "admin@$OrganizationWebsite"
            $params += "--publisher-website", "https://$OrganizationWebsite"
        }
        
        if ($params.Count -gt 0) {
            $updateResult = az apim update --name $ApimServiceName --resource-group $ResourceGroup $params
            
            if ($updateResult) {
                Write-Host "Organization details updated successfully" -ForegroundColor Green
            } else {
                Write-Error "Failed to update organization details"
            }
        }
    }
    
    # Upload logo if provided
    if ($LogoPath -and (Test-Path $LogoPath)) {
        Write-Host "Uploading logo..." -ForegroundColor Yellow
        
        $logoResult = az apim update --name $ApimServiceName --resource-group $ResourceGroup --set "properties.portalSettings.logo.type=image/png" --set "properties.portalSettings.logo.data=$(Get-Content $LogoPath -Raw | ConvertTo-Base64)"
        
        if ($logoResult) {
            Write-Host "Logo uploaded successfully" -ForegroundColor Green
        } else {
            Write-Error "Failed to upload logo"
        }
    }
    
    # Upload favicon if provided
    if ($FaviconPath -and (Test-Path $FaviconPath)) {
        Write-Host "Uploading favicon..." -ForegroundColor Yellow
        
        $faviconResult = az apim update --name $ApimServiceName --resource-group $ResourceGroup --set "properties.portalSettings.favicon.type=image/x-icon" --set "properties.portalSettings.favicon.data=$(Get-Content $FaviconPath -Raw | ConvertTo-Base64)"
        
        if ($faviconResult) {
            Write-Host "Favicon uploaded successfully" -ForegroundColor Green
        } else {
            Write-Error "Failed to upload favicon"
        }
    }
    
    # Apply custom styles if available
    $stylesPath = Join-Path $CustomizationPath "styles.css"
    if (Test-Path $stylesPath) {
        Write-Host "Applying custom styles..." -ForegroundColor Yellow
        
        $stylesContent = Get-Content $stylesPath -Raw
        $stylesResult = az apim update --name $ApimServiceName --resource-group $ResourceGroup --set "properties.portalSettings.styling.customCss=$stylesContent"
        
        if ($stylesResult) {
            Write-Host "Custom styles applied successfully" -ForegroundColor Green
        } else {
            Write-Error "Failed to apply custom styles"
        }
    }
    
    # Upload custom pages if available
    $pagesPath = Join-Path $CustomizationPath "pages"
    if (Test-Path $pagesPath) {
        Write-Host "Uploading custom pages..." -ForegroundColor Yellow
        
        $pageFiles = Get-ChildItem -Path $pagesPath -Filter "*.html" -Recurse
        
        foreach ($pageFile in $pageFiles) {
            $pageName = [System.IO.Path]::GetFileNameWithoutExtension($pageFile.Name)
            $pageContent = Get-Content $pageFile.FullName -Raw
            
            Write-Host "  Uploading page: $pageName..." -ForegroundColor Yellow
            
            $pageResult = az apim portal page update --name $ApimServiceName --resource-group $ResourceGroup --page-id $pageName --content $pageContent
            
            if ($pageResult) {
                Write-Host "  Page $pageName uploaded successfully" -ForegroundColor Green
            } else {
                Write-Warning "  Failed to upload page $pageName. Attempting to create..."
                
                $createResult = az apim portal page create --name $ApimServiceName --resource-group $ResourceGroup --page-id $pageName --content $pageContent
                
                if ($createResult) {
                    Write-Host "  Page $pageName created successfully" -ForegroundColor Green
                } else {
                    Write-Error "  Failed to create page $pageName"
                }
            }
        }
    }
    
    # Publish the developer portal
    Write-Host "Publishing developer portal..." -ForegroundColor Yellow
    $publishResult = az apim portal update --name $ApimServiceName --resource-group $ResourceGroup --is-published true
    
    if ($publishResult) {
        Write-Host "Developer portal published successfully" -ForegroundColor Green
    } else {
        Write-Error "Failed to publish developer portal"
    }
    
    Write-Host "Developer Portal customization completed successfully" -ForegroundColor Green
}
catch {
    Write-Error "Developer Portal customization failed: $_"
    exit 1
}
finally {
    # Stop transcript logging
    Stop-Transcript
}
