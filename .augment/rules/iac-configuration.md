---
type: "always_apply"
description: "Configuration-Driven Development for Bicep and Terraform"
---

# Configuration-Driven Development

## Principles (MANDATORY)
- ALL deployments MUST be configuration-driven
- NO hardcoded values in code files
- Use parameter/variable files as primary configuration
- Separate configuration from infrastructure code

## Folder Structure

### Bicep
```
bicep/
├── modules/           # Reusable modules
├── parameters/        # .bicepparam files
└── environments/      # Environment-specific deployments
    ├── dev/
    ├── test/
    └── prod/
```

### Terraform
```
terraform/
├── modules/           # Reusable modules
├── environments/      # Environment-specific configs
│   ├── dev/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── terraform.tfvars
│   ├── test/
│   └── prod/
└── global/           # Shared resources
```

## Configuration File Standards

### Bicep (.bicepparam)
```bicep
using '../environments/dev/main.bicep'

param location = 'eastus'
param environment = 'dev'
param tags = {
  Environment: 'Development'
  ManagedBy: 'Bicep'
}
```

### Terraform (.tfvars)
```hcl
environment = "dev"
location    = "eastus"
tags = {
  Environment = "Development"
  ManagedBy   = "Terraform"
}
```

## Variable/Parameter Best Practices

### Bicep
```bicep
@description('Environment name')
@allowed(['dev', 'test', 'prod'])
param environment string

@description('Azure region')
param location string = 'eastus'

@description('Resource tags')
param tags object = {}
```

### Terraform
```hcl
variable "environment" {
  description = "Environment name"
  type        = string
  validation {
    condition     = contains(["dev", "test", "prod"], var.environment)
    error_message = "Must be dev, test, or prod."
  }
}

variable "location" {
  description = "Azure region"
  type        = string
  default     = "eastus"
}
```

## Sensitive Data Handling
- NEVER store secrets in parameter/variable files
- Use Azure Key Vault references
- Mark sensitive parameters (Bicep: @secure(), Terraform: sensitive = true)
- Use environment variables for credentials

### Bicep Key Vault Reference
```bicep
param adminPassword = getSecret('subscription-id', 'rg-name', 'kv-name', 'secret-name')
```

### Terraform Key Vault Reference
```hcl
data "azurerm_key_vault_secret" "admin_password" {
  name         = "admin-password"
  key_vault_id = data.azurerm_key_vault.example.id
}
```

## Systematic Task-Based Workflow (MANDATORY)

### Configuration Tasks
1. **Planning:**
   - Identify all configurable parameters
   - Determine environment-specific vs shared values
   - Plan validation requirements

2. **Example Breakdown:**
   - Task 1: Create environment directory structure
   - Task 2: Define parameters/variables with validation
   - Task 3: Create dev config file
   - Task 4: Test with validate
   - Task 5: Create test config file
   - Task 6: Create prod config file
   - Task 7: Document all parameters

### Implementation
- Mark task IN_PROGRESS
- Focus on ONE config file at a time
- Test immediately after creation
- Mark COMPLETE after validation

### Quality Gates
- ✅ No hardcoded values in code
- ✅ All config in parameter/variable files
- ✅ Validation rules applied
- ✅ Sensitive parameters marked
- ✅ Validation passes
- ✅ Documentation complete

### Enforcement
- Task-based workflow MANDATORY
- No deployments without validation tasks completed

