---
type: "agent_requested"
description: "Example description"
---

# Azure Naming Conventions

## General Naming Principles
- Follow Azure standard naming conventions
- Use consistent naming patterns across all resources
- Include environment, location, and instance information
- Keep names within Azure length restrictions
- Use lowercase for resource names (except where Azure requires specific casing)
- Use hyphens (-) as separators in resource names

## Standard Naming Pattern
```
{resource-type}-{workload/app-name}-{environment}-{region}-{instance}
```

## Environment Abbreviations
- `dev` - Development
- `tst` - Test
- `stg` - Staging
- `prod` - Production
- `sbx` - Sandbox
- `qa` - Quality Assurance

## Region Abbreviations (Common Azure Regions)
- `eus` - East US
- `wus` - West US
- `eus2` - East US 2
- `wus2` - West US 2
- `cus` - Central US
- `neu` - North Europe
- `weu` - West Europe
- `sea` - Southeast Asia
- `easia` - East Asia
- `uks` - UK South
- `ukw` - UK West
- `aue` - Australia East
- `ause` - Australia Southeast

## Resource Type Prefixes

### Compute
- `vm` - Virtual Machine
- `vmss` - Virtual Machine Scale Set
- `aks` - Azure Kubernetes Service
- `aca` - Azure Container Apps
- `acr` - Azure Container Registry
- `func` - Azure Function App
- `app` - App Service

### Networking
- `vnet` - Virtual Network
- `snet` - Subnet
- `nsg` - Network Security Group
- `asg` - Application Security Group
- `nic` - Network Interface
- `pip` - Public IP Address
- `lb` - Load Balancer
- `appgw` - Application Gateway
- `vpng` - Virtual Network Gateway (VPN)
- `erg` - ExpressRoute Gateway
- `fw` - Azure Firewall
- `route` - Route Table
- `dns` - DNS Zone
- `pdns` - Private DNS Zone
- `endpoint` - Private Endpoint

### Storage
- `st` - Storage Account (no hyphens, max 24 chars, alphanumeric only)
- `dls` - Data Lake Storage
- `blob` - Blob Container
- `share` - File Share
- `queue` - Queue Storage
- `table` - Table Storage

### Databases
- `sql` - SQL Database Server
- `sqldb` - SQL Database
- `cosmos` - Cosmos DB Account
- `redis` - Redis Cache
- `mysql` - MySQL Database
- `psql` - PostgreSQL Database
- `synapse` - Synapse Workspace

### Security & Identity
- `kv` - Key Vault (must be globally unique)
- `vault` - Recovery Services Vault
- `rsv` - Backup Vault
- `aad` - Azure AD

### Management & Governance
- `rg` - Resource Group
- `mg` - Management Group
- `sub` - Subscription
- `policy` - Policy Definition
- `initiative` - Policy Initiative

### Monitoring & Logging
- `log` - Log Analytics Workspace
- `appi` - Application Insights
- `aa` - Automation Account
- `alert` - Alert Rule

### Integration
- `apim` - API Management
- `sb` - Service Bus Namespace
- `sbq` - Service Bus Queue
- `sbt` - Service Bus Topic
- `evh` - Event Hub
- `evhns` - Event Hub Namespace
- `grid` - Event Grid

### Data & Analytics
- `adf` - Data Factory
- `dbw` - Databricks Workspace
- `synapse` - Synapse Workspace
- `purview` - Purview Account

## Naming Examples

### Virtual Machine
```bicep
var vmName = 'vm-webapp-prod-eus-001'
```

### Virtual Network with Subnets
```bicep
var vnetName = 'vnet-hub-prod-eus-001'
var subnetAppName = 'snet-app-prod-eus-001'
var subnetDataName = 'snet-data-prod-eus-001'
```

### Storage Account
```bicep
// No hyphens, lowercase, max 24 chars
var storageAccountName = 'stwebappprodeus001'
```

### Resource Group
```bicep
var resourceGroupName = 'rg-networking-prod-eus-001'
```

### Key Vault
```bicep
var keyVaultName = 'kv-webapp-prod-eus-001'
```

### AKS Cluster
```bicep
var aksClusterName = 'aks-webapp-prod-eus-001'
```

## Special Naming Considerations

### Globally Unique Resources
These resources must be globally unique across Azure:
- Storage accounts (`st*`)
- Key Vaults (`kv-*`)
- App Services (`app-*`)
- Azure Container Registry (`acr*`)
- Cosmos DB (`cosmos-*`)

Add unique identifiers when needed:
```bicep
var uniqueSuffix = uniqueString(resourceGroup().id)
var storageAccountName = 'st${workloadName}${environment}${uniqueSuffix}'
```

### Character Restrictions

#### Storage Accounts
- 3-24 characters
- Lowercase letters and numbers only
- No hyphens or special characters
- Must be globally unique

#### Key Vault
- 3-24 characters
- Alphanumerics and hyphens
- Must start with a letter
- Cannot end with hyphen
- Must be globally unique

#### Virtual Machines
- 1-15 characters (Windows)
- 1-64 characters (Linux)
- Alphanumerics, underscores, and hyphens
- Cannot start or end with hyphen

## Instance Numbering
- Use zero-padded three-digit numbers: `001`, `002`, `003`
- Start at `001` for the first instance
- Increment for multiple instances of the same resource

Examples:
```bicep
'vm-webapp-prod-eus-001'
'vm-webapp-prod-eus-002'
'vm-webapp-prod-eus-003'
```

## Tagging Standards
Apply these tags to ALL resources:
```bicep
var standardTags = {
  Environment: environment          // dev, test, prod
  ManagedBy: 'Bicep'               // IaC tool
  Owner: ownerEmail                // Owner email
  CostCenter: costCenter           // Cost center code
  Project: projectName             // Project name
  ApplicationName: applicationName // Application name
  DeployedBy: deployedBy          // Person/pipeline
  DeployedDate: utcNow()          // Deployment timestamp
}
```

## Naming Variables in Bicep

### Variable Naming Convention
```bicep
// Use camelCase for variable names
var resourceGroupName = 'rg-networking-prod-eus-001'
var virtualNetworkName = 'vnet-hub-prod-eus-001'
var storageAccountName = 'stwebappprodeus001'
```

### Parameter Naming Convention
```bicep
// Use camelCase for parameter names
@description('The environment name')
param environment string

@description('The Azure region for resources')
param location string

@description('The workload name')
param workloadName string
```

## Client-Specific Customization
- These are Azure standard naming conventions
- Adjust prefixes and patterns based on client requirements
- Document client-specific variations in project README
- Maintain consistency within each client's environment
- Create client-specific parameter files with custom naming

## Naming Validation
```bicep
// Example validation for naming standards
@minLength(3)
@maxLength(24)
param keyVaultName string

// Validate environment
@allowed([
  'dev'
  'tst'
  'stg'
  'prod'
  'sbx'
])
param environment string

// Validate location abbreviation
@allowed([
  'eus'
  'wus'
  'eus2'
  'wus2'
  'neu'
  'weu'
])
param locationAbbr string
```

## Documentation
- Document any deviations from standard naming
- Maintain naming convention guide in project README
- Include naming examples for each resource type used
- Update naming conventions when client requirements change