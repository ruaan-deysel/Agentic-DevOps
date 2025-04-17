# Azure Kubernetes Service (AKS) Infrastructure as Code

This project contains Bicep templates and scripts for deploying and configuring Azure Kubernetes Service (AKS) clusters.

## Project Structure

```
AKS/
├── config/                     # Configuration files
│   └── ms.aks/                # AKS-specific configuration
│       ├── parameters.dev.bicepparam  # Development environment parameters
│       ├── parameters.test.bicepparam # Test environment parameters
│       └── parameters.prod.bicepparam # Production environment parameters
├── manifests/                  # Kubernetes manifest files
│   └── sample-deployment.yaml  # Sample Kubernetes deployment
├── scripts/                    # Deployment and utility scripts
│   ├── Post-DeploymentConfiguration.ps1 # Post-deployment configuration script
│   ├── Test-BicepTemplates.ps1 # Bicep template testing script
│   ├── Test-LocalDeployment.ps1 # Local deployment testing script
│   ├── Run-Tests.ps1           # Run all tests script
│   └── Test-K8sManifests.ps1   # Kubernetes manifest testing script
├── tests/                      # Test files
├── artifacts/                  # Generated artifacts (ARM templates)
├── main.bicep                  # Main Bicep template for AKS
└── README.md                   # This file
```

## Features

- **Multi-environment support**: Development, Test, and Production environments with appropriate configurations
- **Node pool management**: Create and manage multiple node pools with different VM sizes and configurations
- **Workload deployment**: Deploy Kubernetes workloads (Helm charts, manifests) after cluster creation
- **Monitoring**: Enable Azure Monitor for containers
- **Security**: Enable Azure Policy for Kubernetes and RBAC
- **Network integration**: Configure network plugins and policies

## Getting Started

### Prerequisites

- Azure CLI
- PowerShell 7.0 or later
- Bicep CLI
- kubectl
- Helm (for deploying workloads)

### Deployment

To deploy the AKS cluster to a specific environment:

```powershell
# Deploy to development environment
./scripts/Test-LocalDeployment.ps1 -Environment dev

# Deploy to test environment
./scripts/Test-LocalDeployment.ps1 -Environment test

# Deploy to production environment
./scripts/Test-LocalDeployment.ps1 -Environment prod
```

### Testing

This project includes several testing options to ensure your templates and deployments work correctly.

#### Unit Testing

Run the unit tests to validate your Bicep templates and ARM templates without deploying any resources:

```powershell
# Run all tests
./scripts/Run-Tests.ps1

# Run only Bicep tests
./scripts/Run-Tests.ps1 -SkipARMTests -SkipDeploymentTests -SkipK8sTests

# Run only ARM tests
./scripts/Run-Tests.ps1 -SkipBicepTests -SkipDeploymentTests -SkipK8sTests

# Test a specific environment
./scripts/Run-Tests.ps1 -Environment prod
```

The unit tests validate:

1. Bicep template syntax and structure
2. Parameter validation
3. Resource configuration
4. Security compliance
5. Best practices

#### Kubernetes Manifest Testing

Test your Kubernetes manifests:

```powershell
# Run Kubernetes manifest tests
./scripts/Test-K8sManifests.ps1
```

#### Local Deployment Testing

To test the solution locally before deploying to your actual environments, use the provided test script:

```powershell
# Test with default settings (dev environment)
./scripts/Test-LocalDeployment.ps1

# Test with WhatIf mode (no actual deployment)
./scripts/Test-LocalDeployment.ps1 -WhatIf

# Test a specific environment
./scripts/Test-LocalDeployment.ps1 -Environment prod
```

## Configuration

### Environment Parameters

Each environment has its own parameter file in `config/ms.aks/`:

- `parameters.dev.bicepparam`: Development environment
- `parameters.test.bicepparam`: Test environment
- `parameters.prod.bicepparam`: Production environment

### Node Pools

You can configure additional node pools in the parameter files:

```bicep
param nodeGroups = [
  {
    name: 'userpool'
    vmSize: 'Standard_D4s_v3'
    count: 2
    minCount: 2
    maxCount: 5
    enableAutoScaling: true
    mode: 'User'
    osDiskSizeGB: 128
    osType: 'Linux'
    labels: {
      workloadType: 'user-apps'
    }
    taints: []
  }
]
```

### Workloads

You can configure workloads to be deployed after cluster creation:

```bicep
param workloads = [
  {
    name: 'nginx-ingress'
    namespace: 'ingress-basic'
    type: 'helm'
    repository: 'https://kubernetes.github.io/ingress-nginx'
    chart: 'ingress-nginx'
    version: '4.7.1'
    values: {
      controller: {
        replicaCount: 2
      }
    }
  }
]
```

## Contributing

1. Create a feature branch
2. Make your changes
3. Run the tests
4. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.
