[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string]$ResourceGroup,
    
    [Parameter(Mandatory = $true)]
    [string]$ApimServiceName,
    
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
$logFile = Join-Path $LogPath "apim-security-$timestamp.log"
Start-Transcript -Path $logFile -Append

Write-Host "Starting API Management security hardening" -ForegroundColor Cyan
Write-Host "API Management: $ApimServiceName" -ForegroundColor Cyan

try {
    # Check if API Management exists
    Write-Host "Checking API Management service..." -ForegroundColor Yellow
    $apim = az apim show --name $ApimServiceName --resource-group $ResourceGroup 2>$null
    
    if (-not $apim) {
        Write-Error "API Management service $ApimServiceName not found in resource group $ResourceGroup"
        exit 1
    }
    
    # 1. Configure TLS settings
    Write-Host "Configuring TLS settings..." -ForegroundColor Yellow
    $tlsResult = az apim update --name $ApimServiceName --resource-group $ResourceGroup --set "properties.customProperties.Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Protocols.Tls10=false" --set "properties.customProperties.Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Protocols.Tls11=false" --set "properties.customProperties.Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Backend.Protocols.Tls10=false" --set "properties.customProperties.Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Backend.Protocols.Tls11=false" --set "properties.customProperties.Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Ciphers.TripleDes168=false" --set "properties.customProperties.Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Ciphers.TLS_RSA_WITH_AES_128_CBC_SHA=false" --set "properties.customProperties.Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Ciphers.TLS_RSA_WITH_AES_256_CBC_SHA=false" --set "properties.customProperties.Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Ciphers.TLS_RSA_WITH_AES_128_CBC_SHA256=false" --set "properties.customProperties.Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Ciphers.TLS_ECDHE_RSA_WITH_AES_128_CBC_SHA=false" --set "properties.customProperties.Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Ciphers.TLS_ECDHE_RSA_WITH_AES_256_CBC_SHA=false" --set "properties.customProperties.Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Ciphers.TLS_ECDHE_RSA_WITH_AES_128_CBC_SHA256=false" --set "properties.customProperties.Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Ciphers.TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256=true" --set "properties.customProperties.Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Ciphers.TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384=true" --set "properties.customProperties.Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Ciphers.TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256=true" --set "properties.customProperties.Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Ciphers.TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384=true"
    
    if ($tlsResult) {
        Write-Host "TLS settings configured successfully" -ForegroundColor Green
    } else {
        Write-Error "Failed to configure TLS settings"
    }
    
    # 2. Configure security headers policy
    Write-Host "Configuring security headers policy..." -ForegroundColor Yellow
    
    $securityHeadersPolicy = @"
<policies>
    <inbound>
        <set-header name="X-Content-Type-Options" exists-action="override">
            <value>nosniff</value>
        </set-header>
        <set-header name="X-Frame-Options" exists-action="override">
            <value>DENY</value>
        </set-header>
        <set-header name="Content-Security-Policy" exists-action="override">
            <value>default-src 'self'; script-src 'self'; object-src 'none'; frame-ancestors 'none';</value>
        </set-header>
        <set-header name="X-XSS-Protection" exists-action="override">
            <value>1; mode=block</value>
        </set-header>
        <set-header name="Strict-Transport-Security" exists-action="override">
            <value>max-age=31536000; includeSubDomains</value>
        </set-header>
        <set-header name="Cache-Control" exists-action="override">
            <value>no-store, no-cache, must-revalidate, max-age=0</value>
        </set-header>
        <set-header name="Pragma" exists-action="override">
            <value>no-cache</value>
        </set-header>
    </inbound>
</policies>
"@
    
    # Save policy to temporary file
    $policyFile = Join-Path $env:TEMP "security-headers-policy.xml"
    $securityHeadersPolicy | Out-File -FilePath $policyFile -Encoding utf8
    
    # Apply policy at global level
    $policyResult = az apim policy create --resource-group $ResourceGroup --service-name $ApimServiceName --policy-id "policy" --policy-format "xml" --value "@$policyFile"
    
    if ($policyResult) {
        Write-Host "Security headers policy configured successfully" -ForegroundColor Green
    } else {
        Write-Error "Failed to configure security headers policy"
    }
    
    # Remove temporary file
    Remove-Item -Path $policyFile -Force
    
    # 3. Configure IP filtering if needed
    # This is commented out as it requires specific IP ranges
    <#
    Write-Host "Configuring IP filtering..." -ForegroundColor Yellow
    
    $ipFilterPolicy = @"
<policies>
    <inbound>
        <ip-filter action="allow">
            <address-range from="203.0.113.0" to="203.0.113.255" />
            <address>198.51.100.1</address>
        </ip-filter>
    </inbound>
</policies>
"@
    
    # Save policy to temporary file
    $ipPolicyFile = Join-Path $env:TEMP "ip-filter-policy.xml"
    $ipFilterPolicy | Out-File -FilePath $ipPolicyFile -Encoding utf8
    
    # Apply policy at global level
    $ipPolicyResult = az apim policy create --resource-group $ResourceGroup --service-name $ApimServiceName --policy-id "policy" --policy-format "xml" --value "@$ipPolicyFile"
    
    if ($ipPolicyResult) {
        Write-Host "IP filtering policy configured successfully" -ForegroundColor Green
    } else {
        Write-Error "Failed to configure IP filtering policy"
    }
    
    # Remove temporary file
    Remove-Item -Path $ipPolicyFile -Force
    #>
    
    # 4. Configure rate limiting
    Write-Host "Configuring rate limiting policy..." -ForegroundColor Yellow
    
    $rateLimitPolicy = @"
<policies>
    <inbound>
        <rate-limit calls="5" renewal-period="60" />
        <quota calls="100" renewal-period="3600" />
    </inbound>
</policies>
"@
    
    # Save policy to temporary file
    $ratePolicyFile = Join-Path $env:TEMP "rate-limit-policy.xml"
    $rateLimitPolicy | Out-File -FilePath $ratePolicyFile -Encoding utf8
    
    # Apply policy at product level (assuming a product named "default" exists)
    $ratePolicyResult = az apim product policy create --resource-group $ResourceGroup --service-name $ApimServiceName --product-id "unlimited" --policy-id "policy" --policy-format "xml" --value "@$ratePolicyFile"
    
    if ($ratePolicyResult) {
        Write-Host "Rate limiting policy configured successfully" -ForegroundColor Green
    } else {
        Write-Warning "Failed to configure rate limiting policy. The 'unlimited' product may not exist."
    }
    
    # Remove temporary file
    Remove-Item -Path $ratePolicyFile -Force
    
    # 5. Configure JWT validation (example)
    Write-Host "Configuring JWT validation policy..." -ForegroundColor Yellow
    
    $jwtPolicy = @"
<policies>
    <inbound>
        <validate-jwt header-name="Authorization" failed-validation-httpcode="401" failed-validation-error-message="Unauthorized. Access token is missing or invalid.">
            <openid-config url="https://login.microsoftonline.com/common/v2.0/.well-known/openid-configuration" />
            <audiences>
                <audience>api://your-app-id</audience>
            </audiences>
            <issuers>
                <issuer>https://login.microsoftonline.com/your-tenant-id/v2.0</issuer>
            </issuers>
            <required-claims>
                <claim name="scp" match="any">
                    <value>access_as_user</value>
                </claim>
            </required-claims>
        </validate-jwt>
    </inbound>
</policies>
"@
    
    # Save policy to temporary file
    $jwtPolicyFile = Join-Path $env:TEMP "jwt-policy.xml"
    $jwtPolicy | Out-File -FilePath $jwtPolicyFile -Encoding utf8
    
    # This is just an example and not applied by default
    Write-Host "JWT validation policy example created at $jwtPolicyFile" -ForegroundColor Yellow
    Write-Host "You can apply this policy to specific APIs or operations as needed" -ForegroundColor Yellow
    
    # Remove temporary file
    Remove-Item -Path $jwtPolicyFile -Force
    
    Write-Host "API Management security hardening completed successfully" -ForegroundColor Green
}
catch {
    Write-Error "API Management security hardening failed: $_"
    exit 1
}
finally {
    # Stop transcript logging
    Stop-Transcript
}
