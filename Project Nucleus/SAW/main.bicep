// ExpressRoute Circuit Deployment Template using Azure Verified Module
// This template deploys an ExpressRoute circuit and connects it to an existing virtual network gateway

@description('The Azure region for the resources.')
param location string = resourceGroup().location

@description('The name of the ExpressRoute circuit.')
param circuitName string

@description('The SKU tier of the ExpressRoute circuit.')
@allowed([
  'Standard'
  'Premium'
])
param skuTier string = 'Standard'

@description('The SKU family of the ExpressRoute circuit.')
@allowed([
  'MeteredData'
  'UnlimitedData'
])
param skuFamily string = 'MeteredData'

@description('The bandwidth of the ExpressRoute circuit in Mbps.')
@allowed([
  50
  100
  200
  500
  1000
  2000
  5000
  10000
])
param bandwidthInMbps int = 50

@description('The peering location of the ExpressRoute circuit.')
param peeringLocation string

@description('The name of the service provider for the ExpressRoute circuit.')
param serviceProviderName string = 'Equinix'

@description('The name of the resource group containing the existing virtual network gateway.')
param gatewayResourceGroupName string

@description('The name of the existing virtual network gateway to connect the ExpressRoute circuit to.')
param gatewayName string

@description('Optional. Tags to be applied to the resources.')
param tags object = {}

@description('Optional. Configure private peering for the ExpressRoute circuit.')
param configurePrivatePeering bool = false

@description('Optional. Autonomous system number for private peering.')
param peerASN int = 65001

@description('Optional. Primary peer subnet for private peering.')
param primaryPeerAddressPrefix string = '192.168.10.16/30'

@description('Optional. Secondary peer subnet for private peering.')
param secondaryPeerAddressPrefix string = '192.168.10.20/30'

@description('Optional. VLAN ID for private peering.')
param vlanId int = 100

// Reference to the existing virtual network gateway
resource existingGateway 'Microsoft.Network/virtualNetworkGateways@2023-09-01' existing = {
  name: gatewayName
  scope: resourceGroup(gatewayResourceGroupName)
}

// Deploy the ExpressRoute circuit using the Azure Verified Module
module expressRouteCircuit 'br/public:avm/res/network/express-route-circuit:0.3.0' = {
  name: 'expressRouteCircuit-Deployment'
  params: {
    name: circuitName
    location: location
    tags: tags
    skuTier: skuTier
    skuFamily: skuFamily
    bandwidthInMbps: bandwidthInMbps
    peeringLocation: peeringLocation
    serviceProviderName: serviceProviderName
    allowClassicOperations: false
    peering: configurePrivatePeering
    peeringType: 'AzurePrivatePeering'
    peerASN: peerASN
    primaryPeerAddressPrefix: primaryPeerAddressPrefix
    secondaryPeerAddressPrefix: secondaryPeerAddressPrefix
    vlanId: vlanId
  }
}

// Create a connection between the ExpressRoute circuit and the virtual network gateway
resource connection 'Microsoft.Network/connections@2023-09-01' = {
  name: '${circuitName}-connection'
  location: location
  tags: tags
  properties: {
    connectionType: 'ExpressRoute'
    virtualNetworkGateway1: {
      id: existingGateway.id
    }
    peer: {
      id: expressRouteCircuit.outputs.resourceId
    }
    routingWeight: 0
    enableBgp: false
    useLocalAzureIpAddress: false
    usePolicyBasedTrafficSelectors: false
  }
}

// Outputs
output expressRouteCircuitId string = expressRouteCircuit.outputs.resourceId
output expressRouteCircuitName string = expressRouteCircuit.outputs.name
output expressRouteCircuitServiceKey string = expressRouteCircuit.outputs.serviceKey
output expressRouteCircuitProvisioningState string = expressRouteCircuit.outputs.serviceProviderProvisioningState
output connectionId string = connection.id
output connectionName string = connection.name

// Note: After deployment, provide the service key to your service provider to complete the provisioning process
// The ExpressRoute circuit will remain in 'NotProvisioned' state until your provider completes the provisioning
