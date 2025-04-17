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
$bicepParamPath = Join-Path $PSScriptRoot ".." "config" "ms.aks" "parameters.$Environment.bicepparam"

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

# Get AKS cluster name from config
$aksClusterName = $config.parameters.aksClusterName.value

Write-Host "Running post-deployment configuration for $aksClusterName in resource group $ResourceGroup"

# Function to get AKS credentials
function Get-AksCredentials {
    param (
        [string]$ResourceGroup,
        [string]$ClusterName
    )
    
    try {
        Write-Host "Getting AKS credentials for cluster: $ClusterName" -ForegroundColor Yellow
        az aks get-credentials --resource-group $ResourceGroup --name $ClusterName --overwrite-existing
        
        if ($LASTEXITCODE -ne 0) {
            throw "Failed to get AKS credentials"
        }
        
        # Verify connection to the cluster
        $nodes = kubectl get nodes
        if ($LASTEXITCODE -ne 0) {
            throw "Failed to connect to AKS cluster"
        }
        
        Write-Host "Successfully connected to AKS cluster: $ClusterName" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Error "Error getting AKS credentials: $_"
        return $false
    }
}

# Function to create additional node pools
function Add-NodePools {
    param (
        [string]$ResourceGroup,
        [string]$ClusterName,
        [array]$NodeGroups
    )
    
    try {
        Write-Host "Adding node pools to AKS cluster: $ClusterName" -ForegroundColor Yellow
        
        if ($NodeGroups -and $NodeGroups.Count -gt 0) {
            foreach ($nodeGroup in $NodeGroups) {
                $nodePoolName = $nodeGroup.name
                
                # Check if node pool already exists
                $existingPool = az aks nodepool list --resource-group $ResourceGroup --cluster-name $ClusterName --query "[?name=='$nodePoolName']" | ConvertFrom-Json
                
                if ($existingPool -and $existingPool.Count -gt 0) {
                    Write-Host "Node pool $nodePoolName already exists, updating..." -ForegroundColor Yellow
                    
                    # Update existing node pool
                    az aks nodepool update `
                        --resource-group $ResourceGroup `
                        --cluster-name $ClusterName `
                        --name $nodePoolName `
                        --enable-cluster-autoscaler $nodeGroup.enableAutoScaling `
                        --min-count $nodeGroup.minCount `
                        --max-count $nodeGroup.maxCount `
                        --node-count $nodeGroup.count `
                        --labels $nodeGroup.labels
                    
                    if ($LASTEXITCODE -ne 0) {
                        throw "Failed to update node pool $nodePoolName"
                    }
                    
                    Write-Host "Node pool $nodePoolName updated successfully" -ForegroundColor Green
                }
                else {
                    Write-Host "Creating new node pool: $nodePoolName" -ForegroundColor Yellow
                    
                    # Create new node pool
                    $addNodePoolCmd = "az aks nodepool add " + `
                        "--resource-group $ResourceGroup " + `
                        "--cluster-name $ClusterName " + `
                        "--name $nodePoolName " + `
                        "--node-count $($nodeGroup.count) " + `
                        "--node-vm-size $($nodeGroup.vmSize) " + `
                        "--mode $($nodeGroup.mode) " + `
                        "--os-type $($nodeGroup.osType) " + `
                        "--os-disk-size-gb $($nodeGroup.osDiskSizeGB) "
                    
                    # Add optional parameters
                    if ($nodeGroup.enableAutoScaling) {
                        $addNodePoolCmd += "--enable-cluster-autoscaler " + `
                            "--min-count $($nodeGroup.minCount) " + `
                            "--max-count $($nodeGroup.maxCount) "
                    }
                    
                    # Add labels if specified
                    if ($nodeGroup.labels) {
                        $labelsString = ""
                        foreach ($label in $nodeGroup.labels.PSObject.Properties) {
                            $labelsString += "$($label.Name)=$($label.Value) "
                        }
                        $labelsString = $labelsString.Trim()
                        $addNodePoolCmd += "--labels `"$labelsString`" "
                    }
                    
                    # Add taints if specified
                    if ($nodeGroup.taints -and $nodeGroup.taints.Count -gt 0) {
                        $taintsString = $nodeGroup.taints -join " "
                        $addNodePoolCmd += "--node-taints `"$taintsString`" "
                    }
                    
                    # Execute the command
                    Invoke-Expression $addNodePoolCmd
                    
                    if ($LASTEXITCODE -ne 0) {
                        throw "Failed to create node pool $nodePoolName"
                    }
                    
                    Write-Host "Node pool $nodePoolName created successfully" -ForegroundColor Green
                }
            }
        }
        else {
            Write-Host "No additional node pools specified" -ForegroundColor Yellow
        }
        
        return $true
    }
    catch {
        Write-Error "Error adding node pools: $_"
        return $false
    }
}

# Function to deploy Kubernetes workloads
function Deploy-Workloads {
    param (
        [array]$Workloads
    )
    
    try {
        Write-Host "Deploying Kubernetes workloads" -ForegroundColor Yellow
        
        if ($Workloads -and $Workloads.Count -gt 0) {
            foreach ($workload in $Workloads) {
                $workloadName = $workload.name
                $namespace = $workload.namespace
                
                # Create namespace if it doesn't exist
                $namespaceExists = kubectl get namespace $namespace 2>$null
                if ($LASTEXITCODE -ne 0) {
                    Write-Host "Creating namespace: $namespace" -ForegroundColor Yellow
                    kubectl create namespace $namespace
                    if ($LASTEXITCODE -ne 0) {
                        throw "Failed to create namespace $namespace"
                    }
                }
                
                # Deploy workload based on type
                switch ($workload.type) {
                    "helm" {
                        Write-Host "Deploying Helm chart: $workloadName" -ForegroundColor Yellow
                        
                        # Add Helm repository if specified
                        if ($workload.repository) {
                            $repoName = $workload.repository.Split('/')[-1].Split('.')[0]
                            helm repo add $repoName $workload.repository
                            helm repo update
                        }
                        
                        # Create values file if values are specified
                        $valuesFile = $null
                        if ($workload.values) {
                            $valuesFile = Join-Path $env:TEMP "$workloadName-values.yaml"
                            $workload.values | ConvertTo-Yaml | Out-File -FilePath $valuesFile -Encoding utf8
                        }
                        
                        # Install or upgrade Helm chart
                        $helmCmd = "helm upgrade --install $workloadName $($workload.chart) " + `
                            "--namespace $namespace " + `
                            "--create-namespace "
                        
                        if ($workload.version) {
                            $helmCmd += "--version $($workload.version) "
                        }
                        
                        if ($valuesFile) {
                            $helmCmd += "--values $valuesFile "
                        }
                        
                        if ($repoName) {
                            $helmCmd += "--repo $($workload.repository) "
                        }
                        
                        # Execute the command
                        Invoke-Expression $helmCmd
                        
                        if ($LASTEXITCODE -ne 0) {
                            throw "Failed to deploy Helm chart $workloadName"
                        }
                        
                        Write-Host "Helm chart $workloadName deployed successfully" -ForegroundColor Green
                        
                        # Clean up values file
                        if ($valuesFile -and (Test-Path $valuesFile)) {
                            Remove-Item $valuesFile -Force
                        }
                    }
                    "manifest" {
                        Write-Host "Deploying manifest: $workloadName" -ForegroundColor Yellow
                        
                        # Apply manifest file
                        $manifestPath = Join-Path $PSScriptRoot ".." "manifests" "$workloadName.yaml"
                        if (Test-Path $manifestPath) {
                            kubectl apply -f $manifestPath -n $namespace
                            
                            if ($LASTEXITCODE -ne 0) {
                                throw "Failed to apply manifest $workloadName"
                            }
                            
                            Write-Host "Manifest $workloadName applied successfully" -ForegroundColor Green
                        }
                        else {
                            Write-Warning "Manifest file not found: $manifestPath"
                        }
                    }
                    default {
                        Write-Warning "Unknown workload type: $($workload.type)"
                    }
                }
            }
        }
        else {
            Write-Host "No workloads specified" -ForegroundColor Yellow
        }
        
        return $true
    }
    catch {
        Write-Error "Error deploying workloads: $_"
        return $false
    }
}

# Execute functions
try {
    # Get AKS credentials
    $credentialsSuccess = Get-AksCredentials -ResourceGroup $ResourceGroup -ClusterName $aksClusterName
    
    if ($credentialsSuccess) {
        # Add node pools
        if ($config.parameters.nodeGroups -and $config.parameters.nodeGroups.value) {
            Write-Host "Adding node pools..." -ForegroundColor Cyan
            Add-NodePools -ResourceGroup $ResourceGroup -ClusterName $aksClusterName -NodeGroups $config.parameters.nodeGroups.value
        }
        
        # Deploy workloads
        if ($config.parameters.workloads -and $config.parameters.workloads.value) {
            Write-Host "Deploying workloads..." -ForegroundColor Cyan
            Deploy-Workloads -Workloads $config.parameters.workloads.value
        }
        
        Write-Host "Post-deployment configuration completed successfully" -ForegroundColor Green
    }
    else {
        Write-Error "Failed to get AKS credentials, cannot proceed with post-deployment configuration"
        exit 1
    }
}
catch {
    Write-Error "Post-deployment configuration failed: $_"
    exit 1
}
finally {
    # Stop transcript logging
    Stop-Transcript
}
