---
type: "always_apply"
description: "Security Best Practices for Bicep and Terraform"
---

# IaC Security Best Practices

## Security Principles
- Never hardcode secrets in code
- Use Azure Key Vault for secret management
- Implement least privilege access
- Enable encryption at rest and in transit
- Use Managed Identities where possible
- Scan code for security vulnerabilities

## Secret Management

### NEVER Do This
```
# ❌ WRONG - Hardcoded secrets
param adminPassword = 'MyPassword123!'
variable "admin_password" { default = "MyPassword123!" }
```

### Correct Approaches

**Bicep:**
```bicep
@secure()
param adminPassword string

// Or use Key Vault reference
param adminPassword = getSecret('sub-id', 'rg', 'kv', 'secret-name')
```

**Terraform:**
```hcl
variable "admin_password" {
  type      = string
  sensitive = true
}

# Or use Key Vault data source
data "azurerm_key_vault_secret" "admin_password" {
  name         = "admin-password"
  key_vault_id = data.azurerm_key_vault.example.id
}
```

## Resource Security Defaults

### Storage Account
**Bicep:**
```bicep
resource storage 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: storageAccountName
  properties: {
    allowBlobPublicAccess: false
    minimumTlsVersion: 'TLS1_2'
    supportsHttpsTrafficOnly: true
    networkAcls: {
      defaultAction: 'Deny'
      bypass: 'AzureServices'
    }
  }
}
```

**Terraform:**
```hcl
resource "azurerm_storage_account" "example" {
  allow_nested_items_to_be_public = false
  min_tls_version                 = "TLS1_2"
  enable_https_traffic_only       = true
  network_rules {
    default_action = "Deny"
    bypass         = ["AzureServices"]
  }
}
```

### Key Vault
**Bicep:**
```bicep
resource kv 'Microsoft.KeyVault/vaults@2023-07-01' = {
  properties: {
    enableRbacAuthorization: true
    enablePurgeProtection: true
    softDeleteRetentionInDays: 90
    networkAcls: {
      defaultAction: 'Deny'
      bypass: 'AzureServices'
    }
  }
}
```

**Terraform:**
```hcl
resource "azurerm_key_vault" "example" {
  enable_rbac_authorization  = true
  purge_protection_enabled   = true
  soft_delete_retention_days = 90
  network_acls {
    default_action = "Deny"
    bypass         = "AzureServices"
  }
}
```

## Network Security
- Default deny for network access
- Use Private Endpoints for PaaS services
- Implement Network Security Groups
- Use Azure Firewall for egress filtering

## Authentication
- Use Managed Identity for Azure authentication
- Avoid Service Principal credentials in code
- Use Azure CLI auth for local development
- Implement RBAC for resource access

## Security Scanning

### Bicep Tools
```bash
# ARM-TTK
Test-AzTemplate -TemplatePath ./bicep

# PSRule
Assert-PSRule -Module PSRule.Rules.Azure -InputPath ./bicep
```

### Terraform Tools
```bash
# tfsec
tfsec .

# Checkov
checkov -d .
```

## Systematic Task-Based Workflow (MANDATORY)

### Security Implementation Tasks
1. **Planning:**
   - Identify all sensitive data
   - Plan Key Vault integration
   - Document security requirements

2. **Example Breakdown:**
   - Task 1: Mark all sensitive parameters/variables
   - Task 2: Configure Key Vault data sources
   - Task 3: Implement network security rules
   - Task 4: Enable encryption settings
   - Task 5: Configure RBAC permissions
   - Task 6: Run security scan
   - Task 7: Fix ALL security issues
   - Task 8: Document security controls

### Implementation
- Mark task IN_PROGRESS
- Implement ONE security control at a time
- Test security configuration
- Mark COMPLETE after verification

### Quality Gates
- ✅ No hardcoded secrets
- ✅ All sensitive parameters marked
- ✅ Key Vault integration configured
- ✅ Network security rules applied
- ✅ Encryption enabled
- ✅ Security scans pass (zero high/critical)
- ✅ RBAC configured

### Enforcement
- Task-based workflow MANDATORY
- Security scanning must be in task list
- No deployments without security scan tasks completed

