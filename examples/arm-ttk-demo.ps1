# ARM Template Test Toolkit (ARM-TTK) Demo Script
# This script demonstrates how to use ARM-TTK to validate ARM templates

# First, build the Bicep template to ARM JSON
Write-Host "Building Bicep template to ARM JSON..." -ForegroundColor Cyan
bicep build ./storage-account.bicep --outfile ./storage-account.json

# Run ARM-TTK tests on the generated ARM template
Write-Host "Running ARM-TTK tests on the ARM template..." -ForegroundColor Cyan
$testResults = & /opt/arm-ttk/arm-ttk.ps1 Test-AzTemplate -TemplatePath ./storage-account.json

# Display test results
$passedTests = $testResults | Where-Object { $_.Passed -eq $true }
$failedTests = $testResults | Where-Object { $_.Passed -eq $false }

Write-Host "Test Results Summary:" -ForegroundColor Yellow
Write-Host "  Passed: $($passedTests.Count)" -ForegroundColor Green
Write-Host "  Failed: $($failedTests.Count)" -ForegroundColor Red

if ($failedTests.Count -gt 0) {
    Write-Host "`nFailed Tests:" -ForegroundColor Red
    foreach ($test in $failedTests) {
        Write-Host "  - $($test.Name): $($test.Errors -join ', ')" -ForegroundColor Red
    }
}

# Run What-If deployment to see what would change
Write-Host "`nRunning What-If deployment to see what would change..." -ForegroundColor Cyan
Write-Host "To perform a what-if deployment, run:" -ForegroundColor Yellow
Write-Host "az deployment group what-if --resource-group <resource-group-name> --template-file ./storage-account.json" -ForegroundColor Yellow

# Run PSRule for Azure validation
Write-Host "`nRunning PSRule for Azure validation..." -ForegroundColor Cyan
$rulePath = Join-Path -Path (Get-Module PSRule.Rules.Azure).ModuleBase -ChildPath 'rules'
$result = "./storage-account.json" | Assert-PSRule -Module PSRule.Rules.Azure -Path $rulePath

# Display PSRule results
$passedRules = $result | Where-Object { $_.Outcome -eq 'Pass' }
$failedRules = $result | Where-Object { $_.Outcome -eq 'Fail' }

Write-Host "PSRule Results Summary:" -ForegroundColor Yellow
Write-Host "  Passed: $($passedRules.Count)" -ForegroundColor Green
Write-Host "  Failed: $($failedRules.Count)" -ForegroundColor Red

if ($failedRules.Count -gt 0) {
    Write-Host "`nFailed Rules:" -ForegroundColor Red
    $failedRules | Format-Table -Property RuleName, TargetName, Outcome
}
