using '../../main.bicep'

param environment = 'test'
param apimServiceName = 'apim-nucleus-test'
param sku = 'Developer'
param skuCount = 1
param publisherEmail = 'admin@dxc.com'
param publisherName = 'DXC'
param tags = {
  Environment: 'Test'
  Project: 'Nucleus-APIM'
}
param enableGatewayLogs = true
param enableResourceLogs = true
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
]
param groups = []
param users = []
param namedValues = []
param policies = []
