[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string]$ResourceGroup,
    
    [Parameter(Mandatory = $true)]
    [ValidateSet('dev', 'test', 'prod')]
    [string]$Environment,
    
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
$logFile = Join-Path $LogPath "post-deployment-$Environment-$timestamp.log"
Start-Transcript -Path $logFile -Append

Write-Host "Starting post-deployment configuration for environment: $Environment" -ForegroundColor Cyan

# Import configuration
$bicepParamPath = Join-Path $PSScriptRoot ".." "config" "ms.apim" "parameters.$Environment.bicepparam"

# Check if the bicepparam file exists
if (-not (Test-Path $bicepParamPath)) {
    Write-Error "Parameter file not found: parameters.$Environment.bicepparam"
    exit 1
}

Write-Host "Using Bicep parameter file: $bicepParamPath" -ForegroundColor Cyan

# Parse Bicep parameter file
$bicepParamContent = Get-Content $bicepParamPath -Raw

# Create a config object
$config = [PSCustomObject]@{
    parameters = [PSCustomObject]@{}
}

# Extract parameter values using regex
$paramMatches = [regex]::Matches($bicepParamContent, 'param\s+([a-zA-Z0-9_]+)\s+=\s+(.+?)(?=(\s+param|$))', [System.Text.RegularExpressions.RegexOptions]::Singleline)

foreach ($match in $paramMatches) {
    $paramName = $match.Groups[1].Value.Trim()
    $paramValue = $match.Groups[2].Value.Trim()
    
    # Try to parse the value based on its format
    try {
        if ($paramValue -eq 'true') {
            $parsedValue = $true
        }
        elseif ($paramValue -eq 'false') {
            $parsedValue = $false
        }
        elseif ($paramValue -match '^\d+$') {
            $parsedValue = [int]$paramValue
        }
        elseif ($paramValue -match '^[\'\"](.*)[\'\"](\s*)$') {
            $parsedValue = $matches[1]
        }
        elseif ($paramValue.StartsWith('{') -or $paramValue.StartsWith('[')) {
            # This is a complex object or array, we'll need to convert it to JSON
            # For arrays of objects, we need special handling
            if ($paramValue.Contains('{') -and $paramValue.Contains('[')) {
                # Convert Bicep array syntax to JSON
                $jsonValue = $paramValue.Replace("'", "\"") # Replace single quotes with double quotes
                                       .Replace(":", ": ") # Add space after colons
                                       .Replace("[", "[") # Keep opening brackets
                                       .Replace("]", "]") # Keep closing brackets
                                       .Replace("{", "{") # Keep opening braces
                                       .Replace("}", "}") # Keep closing braces
                
                # Use ConvertFrom-Json with depth parameter to handle nested objects
                $parsedValue = $jsonValue | ConvertFrom-Json -Depth 10
            } else {
                # Simple object or array
                $jsonValue = $paramValue.Replace("'", "\"") # Replace single quotes with double quotes
                $parsedValue = $jsonValue | ConvertFrom-Json
            }
        }
        else {
            $parsedValue = $paramValue
        }
    }
    catch {
        Write-Warning "Could not parse parameter value for $paramName, using as string: $_"
        $parsedValue = $paramValue
    }
    
    # Add to config object
    $config.parameters | Add-Member -MemberType NoteProperty -Name $paramName -Value @{ value = $parsedValue }
}

# Get APIM service name from config
$apimServiceName = $config.parameters.apimServiceName.value

Write-Host "Running post-deployment configuration for $apimServiceName in resource group $ResourceGroup"

# Import API specifications from external files
function Import-APIsFromSwagger {
    param (
        [string]$ResourceGroup,
        [string]$ApimServiceName
    )

    try {
        $apisFolder = Join-Path $PSScriptRoot ".." "apis"
        Write-Verbose "Looking for API definitions in: $apisFolder"

        if (Test-Path $apisFolder) {
            $swaggerFiles = Get-ChildItem -Path $apisFolder -Filter "*.json" -Recurse
            Write-Verbose "Found $($swaggerFiles.Count) API definition files"

            foreach ($file in $swaggerFiles) {
                $apiName = [System.IO.Path]::GetFileNameWithoutExtension($file.Name)
                Write-Host "Importing API: $apiName from $($file.FullName)" -ForegroundColor Green

                try {
                    $result = az apim api import `
                        --resource-group $ResourceGroup `
                        --service-name $ApimServiceName `
                        --path $apiName `
                        --display-name $apiName `
                        --api-id $apiName `
                        --specification-format "OpenApi" `
                        --specification-path $file.FullName

                    Write-Verbose "API import result: $result"
                    Write-Host "Successfully imported API: $apiName" -ForegroundColor Green
                }
                catch {
                    Write-Error "Failed to import API $apiName. Error: $_"
                }
            }
        }
        else {
            Write-Host "No APIs folder found at $apisFolder. Skipping API import." -ForegroundColor Yellow
        }
    }
    catch {
        Write-Error "Error in Import-APIsFromSwagger: $_"
    }
}

# Apply custom policies to API Management
function Apply-CustomPolicies {
    param (
        [string]$ResourceGroup,
        [string]$ApimServiceName
    )

    try {
        $policiesFolder = Join-Path $PSScriptRoot ".." "policies"
        Write-Verbose "Looking for policy files in: $policiesFolder"

        if (Test-Path $policiesFolder) {
            $policyFiles = Get-ChildItem -Path $policiesFolder -Filter "*.xml" -Recurse
            Write-Verbose "Found $($policyFiles.Count) policy files"

            foreach ($file in $policyFiles) {
                $policyScope = $file.Directory.Name
                $policyName = [System.IO.Path]::GetFileNameWithoutExtension($file.Name)

                Write-Host "Applying policy: $policyName at scope $policyScope" -ForegroundColor Green

                try {
                    # Logic to apply policy based on scope (global, product, api, or operation)
                    switch -Regex ($policyScope) {
                        "global" {
                            $result = az apim policy create `
                                --resource-group $ResourceGroup `
                                --service-name $ApimServiceName `
                                --policy-id "policy" `
                                --policy-format "xml" `
                                --value "@$($file.FullName)"
                            Write-Verbose "Applied global policy: $result"
                        }
                        "products" {
                            $result = az apim product policy create `
                                --resource-group $ResourceGroup `
                                --service-name $ApimServiceName `
                                --product-id $policyName `
                                --policy-id "policy" `
                                --policy-format "xml" `
                                --value "@$($file.FullName)"
                            Write-Verbose "Applied product policy: $result"
                        }
                        "apis" {
                            $apiName = $policyName
                            $result = az apim api policy create `
                                --resource-group $ResourceGroup `
                                --service-name $ApimServiceName `
                                --api-id $apiName `
                                --policy-id "policy" `
                                --policy-format "xml" `
                                --value "@$($file.FullName)"
                            Write-Verbose "Applied API policy: $result"
                        }
                        "operations" {
                            # Format expected: apiName_operationName
                            if ($policyName -match "(.+)_(.+)") {
                                $apiName = $matches[1]
                                $operationName = $matches[2]
                                $result = az apim api operation policy create `
                                    --resource-group $ResourceGroup `
                                    --service-name $ApimServiceName `
                                    --api-id $apiName `
                                    --operation-id $operationName `
                                    --policy-id "policy" `
                                    --policy-format "xml" `
                                    --value "@$($file.FullName)"
                                Write-Verbose "Applied operation policy: $result"
                            }
                            else {
                                Write-Warning "Invalid operation policy file name format: $policyName. Expected format: apiName_operationName"
                            }
                        }
                        default {
                            Write-Warning "Unknown policy scope: $policyScope. Policy not applied."
                        }
                    }
                    Write-Host "Successfully applied policy: $policyName" -ForegroundColor Green
                }
                catch {
                    Write-Error "Failed to apply policy $policyName. Error: $_"
                }
            }
        }
        else {
            Write-Host "No policies folder found at $policiesFolder. Skipping policy application." -ForegroundColor Yellow
        }
    }
    catch {
        Write-Error "Error in Apply-CustomPolicies: $_"
    }
}

# Function to create or update groups
function Set-ApimGroups {
    param (
        [string]$ResourceGroup,
        [string]$ApimServiceName,
        [array]$Groups
    )

    try {
        Write-Verbose "Processing groups for API Management service: $ApimServiceName"

        if ($Groups -and $Groups.Count -gt 0) {
            foreach ($group in $Groups) {
                $groupName = $group.name
                $displayName = $group.displayName ?? $groupName
                $description = $group.description ?? ""

                Write-Host "Creating/updating group: $groupName" -ForegroundColor Green

                try {
                    # Check if group exists
                    $existingGroup = az apim group show --resource-group $ResourceGroup --service-name $ApimServiceName --group-id $groupName 2>$null

                    if ($existingGroup) {
                        # Update existing group
                        $result = az apim group update \
                            --resource-group $ResourceGroup \
                            --service-name $ApimServiceName \
                            --group-id $groupName \
                            --display-name $displayName \
                            --description $description

                        Write-Verbose "Updated group: $groupName"
                    } else {
                        # Create new group
                        $result = az apim group create \
                            --resource-group $ResourceGroup \
                            --service-name $ApimServiceName \
                            --group-id $groupName \
                            --display-name $displayName \
                            --description $description

                        Write-Verbose "Created group: $groupName"
                    }

                    Write-Host "Successfully processed group: $groupName" -ForegroundColor Green
                } catch {
                    Write-Error "Failed to process group $groupName. Error: $_"
                }
            }
        } else {
            Write-Host "No groups defined in configuration. Skipping group creation." -ForegroundColor Yellow
        }
    } catch {
        Write-Error "Error in Set-ApimGroups: $_"
    }
}

# Function to create or update users
function Set-ApimUsers {
    param (
        [string]$ResourceGroup,
        [string]$ApimServiceName,
        [array]$Users
    )

    try {
        Write-Verbose "Processing users for API Management service: $ApimServiceName"

        if ($Users -and $Users.Count -gt 0) {
            foreach ($user in $Users) {
                $userId = $user.name
                $email = $user.email ?? "$userId@example.com"
                $firstName = $user.firstName ?? $userId
                $lastName = $user.lastName ?? ""
                $state = $user.state ?? "active"

                Write-Host "Creating/updating user: $userId" -ForegroundColor Green

                try {
                    # Check if user exists
                    $existingUser = az apim user show --resource-group $ResourceGroup --service-name $ApimServiceName --user-id $userId 2>$null

                    if ($existingUser) {
                        # Update existing user
                        $result = az apim user update \
                            --resource-group $ResourceGroup \
                            --service-name $ApimServiceName \
                            --user-id $userId \
                            --email $email \
                            --first-name $firstName \
                            --last-name $lastName \
                            --state $state

                        Write-Verbose "Updated user: $userId"
                    } else {
                        # Create new user with a random password
                        $password = [System.Guid]::NewGuid().ToString()
                        $result = az apim user create \
                            --resource-group $ResourceGroup \
                            --service-name $ApimServiceName \
                            --user-id $userId \
                            --email $email \
                            --first-name $firstName \
                            --last-name $lastName \
                            --password $password \
                            --state $state

                        Write-Verbose "Created user: $userId"
                    }

                    # Add user to groups if specified
                    if ($user.groups -and $user.groups.Count -gt 0) {
                        foreach ($groupName in $user.groups) {
                            Write-Verbose "Adding user $userId to group $groupName"

                            try {
                                $result = az apim group user add \
                                    --resource-group $ResourceGroup \
                                    --service-name $ApimServiceName \
                                    --group-id $groupName \
                                    --user-id $userId

                                Write-Verbose "Added user $userId to group $groupName"
                            } catch {
                                Write-Warning "Failed to add user $userId to group $groupName. Error: $_"
                            }
                        }
                    }

                    Write-Host "Successfully processed user: $userId" -ForegroundColor Green
                } catch {
                    Write-Error "Failed to process user $userId. Error: $_"
                }
            }
        } else {
            Write-Host "No users defined in configuration. Skipping user creation." -ForegroundColor Yellow
        }
    } catch {
        Write-Error "Error in Set-ApimUsers: $_"
    }
}

# Execute functions
try {
    Write-Host "Starting API import..." -ForegroundColor Cyan
    Import-APIsFromSwagger -ResourceGroup $ResourceGroup -ApimServiceName $apimServiceName

    Write-Host "Starting policy application..." -ForegroundColor Cyan
    Apply-CustomPolicies -ResourceGroup $ResourceGroup -ApimServiceName $apimServiceName

    # Process groups and users from configuration
    if ($config.parameters.groups -and $config.parameters.groups.value) {
        Write-Host "Configuring groups..." -ForegroundColor Cyan
        Set-ApimGroups -ResourceGroup $ResourceGroup -ApimServiceName $apimServiceName -Groups $config.parameters.groups.value
    }

    if ($config.parameters.users -and $config.parameters.users.value) {
        Write-Host "Configuring users..." -ForegroundColor Cyan
        Set-ApimUsers -ResourceGroup $ResourceGroup -ApimServiceName $apimServiceName -Users $config.parameters.users.value
    }

    Write-Host "Post-deployment configuration completed successfully" -ForegroundColor Green
}
catch {
    Write-Error "Post-deployment configuration failed: $_"
    exit 1
}
finally {
    # Stop transcript logging
    Stop-Transcript
}
