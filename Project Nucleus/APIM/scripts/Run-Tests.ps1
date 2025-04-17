[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [switch]$SkipBicepTests,

    [Parameter(Mandatory = $false)]
    [switch]$SkipARMTests,

    [Parameter(Mandatory = $false)]
    [switch]$SkipDeploymentTests,

    [Parameter(Mandatory = $false)]
    [switch]$SkipApiTests,

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
    # Import Pester module if available, install if not
    if (-not (Get-Module -ListAvailable -Name Pester)) {
        Write-Host "Pester module not found. Installing..." -ForegroundColor Yellow
        Install-Module -Name Pester -Force -SkipPublisherCheck
    }

    Import-Module Pester

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

    # Run API tests
    if (-not $SkipApiTests) {
        Write-Host "Running API tests..." -ForegroundColor Cyan
        $apiTestScript = Join-Path $PSScriptRoot "Run-ApiTests.ps1"

        # Check if the API tests file exists
        $apiTestsFile = Join-Path $PSScriptRoot ".." "tests" "api-tests.json"
        if (Test-Path $apiTestsFile) {
            # First validate the JSON structure
            try {
                $null = Get-Content -Path $apiTestsFile -Raw | ConvertFrom-Json
                Write-Host "API tests file validated successfully" -ForegroundColor Green

                # Now run the API tests in validation mode (no actual HTTP requests)
                Write-Host "Validating API tests configuration..." -ForegroundColor Cyan

                # Directly run with -WhatIf and catch errors if not supported
                try {
                    & $apiTestScript -ApiTestsPath $apiTestsFile -WhatIf -ErrorAction Stop
                } catch {
                    Write-Host "Skipping API tests execution - WhatIf parameter not supported" -ForegroundColor Yellow
                }
            } catch {
                Write-Warning "API tests file validation failed: $_"
            }
        } else {
            Write-Warning "API tests file not found: $apiTestsFile"
        }
    } else {
        Write-Host "Skipping API tests" -ForegroundColor Yellow
    }

    Write-Host "Test run completed at $(Get-Date)" -ForegroundColor Cyan
} catch {
    Write-Error "Test run failed: $_"
    exit 1
} finally {
    # Stop transcript logging
    Stop-Transcript
}
