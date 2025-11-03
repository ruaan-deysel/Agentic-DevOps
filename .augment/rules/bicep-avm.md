---
type: "agent_requested"
description: "Example description"
---

# Azure Verified Modules (AVM) Usage

## AVM Principles
- ALWAYS use Azure Verified Modules (AVM) when available
- AVM provides tested, validated, and maintained Bicep modules
- Use both Resource Modules and Pattern Modules as appropriate
- Never recreate functionality that exists in AVM

## Module Types

### Resource Modules
- Use for individual Azure resources (VNets, Storage Accounts, Key Vaults, etc.)
- Located at: `br/public:avm/res/{resource-provider}/{resource-type}:{version}`
- Examples:
  - `br/public:avm/res/storage/storage-account:0.9.0`
  - `br/public:avm/res/network/virtual-network:0.1.0`
  - `br/public:avm/res/key-vault/vault:0.6.0`

### Pattern Modules
- Use for complete solutions and architectural patterns
- Located at: `br/public:avm/ptn/{pattern-name}:{version}`
- Examples:
  - `br/public:avm/ptn/virtual-network/subnet:0.1.0`
  - Hub-spoke networking patterns
  - Landing zone patterns
  - Application patterns

## AVM Implementation Standards

### Module References
- Always use Bicep Registry references with specific versions
- Pin to specific version numbers (never use 'latest')
- Format: `module {name} 'br/public:avm/{type}/{provider}/{resource}:{version}'`
- Example:
  ```bicep
  module storageAccount 'br/public:avm/res/storage/storage-account:0.9.0' = {
    name: 'storage-deployment'
    params: {
      name: storageAccountName
      location: location
      skuName: 'Standard_LRS'
    }
  }
  ```

### Module Organization
- Store AVM module references in `bicep/modules/`
- Create wrapper modules when you need to customize AVM modules
- Wrapper naming: `{resource-type}-wrapper.bicep`
- Example structure:
  ```
  bicep/modules/
  ├── storage-account-wrapper.bicep  # Wraps AVM storage module
  ├── virtual-network-wrapper.bicep  # Wraps AVM network module
  └── key-vault-wrapper.bicep        # Wraps AVM Key Vault module
  ```

### Wrapper Module Pattern
```bicep
// storage-account-wrapper.bicep
@description('Storage account name')
param name string

@description('Location for the storage account')
param location string

@description('Tags for the resource')
param tags object

// Use AVM module
module storageAccount 'br/public:avm/res/storage/storage-account:0.9.0' = {
  name: 'storage-${name}'
  params: {
    name: name
    location: location
    tags: tags
    // Add organization-specific defaults
    allowBlobPublicAccess: false
    networkAcls: {
      defaultAction: 'Deny'
    }
  }
}

output storageAccountId string = storageAccount.outputs.resourceId
output storageAccountName string = storageAccount.outputs.name
```

## AVM Discovery and Documentation
- Search for modules at: https://aka.ms/avm
- Review module documentation before implementation
- Check module README for required and optional parameters
- Review module outputs for integration with other resources

## Version Management
- Document AVM module versions in project README
- Create upgrade plan when new AVM versions are released
- Test new versions in dev environment before production
- Keep modules up-to-date with quarterly reviews

## Custom Modules
- Only create custom modules when AVM doesn't provide the functionality
- Follow AVM design principles for custom modules
- Consider contributing back to AVM if broadly useful
- Document why custom module was necessary

## AVM Advantages
- Pre-tested and validated by Microsoft
- Follows Azure best practices
- Regular updates and security patches
- Community support and contributions
- Reduced development time
- Consistent patterns across projects