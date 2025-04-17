using '../../main.bicep'

param environment = 'prod'
param apimServiceName = 'apim-nucleus-prod'
param sku = 'Premium'
param skuCount = 2
param publisherEmail = 'admin@dxc.com'
param publisherName = 'DXC'
param tags = {
  Environment: 'Production'
  Project: 'Nucleus-APIM'
}
param enableGatewayLogs = true
param enableResourceLogs = true
param subnetResourceId = '/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-nucleus-apim-prod/providers/Microsoft.Network/virtualNetworks/vnet-nucleus-prod/subnets/snet-apim-prod'
param apis = []
param products = [
  {
    name: 'starter'
    displayName: 'Starter'
    description: 'Starter product with limited access'
    subscriptionRequired: true
    approvalRequired: false
    state: 'published'
  }
  {
    name: 'premium'
    displayName: 'Premium'
    description: 'Premium product with full access'
    subscriptionRequired: true
    approvalRequired: true
    state: 'published'
  }
]
param groups = []
param users = []
param namedValues = []
param policies = []
