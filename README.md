# Azure DevOps - Azure Infrastructure as Code Development Container

This repository contains a lightweight development container (devcontainer) specifically designed for Azure Infrastructure as Code (IaC) development using Bicep, ARM templates, PowerShell, and Azure DevOps/GitHub pipelines. The container is designed to work seamlessly on both macOS and Windows via Docker Desktop.

## Features

The Azure DevOps devcontainer includes the following tools and features:

### Core Tools

- **Azure CLI** - Command-line interface for Azure
- **Bicep CLI** - Domain-specific language for deploying Azure resources
- **PowerShell Core** - Cross-platform automation and configuration tool
- **Azure PowerShell Modules** - PowerShell modules for Azure management
- **Git** - Version control system
- **GitHub CLI** - Command-line interface for GitHub
- **Azure DevOps CLI Extension** - CLI extension for Azure DevOps

### Testing & Validation Tools

- **ARM Template Toolkit (ARM-TTK)** - Validation tool for ARM templates
- **PSRule for Azure** - Rules-based validation for Azure resources
- **Pester** - Testing framework for PowerShell
- **Azure What-If** - Preview deployment changes before applying

### Linting & Analysis Tools

- **PSScriptAnalyzer** - Static code analysis for PowerShell
- **Azure Pipelines Linter** - Validates Azure Pipelines YAML
- **ARM Template Linter** - Validates ARM templates

### VS Code Extensions

- Pre-configured extensions for Azure development, testing, and linting

### Cross-Platform Compatibility

- Works seamlessly on both **macOS** and **Windows** via Docker Desktop
- Uses Microsoft's official Dev Container base image and Features
- Consistent development experience across different operating systems

## Getting Started

### Prerequisites

- [Docker Desktop](https://www.docker.com/products/docker-desktop) for macOS or Windows
- [Visual Studio Code](https://code.visualstudio.com/)
- [VS Code Dev Containers extension](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers)

### Using the Devcontainer

1. Clone this repository to your local machine
2. Open the repository in Visual Studio Code
3. When prompted, click "Reopen in Container" or run the "Dev Containers: Reopen in Container" command from the Command Palette (F1)
4. Wait for the container to build and start (this may take a few minutes the first time)
5. Once the container is running, you can start developing your Azure IaC projects

### How It Works

Azure DevOps uses Microsoft's Dev Container Features to simplify setup:

- **Base Image**: Uses `mcr.microsoft.com/devcontainers/base:ubuntu` which runs on both macOS and Windows
- **Azure CLI Feature**: Installs Azure CLI and Bicep CLI with `installBicep: true`
- **PowerShell Feature**: Installs cross-platform PowerShell Core
- **GitHub CLI Feature**: Installs GitHub CLI for repository management

This approach ensures a consistent development environment regardless of your host operating system.

### Authentication

When using the container, you'll need to set up your credentials:

1. **Azure**: Run `az login` in the terminal to authenticate with your Azure account
2. **GitHub**: Run `gh auth login` in the terminal to authenticate with GitHub
3. **Azure DevOps**: Run `az devops login` in the terminal
4. **Git**: Configure your Git identity with:

   ```bash
   git config --global user.name "Your Name"
   git config --global user.email "your.email@example.com"
   ```

## Customization

You can customize the devcontainer by modifying the following files:

- `.devcontainer/Dockerfile` - Modify the container image
- `.devcontainer/devcontainer.json` - Configure VS Code settings and extensions
- `.devcontainer/scripts/post-create.sh` - Add additional setup steps

## Environment Variables

You can set the following environment variables to configure default Azure settings:

- `AZURE_DEFAULTS_GROUP` - Default resource group
- `AZURE_DEFAULTS_LOCATION` - Default Azure region

## Testing & Validation

The container includes several tools for testing and validating your infrastructure code:

### Bicep & ARM Template Testing

```powershell
# Test a Bicep template with ARM-TTK and PSRule
Test-BicepTemplate -TemplateFile ./examples/storage-account.bicep

# Preview deployment changes with What-If
az deployment group what-if --resource-group myResourceGroup --template-file ./examples/storage-account.json
```

### PowerShell Testing

```powershell
# Analyze a PowerShell script with PSScriptAnalyzer
Test-PowerShellScript -ScriptPath ./examples/deploy-resources.ps1

# Run Pester tests
Invoke-Pester -Path ./examples/deploy-resources.Tests.ps1
```

## Best Practices

When working with this devcontainer:

1. Store your infrastructure code in a version control system
2. Use modular templates and parameter files
3. Implement proper testing before deployment using the included tools
4. Use pipeline variables and secrets for sensitive information
5. Follow the principle of least privilege for service principals
6. Run validation tests before deploying to production
7. Use What-If operations to preview changes
