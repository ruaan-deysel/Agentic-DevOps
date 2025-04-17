# Fixes for Test Execution Issues

## Overview
This document outlines the fixes implemented to address the issues identified in BUG.md.

## Bicep Tests Issues

### Issue 1: Pester Module Version Compatibility
**Problem:** The test script uses `New-PesterConfiguration` which is not available in Pester 3.4.0.

**Fix Implemented:**
- Created alternative testing scripts that don't rely on Pester:
  - `scripts/Validate-Templates.sh` - A simple bash script to validate Bicep templates
  - Enhanced `scripts/Test-BicepTemplates.ps1` to work without Pester dependencies

**How to Use:**
```bash
# Run the simple validation script
./scripts/Validate-Templates.sh
```

### Issue 2: Parameter File Extension Mismatch
**Problem:** The test scripts were looking for `.json` parameter files but the workspace uses `.bicepparam` files.

**Fix Implemented:**
- Updated `scripts/Test-BicepTemplates.ps1` to support `.bicepparam` files
- Modified the parameter file path references to use `.bicepparam` extension
- Added logic to parse Bicep parameter files differently from JSON parameter files

**How to Use:**
```powershell
# Run the updated Bicep tests
./scripts/Test-BicepTemplates.ps1
```

### Issue 3: Bicep Validation Failures
**Problem:** Bicep validation was failing due to various issues.

**Fix Implemented:**
- Fixed the path reference in parameter files from `using '../main.bicep'` to `using '../../main.bicep'`
- Updated company name from "Contoso" to "DXC" in all parameter files and the main Bicep file
- Fixed parameter mismatch in the prod parameter file (replaced `virtualNetworkConfiguration` with `subnetResourceId`)

**How to Use:**
```powershell
# Validate the Bicep templates
az bicep build --file main.bicep
```

## API Tests Issues

### Issue 1: No Clear API Test Runner
**Problem:** The workspace contains `tests/api-tests.json` with API endpoint tests, but there was no clear script to run these tests.

**Fix Implemented:**
- Created a new `scripts/Run-ApiTests.ps1` script to run the API tests
- Enhanced the `tests/api-tests.json` file with additional configuration
- Added API testing section to the README.md

**How to Use:**
```powershell
# Run API tests
./scripts/Run-ApiTests.ps1

# Run API tests with specific gateway URL and subscription key
./scripts/Run-ApiTests.ps1 -ApimGatewayUrl "https://apim-nucleus-dev.azure-api.net" -SubscriptionKey "your-subscription-key"
```

### Issue 2: Local Deployment Test Requirements
**Problem:** Prerequisites for running local deployment tests were not clear.

**Fix Implemented:**
- Updated the README.md with detailed information about local testing
- Added a new section about testing options and prerequisites
- Created a comprehensive test runner script (`scripts/Run-Tests.ps1`)

**How to Use:**
```powershell
# Run all tests
./scripts/Run-Tests.ps1

# Run specific tests
./scripts/Run-Tests.ps1 -SkipApiTests -SkipARMTests
```

## Local Environment Setup Issues

### Issue 1: Azure CLI and PowerShell Module Dependencies
**Problem:** Required Azure PowerShell modules and CLI extensions were not documented.

**Fix Implemented:**
- Added documentation about required dependencies
- Created scripts that can run with minimal dependencies
- Added validation checks to ensure required tools are available

**How to Use:**
See the updated README.md for detailed information about prerequisites and setup.

## Summary of Changes

1. **Updated Parameter Files**:
   - Changed from `.json` to `.bicepparam` format
   - Fixed path references
   - Updated company name from "Contoso" to "DXC"

2. **Enhanced Testing Framework**:
   - Added support for `.bicepparam` files in test scripts
   - Created a new API test runner
   - Implemented a comprehensive test runner script

3. **Improved Documentation**:
   - Updated README.md with detailed testing information
   - Added examples for running different types of tests
   - Documented prerequisites and dependencies

4. **Added Validation Scripts**:
   - Created simple validation scripts that don't require external dependencies
   - Added checks to ensure required tools are available

These changes ensure that the testing framework works correctly with the current codebase and provides a clear path for running different types of tests.
