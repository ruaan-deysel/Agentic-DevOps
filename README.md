# Agentic DevOps - AI-Assisted Azure Infrastructure as Code Development Container

This repository contains a comprehensive **Agentic DevOps** development container (devcontainer) that combines traditional Infrastructure as Code (IaC) development with AI-powered assistance from GitHub Copilot, Claude, and Augment Code. Designed for Azure IaC development using Bicep, Terraform, Ansible, PowerShell, and CI/CD pipelines (Azure Pipelines/GitHub Actions), this container enables AI-assisted development workflows while maintaining human oversight, security, and compliance standards.

## What is Agentic DevOps?

**Agentic DevOps** is an AI-assisted approach to infrastructure as code development that leverages AI agents to enhance productivity, quality, and innovation:

- **🤖 AI-Accelerated Development**: Generate infrastructure code from natural language descriptions
- **🔍 AI-Powered Code Review**: Identify security issues, compliance violations, and best practice deviations
- **✅ Automated Testing**: AI generates comprehensive test cases and validation scripts
- **📚 Intelligent Documentation**: AI maintains up-to-date documentation and inline comments
- **🎓 Continuous Learning**: AI provides real-time guidance and best practice recommendations

**Key Principle**: AI agents are **assistants**, not replacements. Human expertise validates, reviews, and approves all AI-generated code.

### AI Tools Stack

This development container is optimized for three AI assistants:

| AI Tool | Role | Use Cases |
|---------|------|-----------|
| **GitHub Copilot** | Real-time code completion | Writing Bicep/Terraform modules, generating tests, creating documentation |
| **Claude (Anthropic)** | Complex reasoning & design | Infrastructure architecture planning, security analysis, refactoring guidance |
| **Augment Code** | Codebase-aware assistant | Large-scale refactoring, cross-file changes, systematic task-based workflows |

### Benefits of AI-Assisted IaC Development

✅ **Faster Development**: Generate boilerplate code and modules in seconds
✅ **Higher Quality**: AI identifies issues before deployment
✅ **Better Security**: Automated security scanning with AI-powered remediation suggestions
✅ **Improved Learning**: AI explains best practices and provides context-aware guidance
✅ **Consistent Standards**: AI enforces organizational naming conventions and patterns
✅ **Reduced Errors**: AI catches common mistakes and edge cases

## Features

The Agentic DevOps development container includes the following tools and features:

### Infrastructure as Code Tools

- **Bicep CLI (Latest)** - Azure-native domain-specific language for deploying Azure resources
- **Terraform 1.9.8** - Multi-cloud infrastructure as code tool with Azure provider support
- **Ansible (Latest)** - Configuration management and automation platform
- **Azure CLI (Latest)** - Command-line interface for Azure with extensions (application-insights, log-analytics)
- **PowerShell 7.5.1** - Cross-platform automation and configuration tool

### Kubernetes & Container Tools

- **kubectl (Latest)** - Kubernetes command-line tool for AKS management
- **Helm 3.16.3** - Kubernetes package manager for AKS deployments
- **k9s 0.32.7** - Terminal-based UI for Kubernetes cluster management

### Security & Compliance Tools

- **Trivy 0.58.1** - Comprehensive security scanner (includes tfsec functionality)
- **Checkov (Latest)** - Infrastructure as Code security scanning
- **Gitleaks 8.21.2** - Secret detection to prevent credential leaks
- **Pre-commit (Latest)** - Git hooks framework for enforcing quality gates

### Code Quality & Validation Tools

- **yamllint (Latest)** - YAML linter for pipeline and manifest validation
- **shellcheck (Latest)** - Shell script static analysis
- **ansible-lint (Latest)** - Ansible playbook linting

### DevOps Utilities

- **jq (Latest)** - JSON processor for parsing Azure CLI outputs
- **yq 4.44.3** - YAML processor for pipeline and manifest manipulation
- **act 0.2.70** - Run GitHub Actions workflows locally for testing
- **git-lfs (Latest)** - Git Large File Storage for Terraform state backups
- **GitHub CLI (Latest)** - Command-line interface for GitHub

### VS Code Extensions (16 Extensions)

**Azure Extensions:**

- Azure Resource Groups
- Bicep language support
- Azure CLI Tools
- Azure MCP Server
- Microsoft Terraform

**IaC Extensions:**

- HashiCorp Terraform
- Red Hat Ansible

**Kubernetes Extensions:**

- Kubernetes Tools

**Language Extensions:**

- PowerShell
- YAML language support

**DevOps Extensions:**

- GitHub Actions
- Azure Pipelines

**Code Quality Extensions:**

- ShellCheck linter
- Markdown linter
- Prettier formatter
- Indent Rainbow

### Cross-Platform Compatibility

- Works seamlessly on both **macOS** and **Windows** via Docker Desktop
- Uses Microsoft's official Dev Container base image: `ubuntu-24.04` (Latest LTS)
- Architecture-aware installations (x64/ARM64 support)
- Consistent development experience across different operating systems

---

## Agentic DevOps Workflow

This development container supports a complete AI-assisted infrastructure development lifecycle:

### 1. 🎨 Design & Architecture (AI-Assisted)

**Human**: Define requirements, constraints, and business objectives
**AI**: Generate architecture proposals, identify patterns, suggest Azure services

**Example Workflow**:

```
You: "Design an Azure infrastructure for a high-availability web application with:
- Frontend: Static web app with CDN
- Backend: Container-based API on AKS
- Database: Cosmos DB with multi-region replication
- Security: Private endpoints, managed identities, Key Vault
- Monitoring: Application Insights, Log Analytics

Generate Bicep module structure following Azure Verified Modules patterns."

AI: [Generates architecture diagram and Bicep module structure]

You: [Review, refine, and approve architecture]
```

### 2. 💻 Implementation (AI-Accelerated)

**Human**: Review generated code, validate against requirements, customize for specific needs
**AI**: Generate Bicep/Terraform modules, implement security controls, create parameter files

**Example Workflow**:

```
You: "Create a Bicep module for Azure Storage Account with:
- Private endpoints enabled
- Encryption at rest with customer-managed keys
- Network rules: deny public access, allow Azure services
- Diagnostic settings to Log Analytics
- RBAC: Blob Data Contributor for managed identity
- Follow naming convention: st-{workload}-{env}-{region}-{instance}"

AI: [Generates complete Bicep module with security controls]

You: [Review code, validate security settings, test deployment]
```

### 3. ✅ Testing & Validation (AI-Generated)

**Human**: Define test scenarios, validate test coverage, approve test results
**AI**: Generate test cases, create validation scripts, identify edge cases

**Example Workflow**:

```
You: "Generate comprehensive tests for the storage account module:
- Pester tests for parameter validation
- Security tests: verify private endpoints, encryption, network rules
- Compliance tests: check naming convention, required tags
- Integration tests: deploy to test environment and validate"

AI: [Generates complete test suite]

You: [Run tests, review coverage, add domain-specific tests]
```

### 4. 🔒 Security & Compliance Review (AI-Powered)

**Human**: Approve security controls, validate compliance requirements
**AI**: Scan for vulnerabilities, check compliance, suggest improvements

**Example Workflow**:

```bash
# AI-assisted security scanning
gitleaks detect --source . --verbose  # Scan for secrets
trivy config .                        # Scan for security issues
checkov -d .                          # Scan for compliance violations

# AI analyzes results and suggests fixes
You: "Review this Terraform configuration for security issues"
AI: [Identifies issues, provides specific remediation steps]
You: [Review findings, prioritize remediation, apply fixes]
```

### 5. 🚀 Deployment & Monitoring (AI-Assisted)

**Human**: Approve deployment plan, monitor deployment, validate results
**AI**: Generate deployment scripts, create monitoring dashboards, analyze logs

**Example Workflow**:

```
You: "Create deployment automation for the infrastructure:
- Generate Azure Pipeline YAML for Bicep deployment
- Include what-if validation step
- Add approval gate before production
- Create rollback procedure
- Generate KQL queries for monitoring deployment health"

AI: [Generates complete CI/CD pipeline with monitoring]

You: [Review pipeline, approve deployment, monitor results]
```

### AI-Assisted Development Best Practices

**DO** ✅:

- Provide clear context and requirements to AI
- Validate all AI-generated code before deployment
- Iterate and refine AI output through feedback
- Use AI explanations to improve your understanding
- Test AI-generated code thoroughly
- Review security implications of AI suggestions

**DON'T** ❌:

- Blindly deploy AI-generated code without review
- Skip validation, linting, or security scanning
- Ignore security scanner warnings
- Let AI replace critical thinking
- Assume AI knows your specific requirements
- Compromise security for speed

---

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

The development container is built on:

- **Base Image**: `mcr.microsoft.com/devcontainers/base:ubuntu-24.04` (Latest Ubuntu LTS)
- **Architecture Support**: Automatic detection and installation for x64 and ARM64 architectures
- **Tool Installation**: All tools installed in Dockerfile with version pinning for reproducibility
- **Post-Creation Scripts**: Automated setup of Azure CLI extensions, bash aliases, and PowerShell profile

This approach ensures a consistent, reproducible development environment regardless of your host operating system.

## VS Code Configuration

The repository includes comprehensive VS Code workspace settings optimized for Azure IaC development:

### Workspace Settings (`.vscode/settings.json`)

**260+ lines of configuration** organized into 12 categories:

1. **General Editor Settings** - Format on save, tab sizes, rulers
2. **Editor Visual Enhancements** - Bracket colorization, indent guides, minimap
3. **File Settings** - File associations, exclusions, whitespace handling
4. **Bicep Settings** - Auto-formatting with Bicep extension
5. **Terraform Settings** - Language server, validation on save, code lens
6. **YAML Settings** - Schema validation for Azure Pipelines, GitHub Actions, Kubernetes
7. **Ansible Settings** - Playbook validation and linting
8. **PowerShell Settings** - Script analysis, OTBS formatting
9. **JSON Settings** - Prettier formatting for config files
10. **Markdown Settings** - Linting with relaxed rules for documentation
11. **Shell Script Settings** - ShellCheck integration
12. **Prettier, Git, Search, Workbench, Terminal Settings**

### Language-Specific Formatters

Each language is configured with its optimal formatter:

- **Bicep**: `ms-azuretools.vscode-bicep` - Official Bicep formatter
- **Terraform**: `hashicorp.terraform` - Official Terraform formatter with language server
- **YAML**: `redhat.vscode-yaml` - Schema-aware YAML formatting
- **PowerShell**: `ms-vscode.powershell` - PowerShell script analysis and formatting
- **JSON/JSONC**: `esbenp.prettier-vscode` - Consistent JSON formatting
- **Markdown**: `DavidAnson.vscode-markdownlint` - Markdown linting and formatting
- **Ansible**: `redhat.ansible` - Ansible playbook formatting

### YAML Schema Support

Automatic IntelliSense and validation for:

- **Azure Pipelines** - `azure-pipelines.yml`, `azure-pipelines.yaml`
- **GitHub Actions** - `.github/workflows/*.yml`
- **Kubernetes Manifests** - `k8s/*.yaml`, `kubernetes/*.yaml`
- **CloudFormation/ARM Tags** - Custom tag support for IaC templates

### Terraform Language Server Features

The Terraform extension provides:

- **Validate on Save** - Real-time validation of Terraform files
- **Prefill Required Fields** - Auto-completion for required resource properties
- **Code Lens** - Shows reference counts for resources
- **IntelliSense** - Auto-completion for Azure provider resources

### Code Quality Features

- **Format on Save** - Automatic formatting for all supported languages
- **Trailing Whitespace Removal** - Keeps files clean
- **Final Newline Insertion** - POSIX compliance
- **ShellCheck on Save** - Real-time shell script linting
- **Bracket Pair Colorization** - Better code readability
- **Indent Guides** - Visual indentation for nested structures

### Authentication

When using the container, you'll need to set up your credentials:

1. **Azure**: Run `az login` in the terminal to authenticate with your Azure account
2. **GitHub**: Run `gh auth login` in the terminal to authenticate with GitHub
3. **Azure Pipelines** (if using): Run `az devops login` in the terminal
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

The container includes comprehensive tools for testing and validating your infrastructure code:

### Bicep Testing & Validation

```bash
# Build and lint Bicep template
az bicep build --file main.bicep
az bicep lint --file main.bicep

# Validate deployment
az deployment sub validate --template-file main.bicep --parameters main.bicepparam

# Preview deployment changes with What-If
az deployment sub what-if --template-file main.bicep --parameters main.bicepparam

# Deploy
az deployment sub create --template-file main.bicep --parameters main.bicepparam
```

### Terraform Testing & Validation

```bash
# Format code
terraform fmt -recursive

# Validate configuration
terraform validate

# Plan deployment
terraform plan -var-file="dev.tfvars" -out=tfplan

# Apply changes
terraform apply tfplan
```

### Security Scanning

```bash
# Scan for secrets (MANDATORY before every commit)
gitleaks detect --source . --verbose
gitleaks protect --verbose --staged

# Scan Bicep for security issues
trivy config ./bicep
checkov -d ./bicep

# Scan Terraform for security issues
trivy config ./terraform
checkov -d ./terraform

# Scan Kubernetes manifests
trivy config k8s/
checkov -d k8s/
```

### YAML Validation

```bash
# Validate all YAML files
yamllint .

# Validate specific files
yamllint azure-pipelines.yml
yamllint .github/workflows/*.yml
yamllint k8s/*.yaml
```

### Shell Script Validation

```bash
# Validate shell scripts
shellcheck scripts/*.sh
shellcheck .devcontainer/scripts/*.sh

# Validate with specific shell
shellcheck --shell=bash script.sh
```

### Kubernetes Validation (for AKS deployments)

```bash
# Validate Kubernetes manifests
kubectl apply --dry-run=client -f manifest.yaml
kubectl apply --dry-run=server -f manifest.yaml
kubectl diff -f manifest.yaml

# Validate Helm charts
helm lint charts/my-app
helm template charts/my-app | kubectl apply --dry-run=client -f -
```

### Pre-Commit Hooks (Automated Quality Gates)

```bash
# Install pre-commit hooks (one-time setup)
pre-commit install

# Run hooks manually on all files
pre-commit run --all-files

# Hooks automatically run before each commit to enforce:
# - Code formatting (terraform fmt, bicep build)
# - Linting (yamllint, shellcheck)
# - Security scanning (gitleaks)
# - Validation checks
```

## Best Practices

When working with this devcontainer:

### Infrastructure as Code

1. **Version Control** - Store all infrastructure code in Git with meaningful commit messages
2. **Modular Design** - Use reusable modules for Bicep and Terraform
3. **Configuration-Driven** - Separate configuration from code using parameter/variable files
4. **Environment Separation** - Maintain separate configurations for dev, test, and prod
5. **Naming Conventions** - Follow Azure naming standards (see `.augment/rules/azure-naming.md`)

### Security & Compliance

1. **Secret Management** - Never hardcode secrets; use Azure Key Vault
2. **Pre-Commit Scanning** - Run `gitleaks` before every commit to prevent credential leaks
3. **Security Scanning** - Run `trivy` and `checkov` on all IaC code
4. **Least Privilege** - Use Managed Identities and RBAC for Azure authentication
5. **Encryption** - Enable encryption at rest and in transit for all resources

### Testing & Validation

1. **Format Before Commit** - Run formatters (`terraform fmt`, `az bicep build`) before committing
2. **Validate Syntax** - Run validation (`terraform validate`, `az bicep lint`) on all changes
3. **Plan Before Deploy** - Always review `terraform plan` or `az deployment what-if` output
4. **Test Locally** - Use `act` to test GitHub Actions workflows locally
5. **Dry-Run Kubernetes** - Use `kubectl apply --dry-run` before deploying to AKS

### Code Quality

1. **Pre-Commit Hooks** - Install and use pre-commit hooks for automated quality gates
2. **YAML Linting** - Validate all YAML files with `yamllint`
3. **Shell Script Linting** - Validate all shell scripts with `shellcheck`
4. **Documentation** - Keep README and inline comments up to date
5. **Task-Based Workflow** - Break complex work into small, testable tasks

### Development Workflow

1. **Format on Save** - VS Code is configured to auto-format on save
2. **Real-Time Validation** - Terraform and YAML files validate as you type
3. **IntelliSense** - Use schema-based auto-completion for Azure Pipelines and Kubernetes
4. **Git Auto-Fetch** - Stay updated with remote changes automatically
5. **Bracket Colorization** - Use visual aids for better code readability

## Rebuilding the Development Container

If you update the devcontainer configuration, you'll need to rebuild:

### When to Rebuild

Rebuild the container when you:

- Modify `.devcontainer/Dockerfile`
- Update `.devcontainer/devcontainer.json` (features, extensions, settings)
- Change `.devcontainer/scripts/post-create.sh`
- Update tool versions or add new tools

### How to Rebuild

**Option 1: Command Palette (Recommended)**

1. Press `F1` or `Cmd/Ctrl+Shift+P` to open Command Palette
2. Type "Dev Containers: Rebuild Container"
3. Select "Dev Containers: Rebuild Container" (rebuilds and reopens)
4. Wait for rebuild to complete (may take several minutes)

**Option 2: Rebuild Without Cache**

1. Press `F1` or `Cmd/Ctrl+Shift+P`
2. Type "Dev Containers: Rebuild Container Without Cache"
3. Select the option (useful if experiencing issues)

**Option 3: Manual Rebuild**

```bash
# From outside the container
docker-compose -f .devcontainer/docker-compose.yml build --no-cache
```

### Verifying the Rebuild

After rebuilding, verify tools are installed correctly:

```bash
# Check tool versions
az --version
bicep --version
terraform --version
ansible --version
pwsh --version
kubectl version --client
helm version
k9s version
trivy --version
gitleaks version
yq --version
```

## Customization

You can customize the devcontainer by modifying:

### Dockerfile (`.devcontainer/Dockerfile`)

- Add or update tool versions
- Install additional packages
- Modify base image

### DevContainer Configuration (`.devcontainer/devcontainer.json`)

- Add or remove VS Code extensions
- Configure container settings
- Set environment variables
- Modify port forwarding

### Post-Creation Script (`.devcontainer/scripts/post-create.sh`)

- Add Azure CLI extensions
- Configure bash aliases
- Set up PowerShell profile
- Initialize tools

### VS Code Settings (`.vscode/settings.json`)

- Customize editor preferences
- Modify language-specific formatters
- Adjust linting rules
- Configure YAML schemas

## Troubleshooting

### Container Build Fails

- **Clear Docker cache**: Rebuild without cache
- **Check Docker resources**: Ensure Docker Desktop has sufficient memory (8GB+ recommended)
- **Verify network**: Some tools require internet access during build

### Tool Not Found

- **Rebuild container**: Tools are installed during container build
- **Check PATH**: Verify tool is in PATH with `which <tool-name>`
- **Check architecture**: Some tools have different binaries for x64 vs ARM64

### VS Code Extension Issues

- **Reload window**: Press `F1` → "Developer: Reload Window"
- **Reinstall extensions**: Rebuild container to reinstall all extensions
- **Check extension compatibility**: Ensure extensions support remote containers

### Authentication Issues

- **Azure CLI**: Run `az login` and `az account set --subscription <id>`
- **GitHub CLI**: Run `gh auth login`
- **Git**: Configure `git config --global user.name` and `user.email`

## Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test in the devcontainer
5. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.
