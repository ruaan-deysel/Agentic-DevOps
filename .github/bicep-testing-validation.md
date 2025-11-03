---
type: "agent_requested"
description: "Example description"
---

# Bicep Testing, Validation, and Quality Assurance

## Zero Tolerance Policy
**CRITICAL**: All Bicep code MUST be completely free of errors and warnings before deployment.
- ❌ NO errors allowed
- ❌ NO warnings allowed
- ❌ NO exceptions to this rule

## Mandatory Validation Steps

ALL Bicep code MUST pass these three validation steps before deployment:

### 1. Bicep Linting (MANDATORY)
Bicep linting MUST be run on all .bicep files and MUST return zero errors and zero warnings.

```bash
# Lint a single file
az bicep lint --file main.bicep

# Lint with strict mode (recommended)
az bicep lint --file main.bicep --diagnostics-format sarif

# Expected output: No errors, no warnings
```

**Requirements**:
- Run linting on EVERY .bicep file
- Fix ALL warnings (not just errors)
- Linting must pass before committing code
- Configure your IDE to show lint warnings in real-time

### 2. Bicep Validation (MANDATORY)
Bicep validation MUST be run to verify template syntax and structure.

```bash
# Validate subscription-level deployment
az deployment sub validate \
  --location eastus \
  --template-file bicep/environments/dev/main.bicep \
  --parameters bicep/parameters/dev/main.dev.bicepparam

# Validate resource group deployment
az deployment group validate \
  --resource-group rg-name \
  --template-file module.bicep \
  --parameters params.bicepparam

# Expected output: "provisioningState": "Succeeded"
```

**Requirements**:
- Validation must succeed without errors
- Run validation for EVERY environment
- Validate before running what-if
- Any validation errors must be fixed immediately

### 3. What-If Deployment (MANDATORY)
What-if deployments MUST be run before ANY actual deployment to preview changes.

```bash
# What-if for subscription deployment
az deployment sub what-if \
  --location eastus \
  --template-file bicep/environments/dev/main.bicep \
  --parameters bicep/parameters/dev/main.dev.bicepparam

# What-if for resource group deployment
az deployment group what-if \
  --resource-group rg-name \
  --template-file module.bicep \
  --parameters params.bicepparam

# What-if with result format (easier to read)
az deployment sub what-if \
  --location eastus \
  --template-file bicep/environments/dev/main.bicep \
  --parameters bicep/parameters/dev/main.dev.bicepparam \
  --result-format FullResourcePayloads
```

**Requirements**:
- ALWAYS run what-if before actual deployment
- Review what-if output for unexpected changes
- Document any destructive changes (deletes, recreates)
- Get approval for production what-if results before deployment
- No deployment without successful what-if completion

## Development Workflow (MANDATORY SEQUENCE)

Every code change MUST follow this exact sequence:

```
1. Write/Modify Bicep Code
   ↓
2. Run Bicep Lint
   → Fix ALL warnings and errors
   → Repeat until clean
   ↓
3. Run Bicep Build
   → Verify successful compilation
   ↓
4. Run Bicep Validate
   → Fix any validation errors
   → Repeat until validated
   ↓
5. Run What-If Deployment
   → Review all changes
   → Verify expected behavior
   ↓
6. Get Approval (for prod)
   ↓
7. Deploy to Environment
   ↓
8. Verify Deployment Success
   ↓
9. Run Post-Deployment Tests
```

## Bicep Build Command

Always build Bicep files to verify they compile correctly:

```bash
# Build single file
az bicep build --file main.bicep

# Build with output to specific location
az bicep build --file main.bicep --outfile ./output/main.json

# Build parameter file
az bicep build-params --file params.bicepparam

# Build all files in directory
az bicep build --file main.bicep --no-restore
```

## Linting Configuration

### bicepconfig.json Setup
Create a `bicepconfig.json` file in your project root to configure linting rules:

```json
{
  "analyzers": {
    "core": {
      "enabled": true,
      "verbose": true,
      "rules": {
        "no-hardcoded-env-urls": {
          "level": "error"
        },
        "no-unused-params": {
          "level": "error"
        },
        "no-unused-vars": {
          "level": "error"
        },
        "prefer-interpolation": {
          "level": "error"
        },
        "secure-parameter-default": {
          "level": "error"
        },
        "simplify-interpolation": {
          "level": "error"
        },
        "protect-commandtoexecute-secrets": {
          "level": "error"
        },
        "use-stable-vm-image": {
          "level": "error"
        },
        "explicit-values-for-loc-params": {
          "level": "error"
        },
        "no-hardcoded-location": {
          "level": "error"
        },
        "no-unnecessary-dependson": {
          "level": "error"
        },
        "no-loc-expr-outside-params": {
          "level": "error"
        },
        "admin-username-should-not-be-literal": {
          "level": "error"
        },
        "use-resource-id-functions": {
          "level": "error"
        },
        "use-parent-property": {
          "level": "error"
        },
        "decompiler-cleanup": {
          "level": "warning"
        }
      }
    }
  }
}
```

### Linting Rules Enforcement

**CRITICAL RULES** (Must be set to "error" level):
- `no-hardcoded-env-urls` - No hardcoded environment URLs
- `no-unused-params` - All parameters must be used
- `no-unused-vars` - All variables must be used
- `prefer-interpolation` - Use string interpolation over concat()
- `secure-parameter-default` - Secure parameters cannot have defaults
- `no-hardcoded-location` - Location must be parameterized
- `admin-username-should-not-be-literal` - No hardcoded admin usernames

**ALL** linting rules must pass. There are no acceptable warnings.

## IDE Integration (MANDATORY)

### VS Code Setup
Install and configure the Bicep extension:

1. **Install Bicep Extension**:
   - Extension ID: `ms-azuretools.vscode-bicep`
   - Latest version required

2. **Configure Settings** (`.vscode/settings.json`):
```json
{
  "bicep.lint.enabled": true,
  "bicep.validate.enabled": true,
  "editor.formatOnSave": true,
  "bicep.experimental.enableSymbolReferences": true,
  "bicep.enableOutputTimestamps": true
}
```

3. **Enable Real-time Validation**:
   - Problems panel must show zero errors and warnings
   - Fix issues as you code, not after

### Required VS Code Extensions
- Bicep (`ms-azuretools.vscode-bicep`)
- Azure Resource Manager (ARM) Tools
- Azure CLI Tools

## Pre-Commit Validation Script

Create a pre-commit validation script to enforce quality:

### validate-bicep.ps1
```powershell
<#
.SYNOPSIS
    Validates all Bicep files in the project
.DESCRIPTION
    Runs lint, build, and validation on all Bicep files
    Fails if any errors or warnings are found
#>

param(
    [string]$Path = "./bicep"
)

$ErrorActionPreference = "Stop"
$errors = 0
$warnings = 0

Write-Host "Starting Bicep validation..." -ForegroundColor Cyan

# Find all .bicep files
$bicepFiles = Get-ChildItem -Path $Path -Filter "*.bicep" -Recurse

foreach ($file in $bicepFiles) {
    Write-Host "`nValidating: $($file.FullName)" -ForegroundColor Yellow
    
    # Run lint
    Write-Host "  → Running lint..." -NoNewline
    $lintResult = az bicep lint --file $file.FullName 2>&1
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host " FAILED" -ForegroundColor Red
        Write-Host $lintResult
        $errors++
    } else {
        # Check for warnings in output
        if ($lintResult -match "warning") {
            Write-Host " WARNINGS FOUND" -ForegroundColor Yellow
            Write-Host $lintResult
            $warnings++
        } else {
            Write-Host " PASSED" -ForegroundColor Green
        }
    }
    
    # Run build
    Write-Host "  → Running build..." -NoNewline
    $buildResult = az bicep build --file $file.FullName 2>&1
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host " FAILED" -ForegroundColor Red
        Write-Host $buildResult
        $errors++
    } else {
        Write-Host " PASSED" -ForegroundColor Green
    }
}

# Summary
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Validation Summary" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Files checked: $($bicepFiles.Count)"
Write-Host "Errors: $errors" -ForegroundColor $(if ($errors -eq 0) { "Green" } else { "Red" })
Write-Host "Warnings: $warnings" -ForegroundColor $(if ($warnings -eq 0) { "Green" } else { "Yellow" })

if ($errors -gt 0) {
    Write-Host "`n❌ VALIDATION FAILED - Errors found" -ForegroundColor Red
    exit 1
}

if ($warnings -gt 0) {
    Write-Host "`n⚠️  VALIDATION FAILED - Warnings found" -ForegroundColor Yellow
    Write-Host "ALL warnings must be fixed before deployment" -ForegroundColor Yellow
    exit 1
}

Write-Host "`n✅ VALIDATION PASSED - No errors or warnings" -ForegroundColor Green
exit 0
```

### validate-bicep.sh
```bash
#!/bin/bash

# Validates all Bicep files in the project
# Fails if any errors or warnings are found

set -e

PATH="${1:-./bicep}"
errors=0
warnings=0

echo "Starting Bicep validation..."

# Find all .bicep files
while IFS= read -r -d '' file; do
    echo ""
    echo "Validating: $file"
    
    # Run lint
    echo -n "  → Running lint... "
    if output=$(az bicep lint --file "$file" 2>&1); then
        if echo "$output" | grep -q "warning"; then
            echo "WARNINGS FOUND"
            echo "$output"
            ((warnings++))
        else
            echo "PASSED"
        fi
    else
        echo "FAILED"
        echo "$output"
        ((errors++))
    fi
    
    # Run build
    echo -n "  → Running build... "
    if az bicep build --file "$file" 2>&1; then
        echo "PASSED"
    else
        echo "FAILED"
        ((errors++))
    fi
done < <(find "$PATH" -name "*.bicep" -print0)

# Summary
echo ""
echo "========================================"
echo "Validation Summary"
echo "========================================"
echo "Errors: $errors"
echo "Warnings: $warnings"

if [ $errors -gt 0 ]; then
    echo ""
    echo "❌ VALIDATION FAILED - Errors found"
    exit 1
fi

if [ $warnings -gt 0 ]; then
    echo ""
    echo "⚠️  VALIDATION FAILED - Warnings found"
    echo "ALL warnings must be fixed before deployment"
    exit 1
fi

echo ""
echo "✅ VALIDATION PASSED - No errors or warnings"
exit 0
```

## CI/CD Pipeline Integration

### Azure DevOps Pipeline Example
```yaml
stages:
  - stage: Validate
    displayName: 'Validate Bicep Code'
    jobs:
      - job: BicepValidation
        displayName: 'Lint, Build, and Validate'
        steps:
          - task: AzureCLI@2
            displayName: 'Install Bicep CLI'
            inputs:
              azureSubscription: 'your-service-connection'
              scriptType: 'bash'
              scriptLocation: 'inlineScript'
              inlineScript: |
                az bicep install
          
          - task: PowerShell@2
            displayName: 'Lint All Bicep Files'
            inputs:
              filePath: 'scripts/validate-bicep.ps1'
              failOnStderr: true
          
          - task: AzureCLI@2
            displayName: 'Validate Dev Deployment'
            inputs:
              azureSubscription: 'your-service-connection'
              scriptType: 'bash'
              scriptLocation: 'inlineScript'
              inlineScript: |
                az deployment sub validate \
                  --location eastus \
                  --template-file bicep/environments/dev/main.bicep \
                  --parameters bicep/parameters/dev/main.dev.bicepparam
          
          - task: AzureCLI@2
            displayName: 'What-If Dev Deployment'
            inputs:
              azureSubscription: 'your-service-connection'
              scriptType: 'bash'
              scriptLocation: 'inlineScript'
              inlineScript: |
                az deployment sub what-if \
                  --location eastus \
                  --template-file bicep/environments/dev/main.bicep \
                  --parameters bicep/parameters/dev/main.dev.bicepparam \
                  --result-format FullResourcePayloads
```

### GitHub Actions Example
```yaml
name: Bicep Validation

on:
  pull_request:
    branches: [ main, develop ]
  push:
    branches: [ main, develop ]

jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Install Bicep CLI
        run: |
          az bicep install
      
      - name: Lint Bicep Files
        run: |
          chmod +x scripts/validate-bicep.sh
          ./scripts/validate-bicep.sh
      
      - name: Azure Login
        uses: azure/login@v1
        with:
          creds: ${{ secrets.AZURE_CREDENTIALS }}
      
      - name: Validate Deployment
        run: |
          az deployment sub validate \
            --location eastus \
            --template-file bicep/environments/dev/main.bicep \
            --parameters bicep/parameters/dev/main.dev.bicepparam
      
      - name: What-If Deployment
        run: |
          az deployment sub what-if \
            --location eastus \
            --template-file bicep/environments/dev/main.bicep \
            --parameters bicep/parameters/dev/main.dev.bicepparam
```

## Common Linting Errors and Fixes

### Error: no-unused-params
```bicep
// ❌ BAD - Parameter defined but not used
param unusedParam string

resource example 'Microsoft.Storage/storageAccounts@2021-09-01' = {
  name: 'mystorageaccount'
}

// ✅ GOOD - Remove unused parameter or use it
resource example 'Microsoft.Storage/storageAccounts@2021-09-01' = {
  name: unusedParam
}
```

### Error: no-hardcoded-location
```bicep
// ❌ BAD - Hardcoded location
resource example 'Microsoft.Storage/storageAccounts@2021-09-01' = {
  name: 'mystorageaccount'
  location: 'eastus'
}

// ✅ GOOD - Parameterized location
param location string = resourceGroup().location

resource example 'Microsoft.Storage/storageAccounts@2021-09-01' = {
  name: 'mystorageaccount'
  location: location
}
```

### Error: prefer-interpolation
```bicep
// ❌ BAD - Using concat()
var name = concat('storage', uniqueString(resourceGroup().id))

// ✅ GOOD - Using string interpolation
var name = 'storage${uniqueString(resourceGroup().id)}'
```

### Error: no-unnecessary-dependson
```bicep
// ❌ BAD - Unnecessary explicit dependency
resource storage 'Microsoft.Storage/storageAccounts@2021-09-01' = {
  name: 'mystorageaccount'
  location: location
}

resource container 'Microsoft.Storage/storageAccounts/blobServices/containers@2021-09-01' = {
  name: '${storage.name}/default/mycontainer'
  dependsOn: [
    storage  // Unnecessary - implicit dependency exists
  ]
}

// ✅ GOOD - Implicit dependency through reference
resource container 'Microsoft.Storage/storageAccounts/blobServices/containers@2021-09-01' = {
  parent: blobService
  name: 'mycontainer'
}
```

## Quality Gates

### Definition of Done for Bicep Code

Code is considered "done" ONLY when:
- ✅ Bicep lint returns zero errors and zero warnings
- ✅ Bicep build completes successfully
- ✅ Bicep validate succeeds for target environment
- ✅ What-if deployment has been reviewed and approved
- ✅ All parameters documented with @description
- ✅ All resources follow naming conventions
- ✅ Code reviewed by at least one other developer
- ✅ Changes documented in commit message
- ✅ README updated if necessary

### Pull Request Requirements

Every PR must include:
1. ✅ Successful lint results (screenshot or logs)
2. ✅ Successful validation results
3. ✅ What-if output for all affected environments
4. ✅ Explanation of any resource deletions or recreations
5. ✅ Approval from code owner

## Testing Checklist

Before any deployment, complete this checklist:

```
□ Run bicep lint on all files - PASSED with 0 errors, 0 warnings
□ Run bicep build on all files - PASSED
□ Run bicep build-params on all parameter files - PASSED
□ Run validate deployment - PASSED
□ Run what-if deployment - REVIEWED
□ Review what-if for unexpected changes - VERIFIED
□ All parameters documented - VERIFIED
□ All variables used - VERIFIED
□ Naming conventions followed - VERIFIED
□ AVM modules used where possible - VERIFIED
□ Code reviewed - APPROVED
□ Documentation updated - COMPLETED
```

## Enforcement

These validation requirements are **NON-NEGOTIABLE**:
- No code commits without passing lint
- No PR merges without clean validation
- No deployments without successful what-if
- No exceptions for "quick fixes"
- No warnings are acceptable

## Automated Enforcement Tools

### Pre-commit Hook
Create `.git/hooks/pre-commit`:
```bash
#!/bin/bash
echo "Running Bicep validation..."
./scripts/validate-bicep.sh
if [ $? -ne 0 ]; then
    echo "❌ Commit rejected - Fix validation errors first"
    exit 1
fi
```

### Git Branch Protection
Configure branch protection rules to require:
- Successful CI/CD validation pipeline
- Code review approval
- Zero failing checks

## Troubleshooting

### Issue: Linting takes too long
**Solution**: Lint only changed files
```bash
git diff --name-only --cached | grep ".bicep$" | xargs -I {} az bicep lint --file {}
```

### Issue: What-if shows unexpected changes
**Solution**: 
1. Review changes carefully
2. Check if resources were manually modified outside IaC
3. Verify parameter values are correct
4. Use `--result-format FullResourcePayloads` for details

### Issue: Validation fails but lint passes
**Solution**: Check Azure permissions and subscription state
```bash
# Verify subscription and permissions
az account show
az deployment sub validate --help
```

## Continuous Improvement

- Review linting rules quarterly
- Update bicepconfig.json with new best practices
- Document recurring validation issues
- Train team on common mistakes
- Automate as much validation as possible