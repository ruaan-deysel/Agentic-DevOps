---
type: "always_apply"
description: "Azure Naming Conventions for Bicep and Terraform"
---

# Azure Naming Conventions

## Standard Naming Pattern
```
{resource-type}-{workload}-{environment}-{region}-{instance}
```

## Environment Abbreviations
- `dev` - Development
- `tst` - Test
- `stg` - Staging
- `prod` - Production

## Region Abbreviations
- `eus` - East US
- `wus` - West US
- `eus2` - East US 2
- `neu` - North Europe
- `weu` - West Europe

## Resource Type Prefixes

### Compute
- `vm` - Virtual Machine
- `vmss` - VM Scale Set
- `aks` - Azure Kubernetes Service
- `func` - Function App
- `app` - App Service

### Networking
- `vnet` - Virtual Network
- `snet` - Subnet
- `nsg` - Network Security Group
- `pip` - Public IP
- `lb` - Load Balancer
- `fw` - Azure Firewall

### Storage
- `st` - Storage Account (no hyphens, max 24 chars)
- `blob` - Blob Container
- `share` - File Share

### Databases
- `sql` - SQL Server
- `sqldb` - SQL Database
- `cosmos` - Cosmos DB
- `redis` - Redis Cache

### Security
- `kv` - Key Vault (globally unique)
- `rsv` - Recovery Services Vault

### Management
- `rg` - Resource Group
- `log` - Log Analytics
- `appi` - Application Insights

## Naming Examples

### Bicep
```bicep
var vmName = 'vm-webapp-prod-eus-001'
var vnetName = 'vnet-hub-prod-eus-001'
var storageAccountName = 'stwebappprodeus001'  // No hyphens
var keyVaultName = 'kv-webapp-prod-eus-001'
```

### Terraform
```hcl
locals {
  vm_name              = "vm-webapp-prod-eus-001"
  vnet_name            = "vnet-hub-prod-eus-001"
  storage_account_name = "stwebappprodeus001"  # No hyphens
  key_vault_name       = "kv-webapp-prod-eus-001"
}
```

## Globally Unique Resources
Must be globally unique across Azure:
- Storage accounts (`st*`)
- Key Vaults (`kv-*`)
- App Services (`app-*`)
- Container Registry (`acr*`)

Add unique identifiers:
```bicep
// Bicep
var uniqueSuffix = uniqueString(resourceGroup().id)
var storageAccountName = 'st${workloadName}${environment}${uniqueSuffix}'
```

```hcl
# Terraform
locals {
  unique_suffix        = substr(md5(azurerm_resource_group.example.id), 0, 8)
  storage_account_name = "st${var.workload}${var.environment}${local.unique_suffix}"
}
```

## Character Restrictions

### Storage Accounts
- 3-24 characters
- Lowercase letters and numbers only
- No hyphens

### Key Vault
- 3-24 characters
- Alphanumerics and hyphens
- Must start with letter
- Cannot end with hyphen

### Virtual Machines
- 1-15 characters (Windows)
- 1-64 characters (Linux)

## Instance Numbering
Use zero-padded three-digit numbers: `001`, `002`, `003`

## Tagging Standards
Apply to ALL resources:
```bicep
// Bicep
var standardTags = {
  Environment: environment
  ManagedBy: 'Bicep'
  Owner: ownerEmail
  CostCenter: costCenter
}
```

```hcl
# Terraform
locals {
  standard_tags = {
    Environment = var.environment
    ManagedBy   = "Terraform"
    Owner       = var.owner_email
    CostCenter  = var.cost_center
  }
}
```

## Validation

### Bicep
```bicep
@minLength(3)
@maxLength(24)
param keyVaultName string

@allowed(['dev', 'tst', 'stg', 'prod'])
param environment string
```

### Terraform
```hcl
variable "key_vault_name" {
  type = string
  validation {
    condition     = length(var.key_vault_name) >= 3 && length(var.key_vault_name) <= 24
    error_message = "Must be 3-24 characters."
  }
}

variable "environment" {
  type = string
  validation {
    condition     = contains(["dev", "tst", "stg", "prod"], var.environment)
    error_message = "Must be dev, tst, stg, or prod."
  }
}
```

## Systematic Task-Based Workflow (MANDATORY)

### Naming Tasks
1. **Planning:**
   - Review Azure naming conventions
   - Identify client-specific requirements
   - Plan unique naming for global resources

2. **Example Breakdown:**
   - Task 1: Define naming pattern variables/locals
   - Task 2: Implement environment validation
   - Task 3: Implement location validation
   - Task 4: Create naming functions
   - Task 5: Add validation rules
   - Task 6: Test with sample values
   - Task 7: Document naming conventions

### Quality Gates
- ✅ Follows pattern: {type}-{workload}-{env}-{region}-{instance}
- ✅ Environment uses allowed values
- ✅ Location uses allowed values
- ✅ Character restrictions enforced
- ✅ Global resources have unique suffix
- ✅ Validation rules applied

### Enforcement
- Task-based workflow MANDATORY
- No deployments without naming compliance verification

