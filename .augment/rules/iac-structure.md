---
type: "always_apply"
description: "IaC File Structure and Documentation Standards for Bicep and Terraform"
---

# IaC File Structure and Documentation

## File Header Block (MANDATORY)

### Bicep
Every Bicep module MUST begin with this header:

```bicep
// ============================================================================
// MODULE TITLE IN UPPERCASE
// ============================================================================
// Description of what the module deploys and key features
//
// Dependencies: List required resources
// Deployment Scope: Resource Group | Subscription | Management Group | Tenant
// ============================================================================

metadata name = 'Module Display Name'
metadata description = 'Concise module description'
metadata owner = 'Team Name'
```

### Terraform
Every Terraform module SHOULD include a header comment in main.tf:

```hcl
# ============================================================================
# MODULE TITLE IN UPPERCASE
# ============================================================================
# Description of what the module deploys and key features
#
# Dependencies: List required resources
# ============================================================================
```

### Header Requirements
- Divider: 78 equals signs (`=`) or hashes (`#`)
- Title: Uppercase, descriptive
- Description: Multi-line, key features
- Dependencies: List or "None"
- Bicep: Include metadata block
- Terraform: Header comment optional but recommended

## Section Organization (MANDATORY)

### Bicep File Organization
All Bicep files MUST organize content in this order:
1. **PARAMETERS** - All input parameters
2. **VARIABLES** - All variables (if any)
3. **RESOURCES** - All resource deployments
4. **OUTPUTS** - All output values

**Section Header Format:**
```bicep
// ============================================================================
// SECTION NAME IN UPPERCASE
// ============================================================================
```

**Example:**
```bicep
// ============================================================================
// PARAMETERS
// ============================================================================

@description('Required. The name of the resource.')
@minLength(3)
@maxLength(64)
param resourceName string

// ============================================================================
// RESOURCES
// ============================================================================

// Resource description explaining purpose
resource example 'Microsoft.Provider/type@2024-01-01' = {
  name: resourceName
  location: location
}

// ============================================================================
// OUTPUTS
// ============================================================================

@description('The resource ID of the deployed resource.')
output resourceId string = example.id
```

### Terraform File Organization
Terraform modules MUST organize content across standard files:
- **variables.tf** - All input variable declarations
- **main.tf** - All resource definitions
- **outputs.tf** - All output value declarations
- **versions.tf** - Provider version constraints

**Example main.tf:**
```hcl
# Resource description explaining purpose
resource "azurerm_resource_group" "example" {
  name     = var.resource_group_name
  location = var.location
}
```

## Inline Comment Requirements

### Resource Comments
- **Placement**: Immediately before each resource declaration
- **Format**: Single or multi-line comment explaining purpose
- **Content**: What resource does, why configured this way, security considerations

### Examples

**Bicep:**
```bicep
// Single-line resource comment
// AVD Host Pool resource with configurable settings
resource hostPool 'Microsoft.DesktopVirtualization/hostPools@2024-08-01' = {

// Multi-line resource comment
// AVD DSC extension for registering session hosts
// Uses Microsoft's official DSC configuration
// Supports Azure AD join and domain join scenarios
resource avdExtension 'Microsoft.Compute/virtualMachines/extensions@2023-09-01' = [
```

**Terraform:**
```hcl
# Single-line resource comment
# Resource group for application resources
resource "azurerm_resource_group" "example" {

# Multi-line resource comment
# Storage account for application data
# Configured with private endpoints and encryption
# Supports blob, file, and table storage
resource "azurerm_storage_account" "example" {
```

## Parameter/Variable Documentation Requirements

### Bicep
Every parameter MUST have:
- `@description()` - Clear explanation
- Validation decorators: `@minLength()`, `@maxLength()`, `@allowed()`, `@secure()`

```bicep
@description('Required. The name of the resource.')
@minLength(3)
@maxLength(64)
param resourceName string

@description('Required. Administrator password.')
@secure()
param adminPassword string
```

### Terraform
Every variable MUST have:
- `description` - Clear explanation
- `type` - Variable type
- `validation` - Validation rules (where applicable)
- `sensitive` - For sensitive values

```hcl
variable "resource_name" {
  description = "Required. The name of the resource."
  type        = string
  validation {
    condition     = length(var.resource_name) >= 3 && length(var.resource_name) <= 64
    error_message = "Must be 3-64 characters."
  }
}

variable "admin_password" {
  description = "Required. Administrator password."
  type        = string
  sensitive   = true
}
```

## Output Documentation Requirements

### Bicep
Every output MUST have:
- `@description()` - Clear explanation
- `@secure()` - For sensitive outputs

```bicep
@description('The resource ID.')
output resourceId string = example.id

@description('The access key.')
@secure()
output accessKey string = example.listKeys().keys[0].value
```

### Terraform
Every output MUST have:
- `description` - Clear explanation
- `sensitive` - For sensitive outputs

```hcl
output "resource_id" {
  description = "The resource ID."
  value       = azurerm_resource_group.example.id
}

output "access_key" {
  description = "The access key."
  value       = azurerm_storage_account.example.primary_access_key
  sensitive   = true
}
```

## Enforcement
- Apply to ALL new and modified IaC files
- Bicep: All files must pass `az bicep lint`
- Terraform: All files must pass `terraform fmt` and `terraform validate`
- Verify during code reviews

## Systematic Task-Based Development Workflow (MANDATORY)

### Task Management for IaC Development
ALL IaC development MUST follow systematic task-based workflow:

#### Pre-Development Phase
1. **Create Granular Tasks**:
   - Break down module development into small, testable tasks
   - Each task focuses on single aspect (parameters, resources, outputs, testing)
   - Document task dependencies and sequence
   - Estimate time (target: 30-60 min per task)

2. **Example Task Breakdown for New Module**:
   - Task 1: Create module file with header block and metadata
   - Task 2: Define and document all parameters with decorators
   - Task 3: Create variables section with naming logic
   - Task 4: Implement primary resource deployment
   - Task 5: Add diagnostic settings integration
   - Task 6: Implement outputs with descriptions
   - Task 7: Run lint and fix all warnings/errors
   - Task 8: Run build and validate
   - Task 9: Create parameter file for dev environment
   - Task 10: Test deployment with what-if
   - Task 11: Deploy to dev and verify
   - Task 12: Update module documentation

#### Development Phase
1. **Work Systematically**:
   - Mark current task as IN_PROGRESS before starting
   - Focus on ONE task at a time
   - Follow file structure standards for current task
   - Apply documentation standards as you code
   - Do NOT skip ahead to other tasks

2. **Testing Each Task**:
   - Bicep: Run `az bicep lint` after each code change
   - Terraform: Run `terraform fmt` and `terraform validate` after each code change
   - Fix ALL errors and warnings immediately
   - Verify file structure compliance
   - Check documentation completeness
   - Test parameter/variable validation

3. **Task Completion**:
   - Verify all acceptance criteria met
   - Run full validation (lint, build, validate)
   - Mark task as COMPLETE only after verification
   - Document any issues or deviations
   - Move to next task ONLY after current task is complete

#### Quality Gates Per Task
Each task must pass these checks before marking COMPLETE:
- ✅ Code follows file structure standards
- ✅ All sections have proper header dividers (78 equals signs or hashes)
- ✅ Parameters/variables have description decorators
- ✅ Resources have explanatory comments
- ✅ Outputs have description decorators
- ✅ Format/lint returns zero errors and warnings
- ✅ File structure matches template requirements

#### Enforcement
- Task-based workflow is MANDATORY for all IaC development
- Code reviews will verify task management was used
- Pull requests must include task completion checklist
- No module deployments without documented task progression

## Related Standards

- See `iac-general.md` for general IaC best practices
- See `azure-naming.md` for resource naming conventions
- See `bicep-avm.md` for Azure Verified Modules usage
- See `iac-configuration.md` for configuration-driven development
- See `iac-testing.md` for testing and validation requirements
