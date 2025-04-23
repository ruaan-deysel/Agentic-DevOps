# ExpressRoute Deployment Pipeline

This directory contains the Azure DevOps pipeline for deploying ExpressRoute circuits in the SAW environment.

## Pipeline Overview

The `expressroute-deployment.yml` pipeline automates the deployment of ExpressRoute circuits using the Bicep templates in this repository. The pipeline consists of the following stages:

1. **Validate**: Validates the Bicep templates and performs a what-if deployment to check for potential issues
2. **Deploy**: Deploys the ExpressRoute circuit using the validated templates
3. **Post-Deployment Validation**: Checks the status of the deployed resources

## Pipeline Parameters

The pipeline accepts the following parameters:

- **environment**: The deployment environment (default: prod)
- **resourceGroupName**: The resource group to deploy to (default: SAW-AE-PLT-CON-NET-RG001)
- **whatIf**: Whether to perform a what-if deployment without making actual changes (default: false)

## Prerequisites

Before using this pipeline, ensure you have:

1. An Azure DevOps project set up
2. A service connection to the Azure subscription (SAW-PLT-CON-SUB001)
3. Appropriate permissions to deploy resources to the target resource group

## Setting Up the Pipeline

To set up the pipeline in Azure DevOps:

1. Navigate to your Azure DevOps project
2. Go to Pipelines > Pipelines
3. Click "New Pipeline"
4. Select "Azure Repos Git" as the source
5. Select your repository
6. Select "Existing Azure Pipelines YAML file"
7. Select the path to this file: `/Project Nucleus/SAW/pipelines/expressroute-deployment.yml`
8. Click "Continue" and then "Run"

## Running the Pipeline

You can run the pipeline manually or it will be triggered automatically when changes are made to the SAW directory in the main branch.

When running manually, you can specify the following parameters:

- **Environment**: The deployment environment (prod)
- **Resource Group Name**: The target resource group
- **What-If Deployment**: Whether to perform a what-if deployment without making actual changes

## Pipeline Variables

The pipeline uses the following variables:

- **templateFile**: Path to the main Bicep template
- **parameterFile**: Path to the parameter file
- **azureServiceConnection**: Name of the Azure service connection to use

## Service Connection

The pipeline uses a service connection named `SAW-PLT-CON-SUB001-ServiceConnection` to authenticate with Azure. Ensure this service connection exists in your Azure DevOps project and has the necessary permissions to deploy resources to the target resource group.

## Deployment Approval

The pipeline is configured to require approval before deploying to the production environment. This ensures that changes are reviewed before being applied to production resources.

## Post-Deployment

After the pipeline completes successfully, it will output the ExpressRoute circuit service key. This key needs to be provided to your service provider to complete the provisioning process.
