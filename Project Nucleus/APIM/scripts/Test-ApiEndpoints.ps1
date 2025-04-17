[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string]$ApimGatewayUrl,
    
    [Parameter(Mandatory = $false)]
    [string]$SubscriptionKey,
    
    [Parameter(Mandatory = $false)]
    [string]$TestConfigPath = "./tests/api-tests.json",
    
    [Parameter(Mandatory = $false)]
    [string]$LogPath = "./logs",
    
    [Parameter(Mandatory = $false)]
    [switch]$DetailedOutput
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
$logFile = Join-Path $LogPath "api-tests-$timestamp.log"
Start-Transcript -Path $logFile -Append

Write-Host "Starting API endpoint tests" -ForegroundColor Cyan
Write-Host "API Management Gateway: $ApimGatewayUrl" -ForegroundColor Cyan
Write-Host "Test Configuration: $TestConfigPath" -ForegroundColor Cyan

# Function to run a single API test
function Test-ApiEndpoint {
    param (
        [string]$Name,
        [string]$Method,
        [string]$Path,
        [hashtable]$Headers = @{},
        [object]$Body = $null,
        [int]$ExpectedStatusCode = 200,
        [string[]]$ExpectedResponseContains = @(),
        [int]$TimeoutSeconds = 30
    )
    
    Write-Host "Testing API: $Name" -ForegroundColor Yellow
    Write-Host "  Method: $Method" -ForegroundColor Gray
    Write-Host "  Path: $Path" -ForegroundColor Gray
    
    $url = "$ApimGatewayUrl$Path"
    $headers = $Headers.Clone()
    
    # Add subscription key if provided
    if ($SubscriptionKey) {
        $headers["Ocp-Apim-Subscription-Key"] = $SubscriptionKey
    }
    
    try {
        $params = @{
            Method = $Method
            Uri = $url
            Headers = $headers
            TimeoutSec = $TimeoutSeconds
            UseBasicParsing = $true
        }
        
        # Add body if provided
        if ($Body) {
            $params["Body"] = if ($Body -is [string]) { $Body } else { $Body | ConvertTo-Json -Depth 10 }
            $params["ContentType"] = "application/json"
        }
        
        # Make the request
        $response = Invoke-WebRequest @params
        
        # Check status code
        $statusCodeMatch = $response.StatusCode -eq $ExpectedStatusCode
        
        # Check response content
        $contentMatch = $true
        foreach ($expectedContent in $ExpectedResponseContains) {
            if (-not $response.Content.Contains($expectedContent)) {
                $contentMatch = $false
                break
            }
        }
        
        # Output results
        if ($statusCodeMatch -and $contentMatch) {
            Write-Host "  Result: PASS" -ForegroundColor Green
            Write-Host "  Status Code: $($response.StatusCode)" -ForegroundColor Green
            
            if ($DetailedOutput) {
                Write-Host "  Response Headers:" -ForegroundColor Gray
                $response.Headers | Format-Table -AutoSize | Out-String | Write-Host
                
                Write-Host "  Response Body:" -ForegroundColor Gray
                if ($response.Content.Length -gt 1000) {
                    Write-Host $response.Content.Substring(0, 1000) -ForegroundColor Gray
                    Write-Host "  ... (truncated)" -ForegroundColor Gray
                } else {
                    Write-Host $response.Content -ForegroundColor Gray
                }
            }
            
            return $true
        } else {
            Write-Host "  Result: FAIL" -ForegroundColor Red
            Write-Host "  Status Code: $($response.StatusCode) (Expected: $ExpectedStatusCode)" -ForegroundColor $(if ($statusCodeMatch) { "Green" } else { "Red" })
            
            if (-not $contentMatch) {
                Write-Host "  Response does not contain expected content" -ForegroundColor Red
            }
            
            if ($DetailedOutput) {
                Write-Host "  Response Headers:" -ForegroundColor Gray
                $response.Headers | Format-Table -AutoSize | Out-String | Write-Host
                
                Write-Host "  Response Body:" -ForegroundColor Gray
                if ($response.Content.Length -gt 1000) {
                    Write-Host $response.Content.Substring(0, 1000) -ForegroundColor Gray
                    Write-Host "  ... (truncated)" -ForegroundColor Gray
                } else {
                    Write-Host $response.Content -ForegroundColor Gray
                }
            }
            
            return $false
        }
    }
    catch {
        Write-Host "  Result: ERROR" -ForegroundColor Red
        Write-Host "  Error: $_" -ForegroundColor Red
        
        if ($_.Exception.Response) {
            $statusCode = $_.Exception.Response.StatusCode.value__
            Write-Host "  Status Code: $statusCode (Expected: $ExpectedStatusCode)" -ForegroundColor Red
            
            try {
                $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
                $reader.BaseStream.Position = 0
                $reader.DiscardBufferedData()
                $responseBody = $reader.ReadToEnd()
                
                Write-Host "  Response Body:" -ForegroundColor Gray
                if ($responseBody.Length -gt 1000) {
                    Write-Host $responseBody.Substring(0, 1000) -ForegroundColor Gray
                    Write-Host "  ... (truncated)" -ForegroundColor Gray
                } else {
                    Write-Host $responseBody -ForegroundColor Gray
                }
            }
            catch {
                Write-Host "  Could not read response body: $_" -ForegroundColor Red
            }
        }
        
        return $false
    }
}

try {
    # Check if test configuration file exists
    if (-not (Test-Path $TestConfigPath)) {
        Write-Error "Test configuration file not found: $TestConfigPath"
        exit 1
    }
    
    # Load test configuration
    $testConfig = Get-Content $TestConfigPath -Raw | ConvertFrom-Json
    
    if (-not $testConfig.tests -or $testConfig.tests.Count -eq 0) {
        Write-Error "No tests found in configuration file"
        exit 1
    }
    
    # Run tests
    $passedTests = 0
    $failedTests = 0
    
    foreach ($test in $testConfig.tests) {
        $headers = @{}
        
        if ($test.headers) {
            foreach ($header in $test.headers.PSObject.Properties) {
                $headers[$header.Name] = $header.Value
            }
        }
        
        $result = Test-ApiEndpoint -Name $test.name -Method $test.method -Path $test.path -Headers $headers -Body $test.body -ExpectedStatusCode $test.expectedStatusCode -ExpectedResponseContains $test.expectedResponseContains -TimeoutSeconds $test.timeoutSeconds
        
        if ($result) {
            $passedTests++
        } else {
            $failedTests++
        }
        
        Write-Host ""
    }
    
    # Output summary
    Write-Host "Test Summary:" -ForegroundColor Cyan
    Write-Host "  Total Tests: $($testConfig.tests.Count)" -ForegroundColor Cyan
    Write-Host "  Passed: $passedTests" -ForegroundColor $(if ($passedTests -gt 0) { "Green" } else { "Gray" })
    Write-Host "  Failed: $failedTests" -ForegroundColor $(if ($failedTests -gt 0) { "Red" } else { "Gray" })
    
    if ($failedTests -gt 0) {
        Write-Host "Some tests failed. Check the log for details." -ForegroundColor Red
        exit 1
    } else {
        Write-Host "All tests passed successfully!" -ForegroundColor Green
    }
}
catch {
    Write-Error "API testing failed: $_"
    exit 1
}
finally {
    # Stop transcript logging
    Stop-Transcript
}
