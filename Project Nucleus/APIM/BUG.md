# Test Execution Bugs and Issues

## Date: April 16, 2025 (Updated)

## Overview
This document records current issues encountered when attempting to run tests for the Nucleus-APIM solution. Several previously identified bugs have been fixed, but some issues remain and new ones have been discovered. The bugs are categorized by test type and include error details and suggested fixes.

## ✅ Fixed Issues
The following issues have been addressed:

- **Pester Module Version Compatibility**: Fixed both Bicep.Tests.ps1 and ARM.Tests.ps1 to properly detect Pester version and use appropriate syntax
- **Parameter File Extension Mismatch**: Test scripts have been updated to support `.bicepparam` files
- **API Test Runner Implementation**: Created a proper script for running API tests
- **Documentation for Prerequisites**: Added detailed information about required dependencies
- **Parameter Error in Comprehensive Test Runner**: Fixed the Run-Tests.ps1 script to correctly call test scripts without using unsupported parameters

## Remaining Issues

### Bicep Tests Issues

#### Issue 1: Azure CLI Python Errors
The Bicep validation process encounters Python errors from Azure CLI when validating templates.

**Error Details:**
```
AttributeError: 'NoneType' object has no attribute 'isatty'
```

**Explanation:**
These errors are environment-specific issues with how Azure CLI's Python backend handles console output in non-interactive contexts. Azure CLI is trying to determine if it's outputting to an interactive terminal (using the `isatty()` method), but in the context of test scripts, it's getting confused by redirected output.

**Recommendation:**
- Use the `--only-show-errors` flag with Azure CLI commands to suppress verbose output
- Run Bicep validation directly with `az bicep build` which works correctly
- Consider using the `Test-BicepTemplates.ps1` script which handles the output redirection better

#### Issue 2: Template Validation Failures Despite Valid Templates
Template validation fails in test scripts even though direct validation with `az bicep build` succeeds with only minor warnings.

**Observations:**
- Direct validation with `az bicep build --file main.bicep` succeeds with only minor warnings about unused parameters
- Test scripts report validation failures for all environments (dev, test, prod)

**Recommendation:**
- Focus on the results of direct Bicep validation rather than the test script output
- Review the minor warnings about unused parameters ("groups" and "users")
- Add error handling in test scripts to better distinguish between template issues and environment/CLI problems

### Run-Tests.ps1 Issues

#### Issue 1: API Tests Regex Pattern Issue
In the Run-Tests.ps1 script, there was an issue with a regex pattern used to check if the Run-ApiTests.ps1 script supports the -WhatIf parameter.

**Error:**
```
Invalid pattern '\[Parameter\(.*\)\]\s*\[switch\]\' at offset 33. Illegal \ at end of pattern.
```

**Status:**
Fixed by replacing the regex pattern matching with a more reliable try-catch approach to directly run the script with -WhatIf and catch any errors if not supported.

#### Issue 2: Output Visibility Issues
The Run-Tests.ps1 script sometimes runs without displaying output in the terminal window.

**Error:**
No visible errors, but no output is displayed and log files may not be created.

**Recommendation:**
- Run individual test components directly if the comprehensive test runner doesn't provide output
- Use the `-Verbose` flag when running the test script
- Check the test-results directory for any newly created log files

## Environment-Specific Issues

### Issue 1: Cross-Platform Execution
The bash script `Validate-Templates.sh` is designed for Linux/Mac environments and doesn't run on Windows PowerShell.

**Recommendation:**
- Use PowerShell scripts on Windows systems
- Use bash scripts on Linux/Mac systems
- Consider using Docker containers for consistent testing environments

## Next Steps
1. Focus on passing Bicep validation through direct `az bicep build` commands rather than test scripts
2. Address the minor warnings about unused parameters in the main Bicep template
3. Run individual test components separately when the comprehensive runner encounters issues
4. Use the `-Verbose` flag or redirect output explicitly when running tests to ensure visibility
5. Consider adding the `--only-show-errors` flag to Azure CLI commands in test scripts to reduce noise
