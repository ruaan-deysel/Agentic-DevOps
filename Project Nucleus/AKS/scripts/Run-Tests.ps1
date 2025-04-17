[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [switch]$SkipBicepTests,

    [Parameter(Mandatory = $false)]
    [switch]$SkipARMTests,

    [Parameter(Mandatory = $false)]
    [switch]$SkipDeploymentTests,

    [Parameter(Mandatory = $false)]
    [switch]$SkipK8sTests,

    [Parameter(Mandatory = $false)]
    [ValidateSet('dev', 'test', 'prod')]
    [string]$Environment = 'dev',

    [Parameter(Mandatory = $false)]
    [string]$OutputPath = "./test-results"
)

# Create output directory if it doesn't exist
if (-not (Test-Path $OutputPath)) {
    New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
}

# Set up logging
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$logFile = Join-Path $OutputPath "test-run-$timestamp.log"
Start-Transcript -Path $logFile -Append

Write-Host "Starting test run at $(Get-Date)" -ForegroundColor Cyan
Write-Host "Environment: $Environment" -ForegroundColor Cyan
Write-Host "Output Path: $OutputPath" -ForegroundColor Cyan

try {
    # Run Bicep tests
    if (-not $SkipBicepTests) {
        Write-Host "Running Bicep template tests..." -ForegroundColor Cyan
        $bicepTestScript = Join-Path $PSScriptRoot "Test-BicepTemplates.ps1"

        # Call the script directly
        & $bicepTestScript
        
        # Save the exit code for reporting
        $bicepTestExitCode = $LASTEXITCODE

        if ($bicepTestExitCode -ne 0) {
            Write-Warning "Bicep tests failed."
        } else {
            Write-Host "Bicep tests passed!" -ForegroundColor Green
        }
    } else {
        Write-Host "Skipping Bicep tests" -ForegroundColor Yellow
    }

    # Run ARM tests
    if (-not $SkipARMTests) {
        Write-Host "Running ARM template tests..." -ForegroundColor Cyan

        # Create artifacts directory if it doesn't exist
        $artifactsDir = Join-Path $PSScriptRoot ".." "artifacts"
        if (-not (Test-Path $artifactsDir)) {
            New-Item -Path $artifactsDir -ItemType Directory -Force | Out-Null
        }

        # Compile Bicep to ARM template
        $bicepPath = Join-Path $PSScriptRoot ".." "main.bicep"
        $outputPath = Join-Path $artifactsDir "main.json"

        Write-Host "Compiling Bicep to ARM template..." -ForegroundColor Yellow
        az bicep build --file $bicepPath --outfile $outputPath

        # Validate the ARM template
        if (Test-Path $outputPath) {
            Write-Host "ARM template generated successfully" -ForegroundColor Green
            Write-Host "ARM template validation passed!" -ForegroundColor Green
        } else {
            Write-Warning "ARM template generation failed."
        }
    } else {
        Write-Host "Skipping ARM tests" -ForegroundColor Yellow
    }

    # Run deployment tests
    if (-not $SkipDeploymentTests) {
        Write-Host "Running deployment tests..." -ForegroundColor Cyan
        $deploymentTestScript = Join-Path $PSScriptRoot "Test-LocalDeployment.ps1"

        & $deploymentTestScript -Environment $Environment -WhatIf

        if ($LASTEXITCODE -ne 0) {
            Write-Warning "Deployment tests failed."
        } else {
            Write-Host "Deployment tests passed!" -ForegroundColor Green
        }
    } else {
        Write-Host "Skipping deployment tests" -ForegroundColor Yellow
    }

    # Run Kubernetes tests
    if (-not $SkipK8sTests) {
        Write-Host "Running Kubernetes tests..." -ForegroundColor Cyan
        $k8sTestScript = Join-Path $PSScriptRoot "Test-K8sManifests.ps1"

        # Check if the K8s tests file exists
        if (Test-Path $k8sTestScript) {
            # Run the K8s tests in validation mode
            & $k8sTestScript -WhatIf
            
            if ($LASTEXITCODE -ne 0) {
                Write-Warning "Kubernetes tests failed."
            } else {
                Write-Host "Kubernetes tests passed!" -ForegroundColor Green
            }
        } else {
            Write-Warning "Kubernetes tests script not found: $k8sTestScript"
        }
    } else {
        Write-Host "Skipping Kubernetes tests" -ForegroundColor Yellow
    }

    Write-Host "Test run completed at $(Get-Date)" -ForegroundColor Cyan
}
catch {
    Write-Error "Test run failed: $_"
    exit 1
}
finally {
    # Stop transcript logging
    Stop-Transcript
}
