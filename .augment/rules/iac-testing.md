---
type: "always_apply"
description: "Testing and Validation for Bicep and Terraform"
---

# IaC Testing and Validation

## Zero Tolerance Policy (CRITICAL)
**ALL code MUST be error-free before deployment:**
- ❌ NO errors allowed
- ❌ NO warnings from validation tools
- ❌ NO exceptions

## Mandatory Validation Steps

### Bicep Workflow
```bash
# 1. Build (MANDATORY)
az bicep build --file main.bicep

# 2. Lint (MANDATORY)
az bicep lint --file main.bicep

# 3. Validate (MANDATORY)
az deployment sub validate --template-file main.bicep --parameters main.bicepparam

# 4. What-If (MANDATORY)
az deployment sub what-if --template-file main.bicep --parameters main.bicepparam

# 5. Deploy
az deployment sub create --template-file main.bicep --parameters main.bicepparam
```

### Terraform Workflow
```bash
# 1. Format (MANDATORY)
terraform fmt -recursive

# 2. Validate (MANDATORY)
terraform validate

# 3. Plan (MANDATORY)
terraform plan -var-file="dev.tfvars" -out=tfplan

# 4. Apply
terraform apply tfplan
```

## Pre-Commit Hooks (MANDATORY)

### Setup (Required Once Per Repository)
```bash
# Install pre-commit hooks
pre-commit install

# Run hooks manually on all files
pre-commit run --all-files
```

### Usage
Pre-commit hooks automatically run before each commit to enforce:
- Code formatting (terraform fmt, bicep build)
- Linting (yamllint, shellcheck)
- Security scanning (gitleaks)
- Validation checks

**If hooks fail, commit is blocked until issues are fixed.**

## YAML Validation (MANDATORY)

```bash
# Validate all YAML files
yamllint .

# Validate specific files
yamllint azure-pipelines.yml
yamllint .github/workflows/*.yml
yamllint k8s/*.yaml

# Fix common issues
yamllint --format parsable . | grep -v "line too long"
```

**When to run:**
- Before committing pipeline changes
- Before deploying Kubernetes manifests
- As part of pre-commit hooks

## Shell Script Validation (MANDATORY)

```bash
# Validate shell scripts
shellcheck scripts/*.sh
shellcheck .devcontainer/scripts/*.sh

# Validate with specific shell
shellcheck --shell=bash script.sh

# Ignore specific warnings
shellcheck --exclude=SC2086 script.sh
```

**When to run:**
- Before committing shell scripts
- Before using scripts in pipelines
- As part of pre-commit hooks

## Kubernetes Manifest Validation (When Using AKS)

```bash
# Validate Kubernetes manifests
kubectl apply --dry-run=client -f manifest.yaml
kubectl apply --dry-run=server -f manifest.yaml
kubectl diff -f manifest.yaml

# Validate Helm charts
helm lint charts/my-app
helm template charts/my-app | kubectl apply --dry-run=client -f -

# Security scan Kubernetes configs
trivy config k8s/
checkov -d k8s/
```

**When to run:**
- Before deploying to AKS
- Before committing Kubernetes manifests
- As part of CI/CD pipeline

## Security Scanning (MANDATORY)

### Secret Detection
```bash
# Scan for secrets (MANDATORY before every commit)
gitleaks detect --source . --verbose

# Scan staged files only
gitleaks protect --verbose --staged

# Scan specific directory
gitleaks detect --source ./bicep --verbose
```

### IaC Security Scanning

**Bicep:**
```bash
# ARM-TTK
Test-AzTemplate -TemplatePath ./bicep

# PSRule
Assert-PSRule -Module PSRule.Rules.Azure -InputPath ./bicep

# Trivy
trivy config ./bicep

# Checkov
checkov -d ./bicep
```

**Terraform:**
```bash
# Trivy (includes tfsec functionality)
trivy config .

# Checkov
checkov -d .
```

**Kubernetes:**
```bash
# Trivy
trivy config k8s/

# Checkov
checkov -d k8s/
```

**When to run:**
- Before EVERY commit (via pre-commit hooks)
- Before creating pull requests
- As part of CI/CD pipeline
- During code reviews

## Systematic Task-Based Workflow (MANDATORY)

### Task Integration with Testing
**EVERY code task MUST have corresponding test task:**

Example Task List:
1. Create storage module
2. Add validation rules
3. **Run format/lint (TEST)**
4. **Run validate (TEST)**
5. Add security settings
6. **Run format/lint (TEST)**
7. **Run validate (TEST)**
8. Create dev config
9. **Run plan/what-if (TEST)**
10. **Review output (TEST)**
11. Deploy to dev
12. **Verify deployment (TEST)**

### Development Workflow (MANDATORY SEQUENCE)

```
1. Write/Modify Code
   → Mark task IN_PROGRESS
   ↓
2. Format Code
   → Bicep: az bicep build
   → Terraform: terraform fmt
   → Mark task COMPLETE
   ↓
3. Validate Code
   → Bicep: az bicep lint + validate
   → Terraform: terraform validate
   → Fix ALL errors
   → Mark task COMPLETE
   ↓
4. Plan Deployment
   → Bicep: what-if
   → Terraform: plan
   → Review ALL changes
   → Mark task COMPLETE
   ↓
5. Security Scan
   → Run security tools
   → Fix ALL issues
   → Mark task COMPLETE
   ↓
6. Deploy
   → Execute deployment
   → Mark task COMPLETE
   ↓
7. Verify
   → Check resources
   → Validate configuration
   → Mark task COMPLETE
```

### Quality Gates (Definition of Done)
Code is "done" ONLY when:
- ✅ Format/lint passes (zero errors)
- ✅ Validate succeeds (zero errors)
- ✅ Plan/what-if reviewed
- ✅ Security scan passes
- ✅ Tested in dev/test
- ✅ Resources verified
- ✅ Documentation updated

### Task-Based Testing Enforcement
- EVERY testing step = separate task
- Mark IN_PROGRESS before starting
- Mark COMPLETE only after passing
- NO skipping tasks
- NO batching tasks
- Testing tasks NON-NEGOTIABLE

## Common Issues and Solutions

### Bicep
**Issue**: Build fails with syntax errors
**Solution**: Check parameter types, missing decorators, invalid expressions

**Issue**: What-if shows unexpected changes
**Solution**: Review parameter values, check existing resource state

### Terraform
**Issue**: Validate fails
**Solution**: Check variable types, provider configuration, resource dependencies

**Issue**: Plan shows destroy/recreate
**Solution**: Review lifecycle blocks, check for breaking changes

## Enforcement
- Task-based workflow MANDATORY
- All validation steps must be tasks
- No deployments without testing task completion
