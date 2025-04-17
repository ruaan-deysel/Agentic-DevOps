// Note: Some parameters like 'nodeGroups' and 'workloads' are not directly used in this Bicep file
// but are passed to the post-deployment script for processing.

@description('The Azure region for the resources.')
param location string = resourceGroup().location

@description('Environment name, such as dev, test, or prod - used for tagging.')
param environment string

@description('Required. The name of the AKS cluster.')
param aksClusterName string

@description('Optional. The Kubernetes version.')
param kubernetesVersion string = '1.27.7'

@description('Optional. The VM size for the default node pool.')
param defaultNodePoolVmSize string = 'Standard_D2s_v3'

@description('Optional. The number of nodes in the default node pool.')
param defaultNodePoolCount int = 3

@description('Optional. Enable auto-scaling for the default node pool.')
param defaultNodePoolEnableAutoScaling bool = true

@description('Optional. Minimum number of nodes for auto-scaling.')
param defaultNodePoolMinCount int = 1

@description('Optional. Maximum number of nodes for auto-scaling.')
param defaultNodePoolMaxCount int = 5

@description('Optional. Tags to be applied to the resources.')
param tags object = {}

@description('Optional. Enable Azure Monitor for containers.')
param enableMonitoring bool = true

@description('Optional. Enable Azure Policy for Kubernetes.')
param enableAzurePolicy bool = true

@description('Optional. Enable RBAC for Kubernetes.')
param enableRBAC bool = true

@description('Optional. Enable private cluster.')
param enablePrivateCluster bool = false

@description('Optional. Resource ID of a subnet for the AKS cluster.')
param subnetId string = ''

@description('Optional. Additional node pools to be created.')
param nodeGroups array = []

@description('Optional. Kubernetes workloads to be deployed after cluster creation.')
param workloads array = []

@description('Optional. Network plugin type. "kubenet" or "azure".')
@allowed([
  'kubenet'
  'azure'
])
param networkPlugin string = 'azure'

@description('Optional. Network policy type. "calico" or "azure".')
@allowed([
  'calico'
  'azure'
])
param networkPolicy string = 'azure'

@description('Optional. Enable managed identity for the cluster.')
param enableManagedIdentity bool = true

// Add environment to tags
var allTags = union(tags, {
  Environment: environment
})

// Create AKS cluster
resource aksCluster 'Microsoft.ContainerService/managedClusters@2023-07-02-preview' = {
  name: aksClusterName
  location: location
  tags: allTags
  identity: {
    type: enableManagedIdentity ? 'SystemAssigned' : 'None'
  }
  properties: {
    kubernetesVersion: kubernetesVersion
    dnsPrefix: '${aksClusterName}-dns'
    enableRBAC: enableRBAC
    
    // Network profile
    networkProfile: {
      networkPlugin: networkPlugin
      networkPolicy: networkPolicy
      loadBalancerSku: 'standard'
    }
    
    // Default node pool
    agentPoolProfiles: [
      {
        name: 'agentpool'
        count: defaultNodePoolCount
        vmSize: defaultNodePoolVmSize
        mode: 'System'
        enableAutoScaling: defaultNodePoolEnableAutoScaling
        minCount: defaultNodePoolEnableAutoScaling ? defaultNodePoolMinCount : null
        maxCount: defaultNodePoolEnableAutoScaling ? defaultNodePoolMaxCount : null
        vnetSubnetID: !empty(subnetId) ? subnetId : null
        osType: 'Linux'
        osDiskSizeGB: 128
        type: 'VirtualMachineScaleSets'
        tags: allTags
      }
    ]
    
    // Private cluster settings
    apiServerAccessProfile: enablePrivateCluster ? {
      enablePrivateCluster: true
    } : null
    
    // Add-ons
    addonProfiles: {
      // Azure Monitor for containers
      omsagent: enableMonitoring ? {
        enabled: true
        config: {
          logAnalyticsWorkspaceResourceID: monitoring.id
        }
      } : {
        enabled: false
      }
      
      // Azure Policy for Kubernetes
      azurepolicy: enableAzurePolicy ? {
        enabled: true
      } : {
        enabled: false
      }
    }
  }
}

// Create Log Analytics workspace for monitoring
resource monitoring 'Microsoft.OperationalInsights/workspaces@2022-10-01' = if (enableMonitoring) {
  name: '${aksClusterName}-workspace'
  location: location
  tags: allTags
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 30
  }
}

// Outputs
output aksClusterName string = aksCluster.name
output aksClusterId string = aksCluster.id
output aksClusterFqdn string = aksCluster.properties.fqdn
output aksClusterPrincipalId string = enableManagedIdentity ? aksCluster.identity.principalId : ''
output logAnalyticsWorkspaceId string = enableMonitoring ? monitoring.id : ''

// Output node groups and workloads for post-deployment script
// This ensures the parameters are used in the template and prevents warnings
output nodeGroupsForPostDeployment array = nodeGroups
output workloadsForPostDeployment array = workloads
