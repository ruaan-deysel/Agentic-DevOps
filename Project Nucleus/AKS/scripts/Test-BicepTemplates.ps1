[CmdletBinding()]
param (
    [Parameter()]
    [string]$TestsPath = ".\tests",

    [Parameter()]
    [string]$OutputPath = ".\test-output"
)

# Create test output directory if it doesn't exist
if (-not (Test-Path $OutputPath)) {
    New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
}

# Function to validate a Bicep file
function Test-BicepFile {
    param (
        [string]$FilePath,
        [string]$TestName
    )

    Write-Host "Testing Bicep file: $FilePath - $TestName"

    try {
        $process = Start-Process -FilePath "az" -ArgumentList "bicep", "build", "--file", $FilePath -Wait -NoNewWindow -PassThru -RedirectStandardError "$OutputPath\$TestName-error.log"

        if ($process.ExitCode -eq 0) {
            Write-Host "✓ $TestName - Bicep validation passed" -ForegroundColor Green
            return $true
        } else {
            Write-Host "✗ $TestName - Bicep validation failed. See $OutputPath\$TestName-error.log for details" -ForegroundColor Red
            return $false
        }
    } catch {
        Write-Host "✗ $TestName - Bicep validation failed with exception: $_" -ForegroundColor Red
        return $false
    }
}

# Function to validate a parameter file against a Bicep file
function Test-ParameterFileAgainstBicep {
    param (
        [string]$BicepFilePath,
        [string]$ParameterFilePath,
        [string]$TestName
    )

    Write-Host "Testing parameter file: $ParameterFilePath against Bicep: $BicepFilePath - $TestName"

    try {
        # Instead of using Azure deployment validation, we'll use bicep build-params
        # This validates the parameter file syntax without requiring an Azure connection
        $process = Start-Process -FilePath "az" -ArgumentList "bicep", "build-params", "--file", $ParameterFilePath -Wait -NoNewWindow -PassThru -RedirectStandardError "$OutputPath\$TestName-error.log"

        if ($process.ExitCode -eq 0) {
            Write-Host "✓ $TestName - Parameter validation passed" -ForegroundColor Green
            return $true
        } else {
            Write-Host "✗ $TestName - Parameter validation failed. See $OutputPath\$TestName-error.log for details" -ForegroundColor Red
            return $false
        }
    } catch {
        Write-Host "✗ $TestName - Parameter validation failed with exception: $_" -ForegroundColor Red
        return $false
    }
}

# Function to test parameter files for required parameters
function Test-ParameterFileRequiredParams {
    param (
        [string]$ParameterFilePath,
        [string]$TestName,
        [string[]]$RequiredParameters
    )

    Write-Host "Testing parameter file for required parameters: $ParameterFilePath - $TestName"

    $success = $true
    try {
        # Check file extension to determine how to parse it
        $fileExtension = [System.IO.Path]::GetExtension($ParameterFilePath)

        if ($fileExtension -eq '.json') {
            # Parse JSON parameter file
            $paramContent = Get-Content -Path $ParameterFilePath -Raw | ConvertFrom-Json

            foreach ($param in $RequiredParameters) {
                if (-not $paramContent.parameters.$param) {
                    Write-Host "✗ Required parameter '$param' not found in $ParameterFilePath" -ForegroundColor Red
                    $success = $false
                }
            }
        }
        elseif ($fileExtension -eq '.bicepparam') {
            # Parse Bicep parameter file
            $paramContent = Get-Content -Path $ParameterFilePath -Raw

            foreach ($param in $RequiredParameters) {
                if (-not ($paramContent -match "param\s+$param\s*=")) {
                    Write-Host "✗ Required parameter '$param' not found in $ParameterFilePath" -ForegroundColor Red
                    $success = $false
                }
            }
        }
        else {
            Write-Host "✗ Unsupported parameter file extension: $fileExtension" -ForegroundColor Red
            $success = $false
        }

        if ($success) {
            Write-Host "✓ $TestName - All required parameters present" -ForegroundColor Green
        }

        return $success
    } catch {
        Write-Host "✗ $TestName - Parameter file validation failed with exception: $_" -ForegroundColor Red
        return $false
    }
}

# Run the tests
Write-Host "Running AKS Bicep Tests" -ForegroundColor Cyan
Write-Host "=======================" -ForegroundColor Cyan

$testResults = @()

# Test 1 - Validate main Bicep file
$test1Result = Test-BicepFile -FilePath ".\main.bicep" -TestName "MainBicepValidation"
$testResults += [PSCustomObject]@{
    TestName = "MainBicepValidation"
    Result = $test1Result
}

# Test 2 - Validate dev parameter file
$requiredParams = @('aksClusterName', 'environment', 'kubernetesVersion')
$test2Result = Test-ParameterFileRequiredParams -ParameterFilePath ".\config\ms.aks\parameters.dev.bicepparam" -TestName "DevParametersRequiredParams" -RequiredParameters $requiredParams
$testResults += [PSCustomObject]@{
    TestName = "DevParametersRequiredParams"
    Result = $test2Result
}

# Test 3 - Validate test parameter file
$test3Result = Test-ParameterFileRequiredParams -ParameterFilePath ".\config\ms.aks\parameters.test.bicepparam" -TestName "TestParametersRequiredParams" -RequiredParameters $requiredParams
$testResults += [PSCustomObject]@{
    TestName = "TestParametersRequiredParams"
    Result = $test3Result
}

# Test 4 - Validate prod parameter file
$test4Result = Test-ParameterFileRequiredParams -ParameterFilePath ".\config\ms.aks\parameters.prod.bicepparam" -TestName "ProdParametersRequiredParams" -RequiredParameters $requiredParams
$testResults += [PSCustomObject]@{
    TestName = "ProdParametersRequiredParams"
    Result = $test4Result
}

# Test 5 - Validate parameter files against Bicep (dev)
$test5Result = Test-ParameterFileAgainstBicep -BicepFilePath ".\main.bicep" -ParameterFilePath ".\config\ms.aks\parameters.dev.bicepparam" -TestName "DevParametersValidation"
$testResults += [PSCustomObject]@{
    TestName = "DevParametersValidation"
    Result = $test5Result
}

# Test 6 - Validate parameter files against Bicep (test)
$test6Result = Test-ParameterFileAgainstBicep -BicepFilePath ".\main.bicep" -ParameterFilePath ".\config\ms.aks\parameters.test.bicepparam" -TestName "TestParametersValidation"
$testResults += [PSCustomObject]@{
    TestName = "TestParametersValidation"
    Result = $test6Result
}

# Test 7 - Validate parameter files against Bicep (prod)
$test7Result = Test-ParameterFileAgainstBicep -BicepFilePath ".\main.bicep" -ParameterFilePath ".\config\ms.aks\parameters.prod.bicepparam" -TestName "ProdParametersValidation"
$testResults += [PSCustomObject]@{
    TestName = "ProdParametersValidation"
    Result = $test7Result
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
