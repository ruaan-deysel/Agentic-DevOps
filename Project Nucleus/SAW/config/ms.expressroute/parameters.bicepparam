using '../../main.bicep'

// ExpressRoute Circuit Parameters for SAW Backup Circuit
// These parameters are used to deploy a new ExpressRoute circuit in Australia East

// Circuit details
param circuitName = 'SAW-ER-CIRCUIT-AUSTRALIA-EAST-BACKUP'
param location = 'Australia East'
param peeringLocation = 'Sydney'
param bandwidthInMbps = 50
param skuTier = 'Standard'
param skuFamily = 'MeteredData'
param serviceProviderName = 'Megaport'

// Existing virtual network gateway details
// These parameters identify the existing virtual network gateway to connect to
param gatewayResourceGroupName = 'SAW-AE-PLT-CON-NET-RG001'
param gatewayName = 'SAW-AE-PLT-CON-VGW001'

// Private peering configuration
// Set to true if you want to configure private peering during deployment
param configurePrivatePeering = false

// Private peering parameters (only used if configurePrivatePeering is true)
// These are default values and should be changed based on your network requirements
param peerASN = 65001
param primaryPeerAddressPrefix = '192.168.10.16/30'
param secondaryPeerAddressPrefix = '192.168.10.20/30'
param vlanId = 100

// Tags for the resources
param tags = {
  Environment: 'Production'
  Project: 'SAW-Network'
  Subscription: 'SAW-PLT-CON-SUB001'
  ResourceGroup: 'SAW-AE-PLT-CON-NET-RG001'
  CreatedBy: 'DXC'
}

// The deployment timestamp will be automatically set by the Bicep template
// param deploymentTimestamp = '2024-07-25' // Uncomment and set if you want to override the default
