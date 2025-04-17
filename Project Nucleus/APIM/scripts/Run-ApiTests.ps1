[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$ApiTestsPath = ".\tests\api-tests.json",

    [Parameter(Mandatory = $false)]
    [string]$ApimGatewayUrl,

    [Parameter(Mandatory = $false)]
    [string]$SubscriptionKey,

    [Parameter(Mandatory = $false)]
    [string]$OutputPath = ".\test-output",

    [Parameter(Mandatory = $false)]
    [switch]$DetailedOutput,

    [Parameter(Mandatory = $false)]
    [switch]$WhatIf
)

# Create test output directory if it doesn't exist
if (-not (Test-Path $OutputPath)) {
    New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
}

# Set up logging
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$logFile = Join-Path $OutputPath "api-tests-$timestamp.log"
Start-Transcript -Path $logFile -Append

Write-Host "Starting API Tests" -ForegroundColor Cyan
Write-Host "================" -ForegroundColor Cyan

# Check if API tests file exists
if (-not (Test-Path $ApiTestsPath)) {
    Write-Error "API tests file not found: $ApiTestsPath"
    exit 1
}

# Load API tests
try {
    $apiTests = Get-Content -Path $ApiTestsPath -Raw | ConvertFrom-Json
    Write-Host "Loaded API tests from $ApiTestsPath" -ForegroundColor Green
}
catch {
    Write-Error "Failed to load API tests: $_"
    exit 1
}

# If we're in WhatIf mode, just validate the test file structure and exit
if ($WhatIf) {
    Write-Host "Running in WhatIf mode - validating test file structure only" -ForegroundColor Yellow

    # Check if the tests array exists and has items
    if (-not $apiTests.tests -or $apiTests.tests.Count -eq 0) {
        Write-Error "No tests found in the API tests file"
        exit 1
    }

    # Validate each test has the required properties
    $validTests = 0
    foreach ($test in $apiTests.tests) {
        $isValid = $true
        $missingProps = @()

        # Check required properties
        foreach ($prop in @('name', 'method', 'path', 'expectedStatusCode')) {
            if (-not $test.$prop) {
                $isValid = $false
                $missingProps += $prop
            }
        }

        if ($isValid) {
            Write-Host "✓ Test '$($test.name)' is valid" -ForegroundColor Green
            $validTests++
        } else {
            Write-Host "✗ Test '$($test.name)' is missing required properties: $($missingProps -join ', ')" -ForegroundColor Red
        }
    }

    Write-Host "Found $validTests valid tests out of $($apiTests.tests.Count) total tests" -ForegroundColor Cyan

    if ($validTests -eq $apiTests.tests.Count) {
        Write-Host "All tests are valid!" -ForegroundColor Green
        exit 0
    } else {
        Write-Error "Some tests are invalid. Please fix the issues and try again."
        exit 1
    }
}

# If ApimGatewayUrl is not provided, try to get it from the API tests file
if (-not $ApimGatewayUrl -and $apiTests.baseUrl) {
    $ApimGatewayUrl = $apiTests.baseUrl
    Write-Host "Using base URL from API tests file: $ApimGatewayUrl" -ForegroundColor Yellow
}

# If ApimGatewayUrl is still not provided, prompt the user
if (-not $ApimGatewayUrl) {
    $ApimGatewayUrl = Read-Host "Enter the APIM Gateway URL (e.g., https://apim-nucleus-dev.azure-api.net)"
}

# If SubscriptionKey is not provided, try to get it from the API tests file
if (-not $SubscriptionKey -and $apiTests.subscriptionKey) {
    $SubscriptionKey = $apiTests.subscriptionKey
    Write-Host "Using subscription key from API tests file" -ForegroundColor Yellow
}

# If SubscriptionKey is still not provided, prompt the user
if (-not $SubscriptionKey) {
    $SubscriptionKey = Read-Host "Enter the APIM subscription key"
}

# Function to run a single API test
function Invoke-ApiTest {
    param (
        [PSCustomObject]$Test,
        [string]$BaseUrl,
        [string]$SubscriptionKey
    )

    $testName = $Test.name
    $method = $Test.method
    $path = $Test.path
    $expectedStatusCode = $Test.expectedStatusCode
    $headers = @{
        "Ocp-Apim-Subscription-Key" = $SubscriptionKey
    }

    # Add any additional headers from the test
    if ($Test.headers) {
        foreach ($header in $Test.headers.PSObject.Properties) {
            $headers[$header.Name] = $header.Value
        }
    }

    $url = "$BaseUrl$path"

    Write-Host "Running test: $testName" -ForegroundColor Cyan
    Write-Host "  URL: $url" -ForegroundColor Gray
    Write-Host "  Method: $method" -ForegroundColor Gray

    try {
        $params = @{
            Method = $method
            Uri = $url
            Headers = $headers
            UseBasicParsing = $true
            ErrorAction = "Stop"
        }

        # Add body if provided
        if ($Test.body) {
            $params.Body = $Test.body | ConvertTo-Json -Depth 10
            $params.ContentType = "application/json"
        }

        # Invoke the request
        $response = Invoke-WebRequest @params

        # Check status code
        $statusCode = $response.StatusCode
        if ($statusCode -eq $expectedStatusCode) {
            Write-Host "  ✓ Status code: $statusCode (Expected: $expectedStatusCode)" -ForegroundColor Green
            $success = $true
        }
        else {
            Write-Host "  ✗ Status code: $statusCode (Expected: $expectedStatusCode)" -ForegroundColor Red
            $success = $false
        }

        # Check response body if validation is provided
        if ($Test.responseValidation) {
            $responseBody = $response.Content | ConvertFrom-Json

            foreach ($validation in $Test.responseValidation) {
                $path = $validation.path
                $expectedValue = $validation.value

                # Extract value from response using the path
                $actualValue = $responseBody
                foreach ($segment in $path.Split('.')) {
                    $actualValue = $actualValue.$segment
                }

                if ($actualValue -eq $expectedValue) {
                    Write-Host "  ✓ Response validation: $path = $actualValue (Expected: $expectedValue)" -ForegroundColor Green
                }
                else {
                    Write-Host "  ✗ Response validation: $path = $actualValue (Expected: $expectedValue)" -ForegroundColor Red
                    $success = $false
                }
            }
        }

        # Output detailed response if requested
        if ($DetailedOutput) {
            Write-Host "  Response Headers:" -ForegroundColor Gray
            $response.Headers | Format-Table -AutoSize | Out-String | Write-Host

            Write-Host "  Response Body:" -ForegroundColor Gray
            $response.Content | ConvertFrom-Json | ConvertTo-Json -Depth 10 | Write-Host
        }

        return $success
    }
    catch {
        $statusCode = $_.Exception.Response.StatusCode.value__

        Write-Host "  ✗ Request failed: $_" -ForegroundColor Red
        Write-Host "  Status code: $statusCode (Expected: $expectedStatusCode)" -ForegroundColor Red

        # If the status code matches the expected one, consider it a success
        if ($statusCode -eq $expectedStatusCode) {
            Write-Host "  ✓ Status code matches expected value" -ForegroundColor Green
            return $true
        }

        return $false
    }
}

# Run the tests
$testResults = @()
$totalTests = $apiTests.tests.Count
$passedTests = 0

foreach ($test in $apiTests.tests) {
    $result = Invoke-ApiTest -Test $test -BaseUrl $ApimGatewayUrl -SubscriptionKey $SubscriptionKey

    $testResults += [PSCustomObject]@{
        TestName = $test.name
        Result = $result
    }

    if ($result) {
        $passedTests++
    }

    Write-Host ""
}

# Print summary
Write-Host "Test Summary" -ForegroundColor Cyan
Write-Host "===========" -ForegroundColor Cyan
$testResults | Format-Table -Property TestName, Result

$successRate = [math]::Round(($passedTests / $totalTests) * 100, 2)
Write-Host "Tests passed: $passedTests/$totalTests ($successRate%)" -ForegroundColor $(if ($passedTests -eq $totalTests) { 'Green' } else { 'Yellow' })

if ($passedTests -ne $totalTests) {
    Write-Host "Some tests failed. Check the logs in $logFile for details." -ForegroundColor Yellow
    exit 1
}
else {
    Write-Host "All tests passed!" -ForegroundColor Green
    exit 0
}

Stop-Transcript
