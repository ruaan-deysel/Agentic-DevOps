// Note: Some parameters like 'groups' and 'users' are not directly used in this Bicep file
// but are passed to the post-deployment script for processing.

@description('The Azure region for the resources.')
param location string = resourceGroup().location

@description('Environment name, such as dev, test, or prod - used for tagging.')
param environment string

@description('Required. The name of the API Management service.')
param apimServiceName string

@description('Optional. The pricing tier of this API Management service.')
@allowed([
  'Basic'
  'Consumption'
  'Developer'
  'Premium'
  'Standard'
])
param sku string = 'Developer'

@description('Optional. The instance size of this API Management service.')
param skuCount int = 1

@description('Optional. Tags to be applied to the resources.')
param tags object = {}

@description('Optional. Whether to enable diagnostic settings for gateway logs.')
param enableGatewayLogs bool = true

@description('Optional. Whether to enable diagnostic settings for resource logs.')
param enableResourceLogs bool = true

@description('Optional. The email address of the publisher of the API Management service.')
param publisherEmail string = 'admin@dxc.com'

@description('Optional. The name of the publisher of the API Management service.')
param publisherName string = 'DXC'

@description('Optional. Resource ID of a subnet to deploy the API Management service in.')
param subnetResourceId string = ''

@description('Optional. List of APIs to be configured in the API Management service.')
param apis array = []

@description('Optional. List of Products to be configured in the API Management service.')
param products array = []

@description('Optional. List of Groups to be configured in the API Management service. These are processed by the post-deployment script.')
param groups array = []

@description('Optional. List of Users to be configured in the API Management service. These are processed by the post-deployment script.')
param users array = []

@description('Optional. List of Named Values to be configured in the API Management service.')
param namedValues array = []

@description('Optional. List of Policies to be configured in the API Management service.')
param policies array = []

// Add environment to tags
var allTags = union(tags, {
  Environment: environment
})

// Use Azure Verified Module for API Management
module apim 'br/public:avm/res/api-management/service:0.9.1' = {
  name: 'apim-${apimServiceName}-deployment'
  params: {
    name: apimServiceName
    location: location
    publisherEmail: publisherEmail
    publisherName: publisherName

    // Proper handling of SKU
    sku: sku
    skuCapacity: contains(sku, 'Consumption') ? 0 : contains(sku, 'Developer') ? 1 : skuCount

    // Setting up managed identity
    managedIdentities: {
      systemAssigned: true
    }

    // Add tags
    tags: allTags

    // Configure virtual network integration if subnetResourceId is provided
    virtualNetworkType: !empty(subnetResourceId) ? 'External' : 'None'
    subnetResourceId: !empty(subnetResourceId) ? subnetResourceId : null
    // Configure diagnostic settings
    diagnosticSettings: [
      {
        name: 'diagnosticSettings'
        logCategoriesAndGroups: [
          // Audit logs
          {
            categoryGroup: 'audit'
            enabled: enableResourceLogs
          }
          // Gateway logs
          {
            categoryGroup: 'gateway'
            enabled: enableGatewayLogs
          }
          // All other logs
          {
            categoryGroup: 'allLogs'
            enabled: enableResourceLogs
          }
        ]
        metricCategories: [
          {
            category: 'AllMetrics'
            enabled: true
          }
        ]
        logAnalyticsDestinationType: 'Dedicated'
      }
    ]

    // Gateway logging is configured through diagnostic settings

    // Configure APIs
    apis: apis

    // Configure Products
    products: products

    // Groups and Users are not directly supported in the latest AVM module version
    // They will be configured through the post-deployment script

    // Configure Named Values
    namedValues: namedValues

    // Configure Policies
    policies: policies
  }
}

// Outputs
output apimName string = apim.outputs.name
output apimResourceId string = apim.outputs.resourceId
output apimPrincipalId string = apim.outputs.?systemAssignedMIPrincipalId ?? ''

// Note: The following URLs are not directly available from module outputs
// They can be retrieved using the Azure CLI or PowerShell after deployment
output apimServiceUrl string = 'https://${apimServiceName}.azure-api.net'
output apimPortalUrl string = 'https://${apimServiceName}.portal.azure-api.net'
output apimManagementUrl string = 'https://${apimServiceName}.management.azure-api.net'
output apimScmUrl string = 'https://${apimServiceName}.scm.azure-api.net'

// Output groups and users for post-deployment script
// This ensures the parameters are used in the template and prevents warnings
output groupsForPostDeployment array = groups
output usersForPostDeployment array = users
