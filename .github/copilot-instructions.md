# Bicep Infrastructure-as-Code Guidelines for GitHub Copilot

## 🎯 Critical Rules (ALWAYS Follow)

### 1. ALWAYS Use Azure Verified Modules (AVM)
```bicep
// ✅ CORRECT - Use AVM with specific version
module storageAccount 'br/public:avm/res/storage/storage-account:0.9.0' = {
  name: 'storage-deployment'
  params: {
    name: 'stwebappdeveus001'
    location: 'eastus'
  }
}

// ❌ WRONG - Don't create custom storage modules
resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: 'stwebappdeveus001'
  location: 'eastus'
  // ... custom implementation
}
```

### 2. ALWAYS Use Configuration-Driven Approach
```bicep
// ✅ CORRECT - Parameters from .bicepparam file
@description('Storage account name')
param storageAccountName string

@description('Location for resources')
param location string

@description('Environment name')
@allowed(['dev', 'tst', 'stg', 'prod'])
param environment string

// ❌ WRONG - Hardcoded values
var storageAccountName = 'mystorageaccount123'
var location = 'eastus'
```

### 3. ALWAYS Follow Naming Conventions
```bicep
// Pattern: {resource-type}-{workload}-{environment}-{region}-{instance}

// ✅ CORRECT Examples
var vmName = 'vm-webapp-prod-eus-001'
var vnetName = 'vnet-hub-prod-eus-001'
var kvName = 'kv-webapp-prod-eus-001'
var storageAccountName = 'stwebappprodeus001'  // No hyphens, max 24 chars
var appServiceName = 'app-webapp-prod-eus-001'
var aksName = 'aks-webapp-prod-eus-001'

// ❌ WRONG Examples
var vmName = 'MyVM'
var vnetName = 'vnet1'
var kvName = 'keyvault'
var storageAccountName = 'mystorage'
```

---

## 📋 Standard Patterns

### Storage Account Pattern
```bicep
@description('Workload name')
param workloadName string

@description('Environment')
@allowed(['dev', 'tst', 'stg', 'prod'])
param environment string

@description('Location')
param location string = resourceGroup().location

@description('Tags')
param tags object

// Generate compliant name (no hyphens, lowercase, max 24 chars)
var storageAccountName = 'st${workloadName}${environment}${uniqueString(resourceGroup().id)}'

module storageAccount 'br/public:avm/res/storage/storage-account:0.9.0' = {
  name: 'storage-${workloadName}-deployment'
  params: {
    name: storageAccountName
    location: location
    tags: tags
    skuName: 'Standard_LRS'
    kind: 'StorageV2'
    allowBlobPublicAccess: false
    minimumTlsVersion: 'TLS1_2'
    networkAcls: {
      defaultAction: 'Deny'
      bypass: 'AzureServices'
    }
  }
}

output storageAccountId string = storageAccount.outputs.resourceId
output storageAccountName string = storageAccount.outputs.name
```

### Virtual Network Pattern
```bicep
@description('Workload name')
param workloadName string

@description('Environment')
@allowed(['dev', 'tst', 'stg', 'prod'])
param environment string

@description('Location abbreviation')
param locationAbbr string = 'eus'

@description('Address prefix')
param addressPrefix string

@description('Tags')
param tags object

var vnetName = 'vnet-${workloadName}-${environment}-${locationAbbr}-001'

module virtualNetwork 'br/public:avm/res/network/virtual-network:0.1.0' = {
  name: 'vnet-${workloadName}-deployment'
  params: {
    name: vnetName
    location: location
    tags: tags
    addressPrefixes: [addressPrefix]
    subnets: [
      {
        name: 'snet-app-${environment}-${locationAbbr}-001'
        addressPrefix: cidrSubnet(addressPrefix, 24, 0)
        networkSecurityGroupResourceId: nsgApp.outputs.resourceId
      }
      {
        name: 'snet-data-${environment}-${locationAbbr}-001'
        addressPrefix: cidrSubnet(addressPrefix, 24, 1)
        networkSecurityGroupResourceId: nsgData.outputs.resourceId
      }
    ]
  }
}
```

### Key Vault Pattern
```bicep
@description('Workload name')
param workloadName string

@description('Environment')
@allowed(['dev', 'tst', 'stg', 'prod'])
param environment string

@description('Location abbreviation')
param locationAbbr string = 'eus'

@description('Tags')
param tags object

var keyVaultName = 'kv-${workloadName}-${environment}-${locationAbbr}-001'

module keyVault 'br/public:avm/res/key-vault/vault:0.6.0' = {
  name: 'keyvault-${workloadName}-deployment'
  params: {
    name: keyVaultName
    location: location
    tags: tags
    sku: 'standard'
    enableRbacAuthorization: true
    enablePurgeProtection: true
    enableSoftDelete: true
    softDeleteRetentionInDays: 90
    networkAcls: {
      defaultAction: 'Deny'
      bypass: 'AzureServices'
    }
  }
}

output keyVaultId string = keyVault.outputs.resourceId
output keyVaultName string = keyVault.outputs.name
output keyVaultUri string = keyVault.outputs.uri
```

### AKS Cluster Pattern
```bicep
@description('Cluster name')
param clusterName string

@description('Environment')
@allowed(['dev', 'tst', 'stg', 'prod'])
param environment string

@description('Location abbreviation')
param locationAbbr string = 'eus'

@description('Tags')
param tags object

var aksName = 'aks-${clusterName}-${environment}-${locationAbbr}-001'

module aksCluster 'br/public:avm/res/container-service/managed-cluster:0.1.0' = {
  name: 'aks-${clusterName}-deployment'
  params: {
    name: aksName
    location: location
    tags: tags
    kubernetesVersion: '1.28.0'
    networkPlugin: 'azure'
    networkPolicy: 'azure'
    agentPools: [
      {
        name: 'systempool'
        mode: 'System'
        vmSize: 'Standard_D2s_v3'
        count: 3
        minCount: 3
        maxCount: 5
        enableAutoScaling: true
      }
    ]
  }
}
```

---

## 🏗️ Folder Structure (MANDATORY)

```
your-project/
├── bicep/
│   ├── modules/
│   │   ├── storage-account-wrapper.bicep
│   │   ├── virtual-network-wrapper.bicep
│   │   ├── key-vault-wrapper.bicep
│   │   └── app-service-wrapper.bicep
│   ├── parameters/
│   │   ├── storage-account.dev.bicepparam
│   │   ├── storage-account.prod.bicepparam
│   │   ├── virtual-network.dev.bicepparam
│   │   └── virtual-network.prod.bicepparam
│   └── environments/
│       ├── dev/
│       │   └── main.bicep
│       ├── test/
│       │   └── main.bicep
│       └── prod/
│           └── main.bicep
```

---

## 📝 Parameter File Pattern (.bicepparam)

```bicep
// parameters/storage-account.dev.bicepparam
using '../environments/dev/main.bicep'

param location = 'eastus'
param environment = 'dev'
param workloadName = 'webapp'
param tags = {
  Environment: 'Development'
  ManagedBy: 'Bicep'
  Owner: 'devteam@company.com'
  CostCenter: 'IT-001'
  Project: 'WebApp'
  ApplicationName: 'CustomerPortal'
  DeployedBy: 'AzureDevOps'
}
```

---

## 🏷️ Standard Tags (ALWAYS Apply)

```bicep
@description('Standard tags for all resources')
var standardTags = {
  Environment: environment           // dev, tst, stg, prod
  ManagedBy: 'Bicep'                // IaC tool
  Owner: ownerEmail                 // Owner email
  CostCenter: costCenter            // Cost center code
  Project: projectName              // Project name
  ApplicationName: applicationName  // Application name
  DeployedBy: deployedBy           // Person/pipeline who deployed
  DeployedDate: utcNow()           // Deployment timestamp
}

// Merge with custom tags
var allTags = union(standardTags, customTags)
```

---

## 🔒 Security Defaults (ALWAYS Apply)

```bicep
// Storage Account Security
module storageAccount 'br/public:avm/res/storage/storage-account:0.9.0' = {
  name: 'storage-deployment'
  params: {
    name: storageAccountName
    location: location
    allowBlobPublicAccess: false        // ✅ No public access
    minimumTlsVersion: 'TLS1_2'         // ✅ Minimum TLS 1.2
    supportsHttpsTrafficOnly: true      // ✅ HTTPS only
    networkAcls: {
      defaultAction: 'Deny'             // ✅ Deny by default
      bypass: 'AzureServices'
    }
    enableHierarchicalNamespace: false
  }
}

// Key Vault Security
module keyVault 'br/public:avm/res/key-vault/vault:0.6.0' = {
  name: 'keyvault-deployment'
  params: {
    name: keyVaultName
    location: location
    enableRbacAuthorization: true       // ✅ Use RBAC, not access policies
    enablePurgeProtection: true         // ✅ Enable purge protection
    enableSoftDelete: true              // ✅ Enable soft delete
    softDeleteRetentionInDays: 90       // ✅ 90-day retention
    networkAcls: {
      defaultAction: 'Deny'             // ✅ Deny by default
      bypass: 'AzureServices'
    }
  }
}

// Network Security Group
module nsg 'br/public:avm/res/network/network-security-group:0.1.0' = {
  name: 'nsg-deployment'
  params: {
    name: nsgName
    location: location
    securityRules: [
      {
        name: 'DenyAllInbound'
        priority: 4096
        direction: 'Inbound'
        access: 'Deny'
        protocol: '*'
        sourcePortRange: '*'
        destinationPortRange: '*'
        sourceAddressPrefix: '*'
        destinationAddressPrefix: '*'
      }
    ]
  }
}
```

---

## 📦 Parameter Decorators (ALWAYS Use)

```bicep
// String parameters
@description('The name of the workload')
@minLength(3)
@maxLength(20)
param workloadName string

// Environment parameter
@description('The environment name')
@allowed(['dev', 'tst', 'stg', 'prod', 'sbx'])
param environment string

// Location parameter
@description('Azure region for resources')
@allowed(['eastus', 'westus', 'northeurope', 'westeurope'])
param location string

// Secure parameter (for secrets)
@description('Administrator password')
@secure()
param adminPassword string

// Integer with range
@description('Number of instances')
@minValue(1)
@maxValue(10)
param instanceCount int = 3

// Array parameter
@description('List of allowed IP addresses')
param allowedIpAddresses array = []

// Object parameter
@description('Tags for resources')
param tags object = {}
```

---

## 🎨 Resource Naming Reference

| Resource Type | Prefix | Example |
|--------------|--------|---------|
| Virtual Machine | `vm` | `vm-webapp-prod-eus-001` |
| Virtual Network | `vnet` | `vnet-hub-prod-eus-001` |
| Subnet | `snet` | `snet-app-prod-eus-001` |
| Network Security Group | `nsg` | `nsg-webapp-prod-eus-001` |
| Storage Account | `st` | `stwebappprodeus001` |
| Key Vault | `kv` | `kv-webapp-prod-eus-001` |
| App Service | `app` | `app-webapp-prod-eus-001` |
| Function App | `func` | `func-webapp-prod-eus-001` |
| AKS Cluster | `aks` | `aks-webapp-prod-eus-001` |
| SQL Server | `sql` | `sql-webapp-prod-eus-001` |
| SQL Database | `sqldb` | `sqldb-webapp-prod-eus-001` |
| Cosmos DB | `cosmos` | `cosmos-webapp-prod-eus-001` |
| Redis Cache | `redis` | `redis-webapp-prod-eus-001` |
| Log Analytics | `log` | `log-prod-eus-001` |
| Application Insights | `appi` | `appi-webapp-prod-eus-001` |
| Container Registry | `acr` | `acrwebappprodeus001` |
| Public IP | `pip` | `pip-webapp-prod-eus-001` |
| Load Balancer | `lb` | `lb-webapp-prod-eus-001` |
| Application Gateway | `appgw` | `appgw-webapp-prod-eus-001` |
| Azure Firewall | `fw` | `fw-hub-prod-eus-001` |

---

## 🔄 Common AVM Module References

```bicep
// Storage Account
'br/public:avm/res/storage/storage-account:0.9.0'

// Virtual Network
'br/public:avm/res/network/virtual-network:0.1.0'

// Network Security Group
'br/public:avm/res/network/network-security-group:0.1.0'

// Key Vault
'br/public:avm/res/key-vault/vault:0.6.0'

// App Service
'br/public:avm/res/web/site:0.3.0'

// App Service Plan
'br/public:avm/res/web/serverfarm:0.2.0'

// SQL Server
'br/public:avm/res/sql/server:0.1.0'

// Log Analytics Workspace
'br/public:avm/res/operational-insights/workspace:0.3.0'

// Application Insights
'br/public:avm/res/insights/component:0.3.0'

// Container Registry
'br/public:avm/res/container-registry/registry:0.1.0'

// AKS Cluster
'br/public:avm/res/container-service/managed-cluster:0.1.0'

// Public IP
'br/public:avm/res/network/public-ip-address:0.2.0'

// Load Balancer
'br/public:avm/res/network/load-balancer:0.1.0'
```

---

## 🚫 NEVER Do These Things

```bicep
// ❌ NEVER use 'latest' API version
resource storageAccount 'Microsoft.Storage/storageAccounts@latest' = {}

// ❌ NEVER hardcode values
var storageAccountName = 'mystorageaccount'
var location = 'eastus'

// ❌ NEVER omit @description
param someParameter string

// ❌ NEVER skip parameter validation
param environment string  // Should use @allowed decorator

// ❌ NEVER store secrets in parameter files
param adminPassword = 'MyPassword123!'  // Use @secure() and Key Vault

// ❌ NEVER allow public access by default
allowBlobPublicAccess: true  // Should be false

// ❌ NEVER use weak naming
var storageName = 'storage1'
var vmName = 'vm1'

// ❌ NEVER skip tags
resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: storageAccountName
  location: location
  // Missing tags!
}

// ❌ NEVER create resources without checking AVM first
// If AVM has a module, use it!
```

---

## ✅ Module Output Pattern

```bicep
// ALWAYS provide these standard outputs
output resourceId string = resource.outputs.resourceId
output resourceName string = resource.outputs.name
output location string = location

// Provide resource-specific outputs
output storageAccountPrimaryEndpoints object = storageAccount.outputs.primaryEndpoints
output keyVaultUri string = keyVault.outputs.uri
output virtualNetworkId string = virtualNetwork.outputs.resourceId
```

---

## 🏁 Deployment Pattern

```bicep
// environments/dev/main.bicep
targetScope = 'subscription'  // or 'resourceGroup'

@description('Location for all resources')
param location string = 'eastus'

@description('Environment name')
@allowed(['dev', 'tst', 'stg', 'prod'])
param environment string = 'dev'

@description('Workload name')
param workloadName string

// Resource Group
module rg 'br/public:avm/res/resources/resource-group:0.2.0' = {
  name: 'rg-${workloadName}-${environment}-deployment'
  params: {
    name: 'rg-${workloadName}-${environment}-${locationAbbr}-001'
    location: location
    tags: standardTags
  }
}

// Storage Account
module storage '../modules/storage-account-wrapper.bicep' = {
  name: 'storage-deployment'
  scope: resourceGroup(rg.outputs.name)
  params: {
    workloadName: workloadName
    environment: environment
    location: location
    tags: standardTags
  }
}

// Key Vault
module keyVault '../modules/key-vault-wrapper.bicep' = {
  name: 'keyvault-deployment'
  scope: resourceGroup(rg.outputs.name)
  params: {
    workloadName: workloadName
    environment: environment
    location: location
    tags: standardTags
  }
}
```

---

## 📚 Environment Abbreviations

| Environment | Abbreviation |
|------------|--------------|
| Development | `dev` |
| Test | `tst` |
| Staging | `stg` |
| Production | `prod` |
| Sandbox | `sbx` |
| Quality Assurance | `qa` |

## 🌍 Location Abbreviations

| Region | Abbreviation |
|--------|--------------|
| East US | `eus` |
| West US | `wus` |
| East US 2 | `eus2` |
| West US 2 | `wus2` |
| Central US | `cus` |
| North Europe | `neu` |
| West Europe | `weu` |
| Southeast Asia | `sea` |
| East Asia | `easia` |
| UK South | `uks` |
| UK West | `ukw` |
| Australia East | `aue` |
| Australia Southeast | `ause` |

---

## 💡 Quick Reference: File Header Template

```bicep
/*
  File: storage-account-wrapper.bicep
  Purpose: Wrapper module for Azure Storage Account using AVM
  Author: [Team Name]
  Created: [Date]
  
  Description:
  This module wraps the AVM Storage Account module with organization-specific
  defaults and security settings.
  
  Dependencies:
  - Azure Verified Module: storage/storage-account:0.9.0
  
  Usage:
  See parameters/storage-account.{env}.bicepparam for configuration examples
*/

targetScope = 'resourceGroup'

// Parameters
@description('Storage account name (3-24 chars, lowercase, alphanumeric)')
@minLength(3)
@maxLength(24)
param name string
```

---

## 🎯 Summary: Golden Rules

1. **AVM First** - Always use Azure Verified Modules
2. **No Hardcoding** - Everything in .bicepparam files
3. **Naming Standards** - `{type}-{workload}-{env}-{region}-{instance}`
4. **Security Default** - Deny public access, enable RBAC, use TLS 1.2+
5. **Always Describe** - @description on every parameter
6. **Always Validate** - @allowed, @minLength, @maxLength decorators
7. **Always Tag** - Standard tags on all resources
8. **Always Version** - Pin specific AVM versions
9. **Always Output** - resourceId, name, location minimum
10. **Always Document** - File headers and inline comments

---

*Follow these patterns for consistent, secure, production-ready Bicep infrastructure code.*