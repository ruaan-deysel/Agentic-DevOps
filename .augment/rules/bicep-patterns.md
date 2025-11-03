---
type: "agent_requested"
description: "Example description"
---

# Bicep Patterns and Landing Zones

## Pattern-Based Development
- ALWAYS use established Azure architectural patterns
- Follow Azure Landing Zone design principles
- Implement patterns using Azure Verified Modules when possible
- Create reusable pattern templates for common scenarios

## Azure Landing Zone Principles

### Core Landing Zone Components
Landing Zones must include these foundational elements:

1. **Identity and Access Management**
   - Azure AD integration
   - Role-Based Access Control (RBAC)
   - Privileged Identity Management (PIM)
   - Conditional Access policies

2. **Management Group Hierarchy**
   - Root management group
   - Platform management groups (connectivity, management, identity)
   - Landing zone management groups (corp, online)
   - Sandbox environments

3. **Network Topology**
   - Hub-spoke architecture
   - Virtual WAN (when appropriate)
   - Network segmentation
   - Hybrid connectivity (VPN/ExpressRoute)

4. **Security**
   - Azure Policy for governance
   - Azure Security Center/Defender
   - Network security groups (NSGs)
   - Azure Firewall
   - DDoS Protection

5. **Monitoring and Logging**
   - Log Analytics workspace
   - Azure Monitor
   - Diagnostic settings
   - Alert rules

## Landing Zone Structure

### Folder Organization
```
bicep/
├── modules/
│   ├── landing-zone/
│   │   ├── management-groups.bicep
│   │   ├── networking-hub.bicep
│   │   ├── networking-spoke.bicep
│   │   ├── monitoring.bicep
│   │   ├── security.bicep
│   │   └── policies.bicep
│   └── shared-services/
│       ├── log-analytics.bicep
│       ├── key-vault.bicep
│       └── automation-account.bicep
├── parameters/
│   ├── landing-zone.dev.bicepparam
│   ├── landing-zone.prod.bicepparam
│   └── shared-services.bicepparam
└── environments/
    ├── dev/
    │   └── main.bicep
    └── prod/
        └── main.bicep
```

## Network Patterns

### Hub-Spoke Topology
```bicep
// Hub virtual network with shared services
module hubNetwork 'br/public:avm/res/network/virtual-network:0.1.0' = {
  name: 'hub-network-deployment'
  params: {
    name: 'vnet-hub-${environment}-${location}-001'
    addressPrefixes: ['10.0.0.0/16']
    subnets: [
      {
        name: 'AzureFirewallSubnet'
        addressPrefix: '10.0.1.0/24'
      }
      {
        name: 'GatewaySubnet'
        addressPrefix: '10.0.2.0/24'
      }
      {
        name: 'AzureBastionSubnet'
        addressPrefix: '10.0.3.0/24'
      }
    ]
  }
}

// Spoke virtual network for workloads
module spokeNetwork 'br/public:avm/res/network/virtual-network:0.1.0' = {
  name: 'spoke-network-deployment'
  params: {
    name: 'vnet-spoke-${workloadName}-${environment}-${location}-001'
    addressPrefixes: ['10.1.0.0/16']
    subnets: [
      {
        name: 'snet-app'
        addressPrefix: '10.1.1.0/24'
      }
      {
        name: 'snet-data'
        addressPrefix: '10.1.2.0/24'
      }
    ]
  }
}

// VNet peering between hub and spoke
module peering 'br/public:avm/res/network/virtual-network-peering:0.1.0' = {
  name: 'hub-spoke-peering'
  params: {
    remoteVirtualNetworkId: spokeNetwork.outputs.resourceId
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: true
    allowGatewayTransit: true
  }
}
```

## Common Patterns

### Pattern: Shared Services
```bicep
// Log Analytics Workspace (central logging)
module logAnalytics 'br/public:avm/res/operational-insights/workspace:0.3.0' = {
  name: 'log-analytics-deployment'
  params: {
    name: 'log-${environment}-${location}-001'
    location: location
    sku: 'PerGB2018'
    retentionInDays: 30
  }
}

// Key Vault (central secrets management)
module keyVault 'br/public:avm/res/key-vault/vault:0.6.0' = {
  name: 'key-vault-deployment'
  params: {
    name: 'kv-${environment}-${location}-001'
    location: location
    enableRbacAuthorization: true
    enablePurgeProtection: true
  }
}
```

### Pattern: Workload Landing Zone
```bicep
// Deploy spoke network
module workloadNetwork '../modules/landing-zone/networking-spoke.bicep' = {
  name: 'workload-network'
  params: {
    workloadName: workloadName
    environment: environment
    addressPrefix: workloadAddressPrefix
  }
}

// Deploy workload resources
module appService 'br/public:avm/res/web/site:0.3.0' = {
  name: 'app-service-deployment'
  params: {
    name: 'app-${workloadName}-${environment}-001'
    location: location
    kind: 'app'
    serverFarmResourceId: appServicePlan.outputs.resourceId
  }
}
```

## Policy and Governance Patterns

### Azure Policy Deployment
```bicep
// Apply policies at management group or subscription level
module policies '../modules/landing-zone/policies.bicep' = {
  name: 'policy-deployment'
  params: {
    policies: [
      {
        name: 'require-tags'
        displayName: 'Require tags on resources'
        effect: 'Audit'
      }
      {
        name: 'allowed-locations'
        displayName: 'Allowed locations for resources'
        effect: 'Deny'
        allowedLocations: ['eastus', 'westus']
      }
    ]
  }
}
```

## Pattern Implementation Guidelines

### When to Use Patterns
- Landing zone deployment (new subscription/environment)
- Multi-region deployments
- Disaster recovery configurations
- Hub-spoke network architecture
- Shared services infrastructure
- Workload isolation requirements

### Pattern Customization
- Start with AVM pattern modules when available
- Customize patterns in wrapper modules
- Document deviations from standard patterns
- Maintain pattern documentation in README files

### Pattern Testing
- Test patterns in sandbox subscriptions first
- Validate across different Azure regions
- Test with different parameter configurations
- Verify pattern compliance with policies

## Landing Zone Deployment Sequence
1. Deploy management groups
2. Apply Azure policies
3. Deploy hub network infrastructure
4. Deploy shared services (Log Analytics, Key Vault)
5. Deploy spoke networks
6. Configure network connectivity (peering, firewalls)
7. Deploy workload-specific resources
8. Configure monitoring and alerts

## Documentation Requirements
- Document the chosen pattern and why
- Diagram network topology
- List all interconnected resources
- Document DNS configuration
- Provide deployment runbook
- Include troubleshooting guide