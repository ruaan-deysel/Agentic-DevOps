[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$ManifestsPath = ".\manifests",
    
    [Parameter(Mandatory = $false)]
    [string]$OutputPath = ".\test-output",
    
    [Parameter(Mandatory = $false)]
    [switch]$WhatIf
)

# Create test output directory if it doesn't exist
if (-not (Test-Path $OutputPath)) {
    New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
}

# Set up logging
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$logFile = Join-Path $OutputPath "k8s-tests-$timestamp.log"
Start-Transcript -Path $logFile -Append

Write-Host "Starting Kubernetes Manifest Tests" -ForegroundColor Cyan
Write-Host "=================================" -ForegroundColor Cyan

# Function to validate a Kubernetes YAML file
function Test-KubernetesManifest {
    param (
        [string]$FilePath,
        [string]$TestName
    )

    Write-Host "Testing Kubernetes manifest: $FilePath - $TestName"

    try {
        if ($WhatIf) {
            # In WhatIf mode, just check if the file is valid YAML
            $yamlContent = Get-Content -Path $FilePath -Raw
            $null = ConvertFrom-Yaml -Yaml $yamlContent
            Write-Host "✓ $TestName - YAML validation passed" -ForegroundColor Green
            return $true
        } else {
            # Use kubectl to validate the manifest
            $process = Start-Process -FilePath "kubectl" -ArgumentList "apply", "--dry-run=client", "--validate=true", "-f", $FilePath -Wait -NoNewWindow -PassThru -RedirectStandardError "$OutputPath\$TestName-error.log"

            if ($process.ExitCode -eq 0) {
                Write-Host "✓ $TestName - Kubernetes manifest validation passed" -ForegroundColor Green
                return $true
            } else {
                Write-Host "✗ $TestName - Kubernetes manifest validation failed. See $OutputPath\$TestName-error.log for details" -ForegroundColor Red
                return $false
            }
        }
    } catch {
        Write-Host "✗ $TestName - Kubernetes manifest validation failed with exception: $_" -ForegroundColor Red
        return $false
    }
}

# Check if manifests directory exists
if (-not (Test-Path $ManifestsPath)) {
    Write-Host "Manifests directory not found: $ManifestsPath" -ForegroundColor Yellow
    Write-Host "Creating manifests directory..." -ForegroundColor Yellow
    New-Item -Path $ManifestsPath -ItemType Directory -Force | Out-Null
    
    # Create a sample manifest for testing
    $sampleManifestPath = Join-Path $ManifestsPath "sample-deployment.yaml"
    @"
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment
  labels:
    app: nginx
spec:
  replicas: 3
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx:1.21
        ports:
        - containerPort: 80
"@ | Out-File -FilePath $sampleManifestPath -Encoding utf8
    
    Write-Host "Created sample manifest: $sampleManifestPath" -ForegroundColor Green
}

# Get all YAML files in the manifests directory
$manifestFiles = Get-ChildItem -Path $ManifestsPath -Filter "*.yaml" -Recurse
$manifestFiles += Get-ChildItem -Path $ManifestsPath -Filter "*.yml" -Recurse

if ($manifestFiles.Count -eq 0) {
    Write-Warning "No Kubernetes manifest files found in $ManifestsPath"
    exit 0
}

Write-Host "Found $($manifestFiles.Count) Kubernetes manifest files" -ForegroundColor Cyan

# Run the tests
$testResults = @()

foreach ($file in $manifestFiles) {
    $testName = "Validate-$($file.Name)"
    $testResult = Test-KubernetesManifest -FilePath $file.FullName -TestName $testName
    
    $testResults += [PSCustomObject]@{
        TestName = $testName
        FilePath = $file.FullName
        Result = $testResult
    }
}

# Print summary
Write-Host "`nTest Summary" -ForegroundColor Cyan
Write-Host "============" -ForegroundColor Cyan
$testResults | Format-Table -Property TestName, Result

$passedTests = ($testResults | Where-Object { $_.Result -eq $true }).Count
$totalTests = $testResults.Count
$successRate = [math]::Round(($passedTests / $totalTests) * 100, 2)

Write-Host "Tests passed: $passedTests/$totalTests ($successRate%)" -ForegroundColor $(if ($passedTests -eq $totalTests) { 'Green' } else { 'Yellow' })

if ($passedTests -ne $totalTests) {
    Write-Host "Some tests failed. Check the logs in $OutputPath for details." -ForegroundColor Yellow
    exit 1
} else {
    Write-Host "All tests passed!" -ForegroundColor Green
    exit 0
}
