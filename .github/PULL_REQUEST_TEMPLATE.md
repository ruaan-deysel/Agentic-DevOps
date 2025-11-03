# Pull Request

## Description
<!-- Provide a brief description of the changes in this PR -->

## Type of Change
<!-- Mark the relevant option with an 'x' -->
- [ ] New feature (non-breaking change which adds functionality)
- [ ] Bug fix (non-breaking change which fixes an issue)
- [ ] Breaking change (fix or feature that would cause existing functionality to not work as expected)
- [ ] Documentation update
- [ ] Infrastructure change (Bicep/Terraform)
- [ ] Configuration change

## Related Issues
<!-- Link to related issues using #issue_number -->
Closes #

## Task-Based Development Checklist
<!-- This section is MANDATORY for all infrastructure changes -->

### Task Management (REQUIRED)
- [ ] Created granular tasks before starting work
- [ ] Worked through tasks systematically one at a time
- [ ] Marked each task as IN_PROGRESS before starting
- [ ] Tested each task thoroughly after implementation
- [ ] Marked each task as COMPLETE only after verification
- [ ] All tasks documented and tracked

### Task List Reference
<!-- Provide link to task list or list completed tasks -->
**Completed Tasks:**
1. 
2. 
3. 

## Testing Checklist

### For Bicep Changes
- [ ] Ran `az bicep build` on all .bicep files (ZERO errors)
- [ ] Ran `az bicep lint` on all .bicep files (ZERO warnings)
- [ ] Ran `az deployment sub validate` or `az deployment group validate`
- [ ] Ran `az deployment sub what-if` or `az deployment group what-if`
- [ ] Reviewed what-if output for expected changes
- [ ] Tested deployment in dev/test environment
- [ ] Verified deployed resources match expectations
- [ ] No hardcoded values in .bicep files
- [ ] All configuration in .bicepparam files
- [ ] Used Azure Verified Modules (AVM) where available

### For Terraform Changes
- [ ] Ran `terraform fmt -recursive` (all files formatted)
- [ ] Ran `terraform validate` (ZERO errors)
- [ ] Ran `terraform plan` for all environments
- [ ] Reviewed plan output for expected changes
- [ ] Ran `tfsec .` security scan (ZERO high/critical issues)
- [ ] Ran `checkov -d .` compliance scan
- [ ] Tested deployment in dev/test environment
- [ ] Verified deployed resources match expectations
- [ ] No hardcoded values in .tf files
- [ ] All configuration in .tfvars files
- [ ] Remote state configured and tested

### General Testing
- [ ] All automated tests pass
- [ ] Manual testing completed
- [ ] No secrets or sensitive data in code
- [ ] Documentation updated

## Security Checklist
- [ ] No secrets or credentials in code
- [ ] Sensitive variables marked as sensitive
- [ ] Azure Key Vault used for secrets
- [ ] Network security rules configured
- [ ] Encryption enabled where applicable
- [ ] RBAC permissions configured correctly
- [ ] Security scanning completed (tfsec/Checkov)

## Documentation
- [ ] Code comments added/updated
- [ ] README updated (if applicable)
- [ ] Parameter/variable descriptions added
- [ ] Deployment instructions updated (if applicable)
- [ ] Architecture diagrams updated (if applicable)

## Deployment Plan
<!-- Describe the deployment approach -->
**Target Environment(s):**
- [ ] Development
- [ ] Test
- [ ] Production

**Deployment Steps:**
1. 
2. 
3. 

**Rollback Plan:**
<!-- Describe how to rollback if deployment fails -->

## Breaking Changes
<!-- List any breaking changes and migration steps -->
- None

## Additional Notes
<!-- Any additional information reviewers should know -->

---

## Reviewer Checklist
<!-- For reviewers to complete -->
- [ ] Task-based workflow was followed
- [ ] All testing tasks completed
- [ ] Code follows project standards
- [ ] Security best practices followed
- [ ] Documentation is adequate
- [ ] Changes are backwards compatible OR migration plan provided
- [ ] Deployment plan is clear and safe

