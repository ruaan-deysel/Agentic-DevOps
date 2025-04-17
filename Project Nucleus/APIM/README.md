# Nucleus APIM

This repository contains the infrastructure as code (IaC) for deploying and configuring Azure API Management (APIM) using Bicep templates and Azure DevOps pipelines.

## Overview

The Nucleus APIM project provides a standardized approach to deploying and managing Azure API Management instances across different environments (dev, test, prod). It uses Azure Verified Modules (AVM) to ensure best practices and consistency.

## Features

- Automated deployment of Azure API Management using Bicep templates
- Environment-specific configuration (dev, test, prod)
- Integration with Azure Verified Modules (AVM)
- Automated API import from Swagger/OpenAPI definitions
- Policy management across different scopes (global, product, API, operation)
- Comprehensive logging and diagnostics
- CI/CD pipeline for automated deployment

## Repository Structure

```text
├── .devcontainer/              # Dev container configuration
│   ├── devcontainer.json       # Dev container settings
│   ├── Dockerfile              # Container image definition
│   ├── setup.ps1               # Container setup script
│   └── README.md               # Dev container documentation
├── config/                     # Configuration files
│   └── ms.apim/               # APIM-specific configuration
│       ├── parameters.dev.bicepparam # Development environment parameters
│       ├── parameters.test.bicepparam # Test environment parameters
│       └── parameters.prod.bicepparam # Production environment parameters
├── pl/                         # Pipeline definitions
│   └── ms.apim/               # APIM-specific pipelines
│       └── azure-pipelines.yml # Azure DevOps pipeline definition
├── scripts/                    # Deployment and utility scripts
│   ├── Post-DeploymentConfiguration.ps1 # Post-deployment configuration script
│   ├── Test-BicepTemplates.ps1 # Bicep template testing script
│   ├── Test-LocalDeployment.ps1 # Local deployment testing script
│   ├── Run-Tests.ps1           # Run all tests script
│   ├── Backup-ApiManagement.ps1 # Backup API Management script
│   ├── Restore-ApiManagement.ps1 # Restore API Management script
│   ├── Set-ApimCustomDomains.ps1 # Configure custom domains script
│   ├── Test-ApiEndpoints.ps1 # Test API endpoints script
│   ├── Customize-DeveloperPortal.ps1 # Customize developer portal script
│   ├── Secure-ApiManagement.ps1 # Security hardening script
│   └── Set-ApimMonitoring.ps1 # Monitoring and alerting script
├── apis/                       # API definitions (optional)
│   └── *.json                  # Swagger/OpenAPI definition files
├── policies/                   # API Management policies (optional)
│   ├── global/                 # Global policies
│   ├── products/               # Product-level policies
│   ├── apis/                   # API-level policies
│   └── operations/             # Operation-level policies
├── portal-customizations/      # Developer portal customizations
│   ├── styles.css              # Custom CSS styles
│   └── pages/                  # Custom portal pages
├── tests/                      # Test configurations
│   ├── api-tests.json          # API test definitions
│   ├── Bicep.Tests.ps1         # Unit tests for Bicep templates
│   └── ARM.Tests.ps1           # Unit tests for ARM templates
├── main.bicep                  # Main Bicep template
└── README.md                   # This file
```

## Getting Started

### Prerequisites

- Azure subscription
- One of the following options:

  **Option 1: Dev Container (Recommended)**
  - Docker Desktop
  - Visual Studio Code with Remote - Containers extension
  - Git

  **Option 2: Local Installation**
  - Azure CLI
  - PowerShell 7.0 or later
  - Bicep CLI

### Development Environment

#### Using Dev Container (Recommended)

This project includes a lightweight dev container configuration that provides a consistent development environment with all required tools pre-installed. The container is optimized for size (~300MB) to ensure fast downloads and minimal disk usage.

1. **Prerequisites**:
   - Docker Desktop
   - Visual Studio Code with Remote - Containers extension
   - Git

2. **Getting Started**:

   ```bash
   # Clone the repository
   git clone https://github.com/domalab/Nucleus-APIM.git
   cd Nucleus-APIM

   # Open in VS Code
   code .
   ```

3. When prompted, click "Reopen in Container" or use the command palette (F1) and select "Remote-Containers: Reopen in Container"

4. The container will build and initialize with all required tools:
   - Azure CLI with Bicep extension (pre-installed in base image)
   - PowerShell Core (minimal installation)
   - Essential Azure PowerShell modules
   - Pester for testing
   - Required VS Code extensions

5. **Authentication**:

   ```bash
   # Login to Azure
   az login --use-device-code
   ```

For more details, see the [Dev Container README](.devcontainer/README.md).

#### Local Installation

If you prefer not to use the dev container, you'll need to install the following tools manually:

1. **Required Tools**:
   - Azure CLI: [Installation Guide](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli)
   - PowerShell 7.0+: [Installation Guide](https://docs.microsoft.com/en-us/powershell/scripting/install/installing-powershell)
   - Bicep CLI: `az bicep install`

2. **Required PowerShell Modules**:

   ```powershell
   Install-Module -Name Az.ApiManagement, Az.Resources -Force
   Install-Module -Name Pester -Force -SkipPublisherCheck -MinimumVersion 5.0.0
   ```

3. **Required CLI Extensions**:

   ```bash
   az extension add --name azure-devops
   ```

### Testing

This project includes several testing options to ensure your templates and deployments work correctly.

#### Unit Testing

Run the unit tests to validate your Bicep templates and ARM templates without deploying any resources:

```powershell
# Run all tests
./scripts/Run-Tests.ps1

# Run only Bicep tests
./scripts/Run-Tests.ps1 -SkipARMTests -SkipDeploymentTests

# Run only ARM tests
./scripts/Run-Tests.ps1 -SkipBicepTests -SkipDeploymentTests

# Test a specific environment
./scripts/Run-Tests.ps1 -Environment prod
```

The unit tests validate:

1. Bicep template syntax and structure
2. Parameter validation
3. Resource configuration
4. Security compliance
5. Best practices

#### API Testing

Test your API endpoints after deployment:

```powershell
# Run API tests with default settings
./scripts/Run-ApiTests.ps1

# Run API tests with specific gateway URL and subscription key
./scripts/Run-ApiTests.ps1 -ApimGatewayUrl "https://apim-nucleus-dev.azure-api.net" -SubscriptionKey "your-subscription-key"

# Run API tests with detailed output
./scripts/Run-ApiTests.ps1 -DetailedOutput
```

API tests are defined in the `tests/api-tests.json` file. You can add, modify, or remove tests as needed.

#### Local Deployment Testing

To test the solution locally before deploying to your actual environments, use the provided test script:

```powershell
# Test with default settings (dev environment)
./scripts/Test-LocalDeployment.ps1

# Test with specific environment
./scripts/Test-LocalDeployment.ps1 -Environment test

# Test with custom resource group name
./scripts/Test-LocalDeployment.ps1 -ResourceGroupName "rg-my-test-apim"

# Run validation and what-if analysis without actual deployment
./scripts/Test-LocalDeployment.ps1 -WhatIf

# Skip post-deployment configuration
./scripts/Test-LocalDeployment.ps1 -SkipPostDeployment
```

The deployment test script will:

1. Verify prerequisites (Azure CLI, Bicep)
2. Create a resource group if it doesn't exist
3. Validate the Bicep template
4. Run a what-if analysis to show what would be deployed
5. Deploy the resources (unless `-WhatIf` or `-SkipDeployment` is specified)
6. Run the post-deployment configuration (unless `-SkipPostDeployment` is specified)

### Deployment

1. Clone this repository
2. Update the parameters files in `config/ms.apim/` for your environment
3. Run the deployment using Azure CLI:

```bash
# Set variables
resourceGroupName="rg-nucleus-apim-dev"
environment="dev"

# Create resource group if it doesn't exist
az group create --name $resourceGroupName --location eastus

# Deploy the Bicep template
az deployment group create \
  --resource-group $resourceGroupName \
  --template-file main.bicep \
  --parameters @config/ms.apim/parameters.$environment.bicepparam
```

Alternatively, use the Azure DevOps pipeline for automated deployment:

1. Create a service connection in Azure DevOps named `azure-service-connection`
2. Create a pipeline using the YAML file at `pl/ms.apim/azure-pipelines.yml`
3. Run the pipeline, selecting the appropriate environment parameter

## Configuration

### Environment Parameters

Each environment has its own parameter file in `config/ms.apim/`:

- `parameters.dev.json`: Development environment
- `parameters.test.json`: Test environment
- `parameters.prod.json`: Production environment

### API Import

To import APIs automatically during deployment:

1. Place your Swagger/OpenAPI definition files in the `apis/` directory
2. The post-deployment script will automatically import these APIs

### Policy Management

To apply policies to your API Management instance:

1. Create XML policy files in the appropriate subdirectory under `policies/`:
   - `global/`: Global policies
   - `products/`: Product-level policies (filename should match product ID)
   - `apis/`: API-level policies (filename should match API ID)
   - `operations/`: Operation-level policies (filename format: `apiId_operationId.xml`)

2. The post-deployment script will automatically apply these policies

## Additional Features

### Backup and Restore

The repository includes scripts for backing up and restoring your API Management instance:

```bash
# Backup API Management
./scripts/Backup-ApiManagement.ps1 -ResourceGroup "rg-nucleus-apim-dev" -ApimServiceName "apim-nucleus-dev" -StorageAccountName "stanucleusbackup" -StorageContainerName "apim-backups"

# Restore API Management
./scripts/Restore-ApiManagement.ps1 -ResourceGroup "rg-nucleus-apim-dev" -ApimServiceName "apim-nucleus-dev" -StorageAccountName "stanucleusbackup" -StorageContainerName "apim-backups" -BackupName "apim-backup-20230101-120000"
```

### Custom Domains

Configure custom domains for your API Management instance:

```bash
./scripts/Set-ApimCustomDomains.ps1 -ResourceGroup "rg-nucleus-apim-dev" -ApimServiceName "apim-nucleus-dev" -KeyVaultName "kv-nucleus-dev" -GatewayHostname "api.example.com" -PortalHostname "developer.example.com" -CertificateName "wildcard-example-com"
```

### API Endpoint Testing

Test your API endpoints after deployment using the Test-ApiEndpoints script:

```bash
./scripts/Test-ApiEndpoints.ps1 -ApimGatewayUrl "https://apim-nucleus-dev.azure-api.net" -SubscriptionKey "your-subscription-key" -DetailedOutput
```

### Developer Portal Customization

Customize the developer portal with your branding:

```bash
./scripts/Customize-DeveloperPortal.ps1 -ResourceGroup "rg-nucleus-apim-dev" -ApimServiceName "apim-nucleus-dev" -LogoPath "./assets/logo.png" -FaviconPath "./assets/favicon.ico" -OrganizationName "Your Company" -OrganizationWebsite "example.com"
```

### Security Hardening

Apply security best practices to your API Management instance:

```bash
./scripts/Secure-ApiManagement.ps1 -ResourceGroup "rg-nucleus-apim-dev" -ApimServiceName "apim-nucleus-dev"
```

### Monitoring and Alerting

Set up monitoring and alerting for your API Management instance:

```bash
./scripts/Set-ApimMonitoring.ps1 -ResourceGroup "rg-nucleus-apim-dev" -ApimServiceName "apim-nucleus-dev" -LogAnalyticsWorkspaceName "law-nucleus-dev" -ActionGroupName "ag-nucleus-apim" -ActionGroupEmails "admin@example.com,alerts@example.com"
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.
