# SAW ExpressRoute Circuit Deployment

This project contains Bicep templates for deploying and configuring ExpressRoute circuits for the SAW environment.

## Overview

The SAW ExpressRoute project provides a standardized approach to deploying and managing ExpressRoute circuits across different environments. It uses Bicep templates to ensure best practices and consistency.

## Project Structure

```text
SAW/
├── config/                     # Configuration files
│   └── ms.expressroute/        # ExpressRoute-specific configuration
│       └── parameters.bicepparam # Parameter file for ExpressRoute circuit
├── pipelines/                  # Azure DevOps pipeline definitions
│   ├── expressroute-deployment.yml # Pipeline for deploying ExpressRoute circuits
│   ├── variable-group-template.json # Template for pipeline variable group
│   └── README.md               # Pipeline documentation
├── scripts/                    # Deployment and utility scripts
│   ├── Deploy-ExpressRoute.ps1 # Script for deploying ExpressRoute circuit
│   └── Test-BicepTemplates.ps1 # Script for validating Bicep templates
├── main.bicep                  # Main Bicep template for ExpressRoute circuit
└── README.md                   # This file
```

## Features

- Deployment of ExpressRoute circuits with specified bandwidth, SKU, and peering location
- Connection to existing virtual network gateways
- Standardized tagging for resource management

## Getting Started

### Prerequisites

- Azure subscription
- Existing virtual network gateway
- One of the following options:
  - Azure CLI with Bicep installed
  - PowerShell with Az module and Bicep installed
  - Azure DevOps for pipeline-based deployment

### Deployment

You can deploy the ExpressRoute circuit using one of the following methods:

#### Using Azure CLI

```bash
az deployment group create \
  --resource-group SAW-AE-PLT-CON-NET-RG001 \
  --template-file main.bicep \
  --parameters @config/ms.expressroute/parameters.bicepparam
```

#### Using PowerShell

```powershell
New-AzResourceGroupDeployment `
  -ResourceGroupName SAW-AE-PLT-CON-NET-RG001 `
  -TemplateFile main.bicep `
  -TemplateParameterFile config/ms.expressroute/parameters.bicepparam
```

#### Using the Deployment Script

```powershell
./scripts/Deploy-ExpressRoute.ps1
```

#### Using Azure DevOps Pipeline

The repository includes an Azure DevOps pipeline for automated deployment. See the [Pipeline Documentation](pipelines/README.md) for details on setting up and using the pipeline.

## Configuration

### ExpressRoute Circuit Parameters

The parameter file `config/ms.expressroute/parameters.bicepparam` contains the following configuration:

- **circuitName**: The name of the ExpressRoute circuit (SAW-ER-CIRCUIT-AUSTRALIA-EAST-BACKUP)
- **location**: The Azure region for the circuit (Australia East)
- **peeringLocation**: The peering location (Sydney)
- **bandwidthInMbps**: The bandwidth of the circuit (50 Mbps)
- **skuTier**: The SKU tier (Standard)
- **skuFamily**: The SKU family (MeteredData)
- **serviceProviderName**: The service provider (Equinix)
- **virtualNetworkGatewayId**: The ID of the existing virtual network gateway to connect to
- **tags**: Resource tags for management and organization

## Post-Deployment Steps

After deploying the ExpressRoute circuit, you will need to:

1. Provide the service key to your service provider to complete the provisioning process
2. Configure BGP peering for the ExpressRoute circuit
3. Verify connectivity through the ExpressRoute circuit

## Monitoring and Management

You can monitor the ExpressRoute circuit using Azure Monitor and Azure Network Watcher. Key metrics to monitor include:

- Circuit availability
- Bandwidth utilization
- BGP availability
- Packet drops

## Troubleshooting

Common issues and their solutions:

- **Circuit Provisioning Stuck**: Contact your service provider with the service key
- **Connection Issues**: Verify BGP configuration and network security groups
- **Bandwidth Limitations**: Check for throttling or consider upgrading the circuit bandwidth
