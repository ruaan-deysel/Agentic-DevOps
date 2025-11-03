---
type: "agent_requested"
description: "Bicep File Structure and Documentation Standards"
---

# Bicep File Structure and Documentation Standards

## Overview
This document defines the mandatory structure and documentation standards for all Bicep files in this repository. These standards ensure consistency, maintainability, and professional quality across all Infrastructure as Code modules.

## File Header Block Requirements

### Standard Format
Every Bicep module file MUST begin with a comprehensive header block using the following format:

```bicep
// ============================================================================
// MODULE TITLE IN UPPERCASE
// ============================================================================
// Multi-line description explaining what the module deploys and its purpose.
// This section should include:
// - Key features or capabilities provided by the module
// - Security configurations or considerations
// - Integration points with other services
// - Any important behavioral notes
//
// Dependencies: List of required resources (e.g., Virtual Network, Key Vault)
// Deployment Scope: Resource Group | Subscription | Management Group | Tenant
// ============================================================================

metadata name = 'Module Display Name'
metadata description = 'Concise description of the module purpose and functionality.'
metadata owner = 'Team or Owner Name'
```

### Header Block Components

#### 1. Divider Lines
- **Format**: `// ============================================================================`
- **Length**: Exactly 78 equals signs (`=`)
- **Purpose**: Visual separation and professional appearance
- **Placement**: Before title, after title, and after deployment scope

#### 2. Module Title
- **Format**: Uppercase with descriptive name
- **Examples**:
  - `AZURE VIRTUAL DESKTOP HOST POOL MODULE`
  - `AZURE VIRTUAL DESKTOP SESSION HOST VIRTUAL MACHINES MODULE`
  - `STORAGE ACCOUNT WITH PRIVATE ENDPOINT MODULE`
- **Guidelines**: Be specific and descriptive, include service name

#### 3. Description Section
- **Format**: Multi-line comment block
- **Content**:
  - First line: High-level explanation of what the module deploys
  - Following lines: Key features as bullet points
  - Use `// -` for bullet points
- **Example**:
  ```bicep
  // This module deploys an Azure Virtual Desktop Host Pool with enterprise
  // configuration including:
  // - Configurable load balancing (BreadthFirst or DepthFirst)
  // - Validation environment support for testing
  // - Diagnostic settings integration with Log Analytics
  // - Support for both pooled and personal desktop scenarios
  // - Automatic session host registration token generation
  ```

#### 4. Dependencies Section
- **Format**: `// Dependencies: <comma-separated list>`
- **Content**: List all Azure resources or modules that must exist before deployment
- **Examples**:
  - `// Dependencies: None (core AVD resource)`
  - `// Dependencies: AVD Host Pool`
  - `// Dependencies: Virtual Network, AVD Host Pool, Key Vault (optional)`
- **Guidelines**: Mark optional dependencies with "(optional)" suffix

#### 5. Deployment Scope
- **Format**: `// Deployment Scope: <scope>`
- **Valid Values**:
  - `Resource Group` (most common)
  - `Subscription`
  - `Management Group`
  - `Tenant`
- **Purpose**: Clearly indicates the Azure scope at which the module deploys

#### 6. Metadata Block
- **Placement**: Immediately after the header block divider
- **Required Fields**:
  - `metadata name` - Display name for the module
  - `metadata description` - Concise description (1-2 sentences)
  - `metadata owner` - Team or individual responsible for maintenance
- **Example**:
  ```bicep
  metadata name = 'AVD Host Pool'
  metadata description = 'This module deploys an Azure Virtual Desktop Host Pool with configurable load balancing, validation environment settings, and diagnostic capabilities.'
  metadata owner = 'AVD Platform Team'
  ```

## Section Header Requirements

### Standard Section Organization
All Bicep files MUST organize content into clearly defined sections in this order:

1. **PARAMETERS** - All input parameters
2. **VARIABLES** - All variables (if any)
3. **RESOURCES** - All resource deployments
4. **OUTPUTS** - All output values

### Section Header Format

```bicep
// ============================================================================
// SECTION NAME IN UPPERCASE
// ============================================================================
```

#### Section Header Rules
- **Divider Length**: Exactly 78 equals signs (`=`)
- **Section Name**: Uppercase only (e.g., `PARAMETERS`, not `Parameters` or `parameters`)
- **No Extra Text**: Section headers should contain only the section name
- **Blank Lines**: One blank line before the section header, one blank line after

### Section Examples

#### PARAMETERS Section
```bicep
// ============================================================================
// PARAMETERS
// ============================================================================

@description('Required. The name of the resource.')
@minLength(3)
@maxLength(64)
param resourceName string

@description('Optional. Location for all resources.')
param location string = resourceGroup().location
```

#### VARIABLES Section
```bicep
// ============================================================================
// VARIABLES
// ============================================================================

var resourceNameCleaned = replace(resourceName, '-', '')
var uniqueSuffix = uniqueString(resourceGroup().id)
```

#### RESOURCES Section
```bicep
// ============================================================================
// RESOURCES
// ============================================================================

// Resource description explaining purpose and key configuration
resource example 'Microsoft.Provider/type@2024-01-01' = {
  name: resourceName
  location: location
  properties: {
    // resource properties
  }
}
```

#### OUTPUTS Section
```bicep
// ============================================================================
// OUTPUTS
// ============================================================================

@description('The resource ID of the deployed resource.')
output resourceId string = example.id

@description('The name of the deployed resource.')
output resourceName string = example.name
```

## Complete File Structure Example

```bicep
// ============================================================================
// AZURE VIRTUAL DESKTOP HOST POOL MODULE
// ============================================================================
// This module deploys an Azure Virtual Desktop Host Pool with enterprise
// configuration including:
// - Configurable load balancing (BreadthFirst or DepthFirst)
// - Validation environment support for testing
// - Diagnostic settings integration with Log Analytics
// - Support for both pooled and personal desktop scenarios
// - Automatic session host registration token generation
//
// Dependencies: None (core AVD resource)
// Deployment Scope: Resource Group
// ============================================================================

metadata name = 'AVD Host Pool'
metadata description = 'This module deploys an Azure Virtual Desktop Host Pool with configurable load balancing, validation environment settings, and diagnostic capabilities.'
metadata owner = 'AVD Platform Team'

// ============================================================================
// PARAMETERS
// ============================================================================

@description('Required. The name of the AVD Host Pool.')
@minLength(3)
@maxLength(64)
param hostPoolName string

@description('Optional. Location for all resources.')
param location string = resourceGroup().location

@description('Required. Type of host pool.')
@allowed([
  'Pooled'
  'Personal'
])
param hostPoolType string

@description('Optional. Load balancing algorithm.')
@allowed([
  'BreadthFirst'
  'DepthFirst'
])
param loadBalancerType string = 'BreadthFirst'

// ============================================================================
// VARIABLES
// ============================================================================

var registrationTokenExpirationTime = dateTimeAdd(utcNow(), 'PT2H')

// ============================================================================
// RESOURCES
// ============================================================================

// AVD Host Pool resource with configurable settings for pooled or personal desktop scenarios
resource hostPool 'Microsoft.DesktopVirtualization/hostPools@2024-08-01' = {
  name: hostPoolName
  location: location
  properties: {
    hostPoolType: hostPoolType
    loadBalancerType: loadBalancerType
    registrationInfo: {
      expirationTime: registrationTokenExpirationTime
      registrationTokenOperation: 'Update'
    }
  }
}

// Diagnostic settings for Host Pool monitoring and compliance
// Sends logs and metrics to Log Analytics workspace for AVD Insights
resource diagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01' = {
  name: '${hostPoolName}-diagnostics'
  scope: hostPool
  properties: {
    workspaceId: logAnalyticsWorkspaceId
    logs: [
      {
        category: 'Checkpoint'
        enabled: true
      }
    ]
  }
}

// ============================================================================
// OUTPUTS
// ============================================================================

@description('The resource ID of the Host Pool.')
output hostPoolId string = hostPool.id

@description('The name of the Host Pool.')
output hostPoolName string = hostPool.name

@description('The registration token for session hosts.')
@secure()
output registrationToken string = hostPool.properties.registrationInfo.token
```

## Inline Comment Requirements

### Resource Comments
- **Placement**: Immediately before each resource declaration
- **Format**: Single or multi-line comment explaining the resource purpose
- **Content**:
  - What the resource does
  - Why it's configured in a specific way
  - Any important dependencies or relationships
  - Security considerations

### Examples

#### Single-line Resource Comment
```bicep
// AVD Host Pool resource with configurable settings for pooled or personal desktop scenarios
resource hostPool 'Microsoft.DesktopVirtualization/hostPools@2024-08-01' = {
```

#### Multi-line Resource Comment
```bicep
// AVD DSC extension for registering session hosts with the host pool
// Uses Microsoft's official DSC configuration to join VMs to the AVD host pool
// Supports both Azure AD join and traditional domain join scenarios
resource avdExtension 'Microsoft.Compute/virtualMachines/extensions@2023-09-01' = [
```

### Complex Logic Comments
Add inline comments for:
- Conditional deployments
- Complex expressions or calculations
- Non-obvious business logic
- Security-related configurations
- Dependency chains

```bicep
// Only deploy domain join extension when domainFqdn is provided
// Skipped for Azure AD join scenarios
resource domainJoinExtension 'Microsoft.Compute/virtualMachines/extensions@2023-09-01' = [
  for i in range(0, sessionHostCount): if (!empty(domainJoinConfig.domainFqdn)) {
```

## Parameter Documentation Requirements

### Required Decorators
Every parameter MUST have:
- `@description()` - Clear explanation of the parameter purpose
- Validation decorators where applicable:
  - `@minLength()` / `@maxLength()` for strings
  - `@minValue()` / `@maxValue()` for integers
  - `@allowed()` for enumerated values
  - `@secure()` for sensitive values (passwords, keys, tokens)

### Parameter Documentation Examples

```bicep
@description('Required. The name of the resource.')
@minLength(3)
@maxLength(64)
param resourceName string

@description('Required. Administrator password for the virtual machine.')
@secure()
param adminPassword string

@description('Optional. The SKU of the resource.')
@allowed([
  'Standard'
  'Premium'
])
param sku string = 'Standard'

@description('Optional. The number of instances to deploy.')
@minValue(1)
@maxValue(100)
param instanceCount int = 1
```

## Output Documentation Requirements

### Required Decorators
Every output MUST have:
- `@description()` - Clear explanation of what the output returns
- `@secure()` - For sensitive outputs (tokens, keys, connection strings)

### Output Documentation Examples

```bicep
@description('The resource ID of the deployed resource.')
output resourceId string = example.id

@description('The primary endpoint URL.')
output endpoint string = example.properties.primaryEndpoint

@description('The access key for the resource.')
@secure()
output accessKey string = example.listKeys().keys[0].value
```

## Enforcement and Application

### Scope of Application
These standards MUST be applied to:
- ✅ All new Bicep module files
- ✅ All existing module files during updates or modifications
- ✅ Custom modules developed for this repository
- ✅ Wrapper modules around Azure Verified Modules (AVM)
- ✅ Main orchestration files (e.g., `main.bicep`)

### Exceptions
The following files may use simplified headers:
- Parameter files (`.bicepparam`) - no header block required
- Test files in test directories - simplified headers acceptable
- Generated files - if clearly marked as auto-generated

### Validation
- All Bicep files must pass `az bicep lint` without errors
- Documentation completeness should be verified during code reviews
- Automated checks should validate header block presence and format

## Benefits of These Standards

1. **Consistency**: All modules follow identical structure and formatting
2. **Discoverability**: Developers can quickly understand module purpose and dependencies
3. **Maintainability**: Clear organization makes updates and debugging easier
4. **Professionalism**: Enterprise-grade documentation headers
5. **Onboarding**: New team members can navigate codebase efficiently
6. **Compliance**: Meets enterprise IaC documentation requirements
7. **AI-Assisted Development**: Clear structure enables better AI code generation and assistance

## Related Standards

- See `bicep-general.md` for general Bicep best practices
- See `bicep-naming.md` for resource naming conventions
- See `bicep-avm.md` for Azure Verified Modules usage
- See `bicep-configuration.md` for configuration-driven development patterns
