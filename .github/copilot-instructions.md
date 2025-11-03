# Agentic DevOps - GitHub Copilot Instructions

## 🤖 Agentic DevOps Context

This repository follows **Agentic DevOps** principles - an AI-assisted approach to infrastructure as code development that combines traditional DevOps practices with AI-powered assistance from GitHub Copilot, Claude, and Augment Code.

**Your Role as GitHub Copilot**:

- **Real-time code completion** for Bicep, Terraform, Ansible, PowerShell, YAML
- **Pattern recognition** from existing codebase to suggest consistent implementations
- **Test generation** for infrastructure code validation
- **Documentation generation** with inline comments and README updates
- **Security-aware suggestions** following Azure best practices

**Key Principle**: You are an **assistant**, not a replacement. All generated code must be reviewed, validated, and tested by humans before deployment.

---

## 🚨 MANDATORY: Systematic Task-Based Development Workflow

**ALL development work MUST follow a systematic task-based workflow:**

### Before Starting ANY Work

1. **Create Granular Tasks**:

   - Break down work into small, testable units (30-60 min each)
   - Each task = single, verifiable piece of work
   - Document task dependencies and sequence
   - Include testing tasks for each code task

2. **Task Management Rules**:
   - Work through tasks ONE AT A TIME
   - Mark task as IN_PROGRESS before starting
   - Focus ONLY on current task
   - Test thoroughly after each task
   - Mark COMPLETE only after verification passes
   - NEVER batch multiple tasks before marking complete
   - NEVER skip ahead to next task

### Example Task Breakdown

For new storage account deployment:

1. Create module/wrapper structure
2. Add parameter validation
3. Configure security settings
4. Run lint/fmt (TESTING TASK)
5. Run validate (TESTING TASK)
6. Create parameter file for dev
7. Run plan and review (TESTING TASK)
8. Deploy to dev
9. Verify deployment (TESTING TASK)
10. Update documentation

### Enforcement

- Task-based workflow is NON-NEGOTIABLE
- Code reviews verify task management was used
- PRs must reference completed tasks
- No deployments without documented task completion

---

## � Documentation Standards (MANDATORY)

### ❌ DO NOT Create Unsolicited Documentation Files

**NEVER create these types of files unless explicitly requested by the user:**

#### Summary Files

- `*_SUMMARY.md`
- `IMPLEMENTATION_SUMMARY.md`
- `CHANGES_SUMMARY.md`
- `UPDATE_SUMMARY.md`
- `DEPLOYMENT_SUMMARY.md`
- `MIGRATION_SUMMARY.md`

#### Validation/Verification Files

- `VALIDATION.md`
- `VERIFICATION.md`
- `TESTING_RESULTS.md`
- `CHECKLIST.md`
- `VERIFICATION_STEPS.md`

#### Reference Documentation Files

- `REFERENCE.md`
- `TOOLS_REFERENCE.md`
- `API_REFERENCE.md`
- `COMMANDS_REFERENCE.md`
- `CONFIGURATION_REFERENCE.md`
- `*_REFERENCE.md`

#### Tool/Update Documentation Files

- `TOOLS_REFERENCE_PART2.md`
- `DEVCONTAINER_UPDATES.md`
- `CHANGELOG_DETAILED.md`
- `INSTALLATION_GUIDE.md`
- `SETUP_INSTRUCTIONS.md`

### ✅ What to Do Instead

**Instead of creating new documentation files:**

1. **Use Commit Messages:**

   ```
   feat: add Kubernetes deployment support

   - Added kubectl and Helm to devcontainer
   - Configured k9s for cluster management
   - Updated testing workflow with kubectl validation

   Closes #123
   ```

2. **Update Existing Documentation:**

   - Add to existing README.md
   - Update inline code comments
   - Enhance existing documentation files

3. **Link to Official Documentation:**

   - Reference official tool documentation
   - Use tool's built-in help (`--help`, man pages)
   - Link to Azure documentation

4. **Use PR Descriptions:**
   - Summarize changes in pull request description
   - Include testing results in PR comments
   - Document decisions in PR discussion

### Rationale

**Why this rule exists:**

- Prevents documentation sprawl and repository clutter
- Avoids redundant information that becomes outdated
- Keeps documentation focused and maintainable
- Information is better placed in commit messages, PRs, or existing docs
- Reduces maintenance burden

### Exceptions

**You MAY create documentation files when:**

- User explicitly requests: "Create a TOOLS_REFERENCE.md file"
- User asks for: "I need a summary document"
- User requests: "Generate API reference documentation"

**When in doubt, ASK:**

- "Would you like me to create a separate documentation file, or update the existing README?"
- "Should I add this to the README or create a new guide?"

### Examples

#### ❌ BAD: Creating Unsolicited Documentation

```
User: "Add Terraform support to the project"

Copilot:
1. Adds Terraform to Dockerfile
2. Creates TERRAFORM_SETUP.md          ← WRONG
3. Creates TOOLS_REFERENCE.md          ← WRONG
4. Creates IMPLEMENTATION_SUMMARY.md   ← WRONG
5. Creates VALIDATION_CHECKLIST.md     ← WRONG
```

#### ✅ GOOD: Minimal Documentation Approach

```
User: "Add Terraform support to the project"

Copilot:
1. Adds Terraform to Dockerfile
2. Updates existing README with Terraform section
3. Adds inline comments in Dockerfile
4. Provides summary in commit message
```

---

## �🛠️ DevOps Tools Usage Guidelines

### When to Use Each Tool

#### **Security Scanning (MANDATORY Before Commits)**

```bash
# Run ALL security scans before committing code
gitleaks detect --source . --verbose          # Scan for secrets/credentials
trivy config .                                 # Scan IaC for security issues
checkov -d .                                   # Additional IaC security scan
yamllint .                                     # Validate YAML syntax
shellcheck scripts/*.sh                        # Validate shell scripts
```

**When to use:**

- Before EVERY commit (use pre-commit hooks)
- Before creating pull requests
- As part of CI/CD pipeline validation
- When reviewing code changes

#### **Kubernetes/AKS Development**

```bash
# Validate Kubernetes manifests
kubectl apply --dry-run=client -f manifest.yaml
kubectl diff -f manifest.yaml

# Helm chart development
helm lint charts/my-app                       # Validate chart
helm template charts/my-app                   # Preview rendered templates
helm install --dry-run my-app charts/my-app   # Test installation

# Interactive cluster management
k9s                                            # Launch terminal UI
kubectl get pods -n my-namespace               # List pods
kubectl logs -f pod-name                       # Stream logs
kubectl exec -it pod-name -- /bin/bash         # Shell into pod
```

**When to use:**

- Deploying applications to AKS
- Debugging AKS cluster issues
- Managing Kubernetes resources
- Validating Helm charts before deployment

#### **GitHub Actions Local Testing**

```bash
# List available workflows
act -l

# Run workflow locally (dry run)
act -n

# Run specific workflow
act push

# Run specific job
act -j build
```

**When to use:**

- Testing GitHub Actions workflows before pushing
- Debugging workflow failures locally
- Iterating on CI/CD pipeline changes
- Validating workflow syntax

#### **YAML/JSON Processing**

```bash
# Parse and query YAML files
yq eval '.spec.containers[0].image' deployment.yaml
yq eval '.parameters.location.value' params.bicepparam

# Parse and query JSON files
jq '.resources[] | select(.type=="Microsoft.Storage/storageAccounts")' template.json
az deployment group show -g rg-name -n deployment-name | jq '.properties.outputs'

# Transform YAML to JSON
yq eval -o=json deployment.yaml

# Validate YAML syntax
yamllint azure-pipelines.yml
yamllint .github/workflows/*.yml
```

**When to use:**

- Parsing Azure CLI JSON outputs
- Querying Bicep/ARM template JSON
- Manipulating pipeline YAML files
- Extracting values from configuration files
- Validating YAML syntax before deployment

#### **Pre-commit Hooks (MANDATORY)**

```bash
# Install pre-commit hooks
pre-commit install

# Run hooks manually on all files
pre-commit run --all-files

# Run specific hook
pre-commit run gitleaks --all-files
pre-commit run terraform-fmt --all-files

# Update hooks to latest versions
pre-commit autoupdate
```

**When to use:**

- Set up ONCE per repository clone
- Automatically runs before every commit
- Enforces code quality and security standards
- Prevents committing secrets or malformed code

#### **Git Large File Storage**

```bash
# Track large files
git lfs track "*.tfstate"
git lfs track "*.zip"
git lfs track "*.tar.gz"

# List tracked files
git lfs ls-files

# Pull LFS files
git lfs pull
```

**When to use:**

- Storing Terraform state backups
- Versioning large binary assets
- Managing documentation images/videos
- Storing compiled artifacts

### Tool Integration in Workflows

#### **Pre-Deployment Validation Workflow**

```bash
# 1. Format code
terraform fmt -recursive
bicep build --file main.bicep

# 2. Lint and validate
yamllint .
shellcheck scripts/*.sh
terraform validate
az bicep lint --file main.bicep

# 3. Security scanning
gitleaks detect --source . --verbose
trivy config .
checkov -d .

# 4. Plan deployment
terraform plan -out=tfplan
az deployment group what-if --template-file main.bicep --parameters main.bicepparam

# 5. Review and apply
terraform apply tfplan
az deployment group create --template-file main.bicep --parameters main.bicepparam
```

#### **AKS Deployment Workflow**

```bash
# 1. Validate manifests
kubectl apply --dry-run=client -f k8s/
helm lint charts/my-app

# 2. Security scan
trivy config k8s/
checkov -d k8s/

# 3. Deploy to cluster
kubectl apply -f k8s/
helm upgrade --install my-app charts/my-app

# 4. Verify deployment
kubectl get all -n my-namespace
k9s  # Interactive verification
```

#### **GitHub Actions Development Workflow**

```bash
# 1. Validate workflow syntax
yamllint .github/workflows/deploy.yml

# 2. Test locally
act -n  # Dry run
act push  # Full run

# 3. Commit and push
git add .github/workflows/deploy.yml
git commit -m "feat: add deployment workflow"
git push
```

### Bash Aliases Reference

The dev container includes helpful aliases:

```bash
# Kubernetes
k='kubectl'
kgp='kubectl get pods'
kgs='kubectl get services'
kgd='kubectl get deployments'
kl='kubectl logs'
kx='kubectl exec -it'

# Helm
h='helm'
hls='helm list'
hi='helm install'
hu='helm upgrade'

# Terraform
tf='terraform'
tfi='terraform init'
tfp='terraform plan'
tfa='terraform apply'
tfv='terraform validate'
tff='terraform fmt -recursive'

# Security
gitleaks-scan='gitleaks detect --source . --verbose'
gitleaks-protect='gitleaks protect --verbose --staged'
trivy-scan='trivy config .'
checkov-scan='checkov -d .'

# YAML/JSON
yq-eval='yq eval'
jq-pretty='jq .'
```

### Azure CLI Extensions

The dev container includes monitoring extensions:

```bash
# Query Application Insights
az monitor app-insights query \
  --app <app-id> \
  --analytics-query "requests | summarize count() by bin(timestamp, 1h)"

# Query Log Analytics
az monitor log-analytics query \
  --workspace <workspace-id> \
  --analytics-query "AzureDiagnostics | take 10"
```

---

## 🎯 Critical Rules (ALWAYS Follow)

### 1. ALWAYS Use Azure Verified Modules (AVM)

```bicep
// ✅ CORRECT - Use AVM with specific version
module storageAccount 'br/public:avm/res/storage/storage-account:0.9.0' = {
  name: 'storage-deployment'
  params: {
    name: 'stwebappdeveus001'
    location: 'eastus'
  }
}

// ❌ WRONG - Don't create custom storage modules
resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: 'stwebappdeveus001'
  location: 'eastus'
  // ... custom implementation
}
```

### 2. ALWAYS Use Configuration-Driven Approach

```bicep
// ✅ CORRECT - Parameters from .bicepparam file
@description('Storage account name')
param storageAccountName string

@description('Location for resources')
param location string

@description('Environment name')
@allowed(['dev', 'tst', 'stg', 'prod'])
param environment string

// ❌ WRONG - Hardcoded values
var storageAccountName = 'mystorageaccount123'
var location = 'eastus'
```

### 3. ALWAYS Follow Naming Conventions

```bicep
// Pattern: {resource-type}-{workload}-{environment}-{region}-{instance}

// ✅ CORRECT Examples
var vmName = 'vm-webapp-prod-eus-001'
var vnetName = 'vnet-hub-prod-eus-001'
var kvName = 'kv-webapp-prod-eus-001'
var storageAccountName = 'stwebappprodeus001'  // No hyphens, max 24 chars
var appServiceName = 'app-webapp-prod-eus-001'
var aksName = 'aks-webapp-prod-eus-001'

// ❌ WRONG Examples
var vmName = 'MyVM'
var vnetName = 'vnet1'
var kvName = 'keyvault'
var storageAccountName = 'mystorage'
```

---

## 📋 Standard Patterns

### Storage Account Pattern

```bicep
@description('Workload name')
param workloadName string

@description('Environment')
@allowed(['dev', 'tst', 'stg', 'prod'])
param environment string

@description('Location')
param location string = resourceGroup().location

@description('Tags')
param tags object

// Generate compliant name (no hyphens, lowercase, max 24 chars)
var storageAccountName = 'st${workloadName}${environment}${uniqueString(resourceGroup().id)}'

module storageAccount 'br/public:avm/res/storage/storage-account:0.9.0' = {
  name: 'storage-${workloadName}-deployment'
  params: {
    name: storageAccountName
    location: location
    tags: tags
    skuName: 'Standard_LRS'
    kind: 'StorageV2'
    allowBlobPublicAccess: false
    minimumTlsVersion: 'TLS1_2'
    networkAcls: {
      defaultAction: 'Deny'
      bypass: 'AzureServices'
    }
  }
}

output storageAccountId string = storageAccount.outputs.resourceId
output storageAccountName string = storageAccount.outputs.name
```

### Virtual Network Pattern

```bicep
@description('Workload name')
param workloadName string

@description('Environment')
@allowed(['dev', 'tst', 'stg', 'prod'])
param environment string

@description('Location abbreviation')
param locationAbbr string = 'eus'

@description('Address prefix')
param addressPrefix string

@description('Tags')
param tags object

var vnetName = 'vnet-${workloadName}-${environment}-${locationAbbr}-001'

module virtualNetwork 'br/public:avm/res/network/virtual-network:0.1.0' = {
  name: 'vnet-${workloadName}-deployment'
  params: {
    name: vnetName
    location: location
    tags: tags
    addressPrefixes: [addressPrefix]
    subnets: [
      {
        name: 'snet-app-${environment}-${locationAbbr}-001'
        addressPrefix: cidrSubnet(addressPrefix, 24, 0)
        networkSecurityGroupResourceId: nsgApp.outputs.resourceId
      }
      {
        name: 'snet-data-${environment}-${locationAbbr}-001'
        addressPrefix: cidrSubnet(addressPrefix, 24, 1)
        networkSecurityGroupResourceId: nsgData.outputs.resourceId
      }
    ]
  }
}
```

### Key Vault Pattern

```bicep
@description('Workload name')
param workloadName string

@description('Environment')
@allowed(['dev', 'tst', 'stg', 'prod'])
param environment string

@description('Location abbreviation')
param locationAbbr string = 'eus'

@description('Tags')
param tags object

var keyVaultName = 'kv-${workloadName}-${environment}-${locationAbbr}-001'

module keyVault 'br/public:avm/res/key-vault/vault:0.6.0' = {
  name: 'keyvault-${workloadName}-deployment'
  params: {
    name: keyVaultName
    location: location
    tags: tags
    sku: 'standard'
    enableRbacAuthorization: true
    enablePurgeProtection: true
    enableSoftDelete: true
    softDeleteRetentionInDays: 90
    networkAcls: {
      defaultAction: 'Deny'
      bypass: 'AzureServices'
    }
  }
}

output keyVaultId string = keyVault.outputs.resourceId
output keyVaultName string = keyVault.outputs.name
output keyVaultUri string = keyVault.outputs.uri
```

### AKS Cluster Pattern

```bicep
@description('Cluster name')
param clusterName string

@description('Environment')
@allowed(['dev', 'tst', 'stg', 'prod'])
param environment string

@description('Location abbreviation')
param locationAbbr string = 'eus'

@description('Tags')
param tags object

var aksName = 'aks-${clusterName}-${environment}-${locationAbbr}-001'

module aksCluster 'br/public:avm/res/container-service/managed-cluster:0.1.0' = {
  name: 'aks-${clusterName}-deployment'
  params: {
    name: aksName
    location: location
    tags: tags
    kubernetesVersion: '1.28.0'
    networkPlugin: 'azure'
    networkPolicy: 'azure'
    agentPools: [
      {
        name: 'systempool'
        mode: 'System'
        vmSize: 'Standard_D2s_v3'
        count: 3
        minCount: 3
        maxCount: 5
        enableAutoScaling: true
      }
    ]
  }
}
```

---

## 🏗️ Folder Structure (MANDATORY)

```
your-project/
├── bicep/
│   ├── modules/
│   │   ├── storage-account-wrapper.bicep
│   │   ├── virtual-network-wrapper.bicep
│   │   ├── key-vault-wrapper.bicep
│   │   └── app-service-wrapper.bicep
│   ├── parameters/
│   │   ├── storage-account.dev.bicepparam
│   │   ├── storage-account.prod.bicepparam
│   │   ├── virtual-network.dev.bicepparam
│   │   └── virtual-network.prod.bicepparam
│   └── environments/
│       ├── dev/
│       │   └── main.bicep
│       ├── test/
│       │   └── main.bicep
│       └── prod/
│           └── main.bicep
```

---

## 📝 Parameter File Pattern (.bicepparam)

```bicep
// parameters/storage-account.dev.bicepparam
using '../environments/dev/main.bicep'

param location = 'eastus'
param environment = 'dev'
param workloadName = 'webapp'
param tags = {
  Environment: 'Development'
  ManagedBy: 'Bicep'
  Owner: 'devteam@company.com'
  CostCenter: 'IT-001'
  Project: 'WebApp'
  ApplicationName: 'CustomerPortal'
  DeployedBy: 'AzureDevOps'
}
```

---

## 🏷️ Standard Tags (ALWAYS Apply)

```bicep
@description('Standard tags for all resources')
var standardTags = {
  Environment: environment           // dev, tst, stg, prod
  ManagedBy: 'Bicep'                // IaC tool
  Owner: ownerEmail                 // Owner email
  CostCenter: costCenter            // Cost center code
  Project: projectName              // Project name
  ApplicationName: applicationName  // Application name
  DeployedBy: deployedBy           // Person/pipeline who deployed
  DeployedDate: utcNow()           // Deployment timestamp
}

// Merge with custom tags
var allTags = union(standardTags, customTags)
```

---

## 🔒 Security Defaults (ALWAYS Apply)

```bicep
// Storage Account Security
module storageAccount 'br/public:avm/res/storage/storage-account:0.9.0' = {
  name: 'storage-deployment'
  params: {
    name: storageAccountName
    location: location
    allowBlobPublicAccess: false        // ✅ No public access
    minimumTlsVersion: 'TLS1_2'         // ✅ Minimum TLS 1.2
    supportsHttpsTrafficOnly: true      // ✅ HTTPS only
    networkAcls: {
      defaultAction: 'Deny'             // ✅ Deny by default
      bypass: 'AzureServices'
    }
    enableHierarchicalNamespace: false
  }
}

// Key Vault Security
module keyVault 'br/public:avm/res/key-vault/vault:0.6.0' = {
  name: 'keyvault-deployment'
  params: {
    name: keyVaultName
    location: location
    enableRbacAuthorization: true       // ✅ Use RBAC, not access policies
    enablePurgeProtection: true         // ✅ Enable purge protection
    enableSoftDelete: true              // ✅ Enable soft delete
    softDeleteRetentionInDays: 90       // ✅ 90-day retention
    networkAcls: {
      defaultAction: 'Deny'             // ✅ Deny by default
      bypass: 'AzureServices'
    }
  }
}

// Network Security Group
module nsg 'br/public:avm/res/network/network-security-group:0.1.0' = {
  name: 'nsg-deployment'
  params: {
    name: nsgName
    location: location
    securityRules: [
      {
        name: 'DenyAllInbound'
        priority: 4096
        direction: 'Inbound'
        access: 'Deny'
        protocol: '*'
        sourcePortRange: '*'
        destinationPortRange: '*'
        sourceAddressPrefix: '*'
        destinationAddressPrefix: '*'
      }
    ]
  }
}
```

---

## 📦 Parameter Decorators (ALWAYS Use)

```bicep
// String parameters
@description('The name of the workload')
@minLength(3)
@maxLength(20)
param workloadName string

// Environment parameter
@description('The environment name')
@allowed(['dev', 'tst', 'stg', 'prod', 'sbx'])
param environment string

// Location parameter
@description('Azure region for resources')
@allowed(['eastus', 'westus', 'northeurope', 'westeurope'])
param location string

// Secure parameter (for secrets)
@description('Administrator password')
@secure()
param adminPassword string

// Integer with range
@description('Number of instances')
@minValue(1)
@maxValue(10)
param instanceCount int = 3

// Array parameter
@description('List of allowed IP addresses')
param allowedIpAddresses array = []

// Object parameter
@description('Tags for resources')
param tags object = {}
```

---

## 🎨 Resource Naming Reference

| Resource Type          | Prefix   | Example                      |
| ---------------------- | -------- | ---------------------------- |
| Virtual Machine        | `vm`     | `vm-webapp-prod-eus-001`     |
| Virtual Network        | `vnet`   | `vnet-hub-prod-eus-001`      |
| Subnet                 | `snet`   | `snet-app-prod-eus-001`      |
| Network Security Group | `nsg`    | `nsg-webapp-prod-eus-001`    |
| Storage Account        | `st`     | `stwebappprodeus001`         |
| Key Vault              | `kv`     | `kv-webapp-prod-eus-001`     |
| App Service            | `app`    | `app-webapp-prod-eus-001`    |
| Function App           | `func`   | `func-webapp-prod-eus-001`   |
| AKS Cluster            | `aks`    | `aks-webapp-prod-eus-001`    |
| SQL Server             | `sql`    | `sql-webapp-prod-eus-001`    |
| SQL Database           | `sqldb`  | `sqldb-webapp-prod-eus-001`  |
| Cosmos DB              | `cosmos` | `cosmos-webapp-prod-eus-001` |
| Redis Cache            | `redis`  | `redis-webapp-prod-eus-001`  |
| Log Analytics          | `log`    | `log-prod-eus-001`           |
| Application Insights   | `appi`   | `appi-webapp-prod-eus-001`   |
| Container Registry     | `acr`    | `acrwebappprodeus001`        |
| Public IP              | `pip`    | `pip-webapp-prod-eus-001`    |
| Load Balancer          | `lb`     | `lb-webapp-prod-eus-001`     |
| Application Gateway    | `appgw`  | `appgw-webapp-prod-eus-001`  |
| Azure Firewall         | `fw`     | `fw-hub-prod-eus-001`        |

---

## 🔄 Common AVM Module References

```bicep
// Storage Account
'br/public:avm/res/storage/storage-account:0.9.0'

// Virtual Network
'br/public:avm/res/network/virtual-network:0.1.0'

// Network Security Group
'br/public:avm/res/network/network-security-group:0.1.0'

// Key Vault
'br/public:avm/res/key-vault/vault:0.6.0'

// App Service
'br/public:avm/res/web/site:0.3.0'

// App Service Plan
'br/public:avm/res/web/serverfarm:0.2.0'

// SQL Server
'br/public:avm/res/sql/server:0.1.0'

// Log Analytics Workspace
'br/public:avm/res/operational-insights/workspace:0.3.0'

// Application Insights
'br/public:avm/res/insights/component:0.3.0'

// Container Registry
'br/public:avm/res/container-registry/registry:0.1.0'

// AKS Cluster
'br/public:avm/res/container-service/managed-cluster:0.1.0'

// Public IP
'br/public:avm/res/network/public-ip-address:0.2.0'

// Load Balancer
'br/public:avm/res/network/load-balancer:0.1.0'
```

---

## 🚫 NEVER Do These Things

```bicep
// ❌ NEVER use 'latest' API version
resource storageAccount 'Microsoft.Storage/storageAccounts@latest' = {}

// ❌ NEVER hardcode values
var storageAccountName = 'mystorageaccount'
var location = 'eastus'

// ❌ NEVER omit @description
param someParameter string

// ❌ NEVER skip parameter validation
param environment string  // Should use @allowed decorator

// ❌ NEVER store secrets in parameter files
param adminPassword = 'MyPassword123!'  // Use @secure() and Key Vault

// ❌ NEVER allow public access by default
allowBlobPublicAccess: true  // Should be false

// ❌ NEVER use weak naming
var storageName = 'storage1'
var vmName = 'vm1'

// ❌ NEVER skip tags
resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: storageAccountName
  location: location
  // Missing tags!
}

// ❌ NEVER create resources without checking AVM first
// If AVM has a module, use it!
```

---

## ✅ Module Output Pattern

```bicep
// ALWAYS provide these standard outputs
output resourceId string = resource.outputs.resourceId
output resourceName string = resource.outputs.name
output location string = location

// Provide resource-specific outputs
output storageAccountPrimaryEndpoints object = storageAccount.outputs.primaryEndpoints
output keyVaultUri string = keyVault.outputs.uri
output virtualNetworkId string = virtualNetwork.outputs.resourceId
```

---

## 🏁 Deployment Pattern

```bicep
// environments/dev/main.bicep
targetScope = 'subscription'  // or 'resourceGroup'

@description('Location for all resources')
param location string = 'eastus'

@description('Environment name')
@allowed(['dev', 'tst', 'stg', 'prod'])
param environment string = 'dev'

@description('Workload name')
param workloadName string

// Resource Group
module rg 'br/public:avm/res/resources/resource-group:0.2.0' = {
  name: 'rg-${workloadName}-${environment}-deployment'
  params: {
    name: 'rg-${workloadName}-${environment}-${locationAbbr}-001'
    location: location
    tags: standardTags
  }
}

// Storage Account
module storage '../modules/storage-account-wrapper.bicep' = {
  name: 'storage-deployment'
  scope: resourceGroup(rg.outputs.name)
  params: {
    workloadName: workloadName
    environment: environment
    location: location
    tags: standardTags
  }
}

// Key Vault
module keyVault '../modules/key-vault-wrapper.bicep' = {
  name: 'keyvault-deployment'
  scope: resourceGroup(rg.outputs.name)
  params: {
    workloadName: workloadName
    environment: environment
    location: location
    tags: standardTags
  }
}
```

---

## 📚 Environment Abbreviations

| Environment       | Abbreviation |
| ----------------- | ------------ |
| Development       | `dev`        |
| Test              | `tst`        |
| Staging           | `stg`        |
| Production        | `prod`       |
| Sandbox           | `sbx`        |
| Quality Assurance | `qa`         |

## 🌍 Location Abbreviations

| Region              | Abbreviation |
| ------------------- | ------------ |
| East US             | `eus`        |
| West US             | `wus`        |
| East US 2           | `eus2`       |
| West US 2           | `wus2`       |
| Central US          | `cus`        |
| North Europe        | `neu`        |
| West Europe         | `weu`        |
| Southeast Asia      | `sea`        |
| East Asia           | `easia`      |
| UK South            | `uks`        |
| UK West             | `ukw`        |
| Australia East      | `aue`        |
| Australia Southeast | `ause`       |

---

## 💡 Quick Reference: File Header Template

```bicep
/*
  File: storage-account-wrapper.bicep
  Purpose: Wrapper module for Azure Storage Account using AVM
  Author: [Team Name]
  Created: [Date]

  Description:
  This module wraps the AVM Storage Account module with organization-specific
  defaults and security settings.

  Dependencies:
  - Azure Verified Module: storage/storage-account:0.9.0

  Usage:
  See parameters/storage-account.{env}.bicepparam for configuration examples
*/

targetScope = 'resourceGroup'

// Parameters
@description('Storage account name (3-24 chars, lowercase, alphanumeric)')
@minLength(3)
@maxLength(24)
param name string
```

---

## 🤖 Agentic DevOps Prompt Templates

### Effective Prompt Structure for IaC

When generating infrastructure code, use this template:

```
[CONTEXT] Describe the infrastructure component and its purpose
[REQUIREMENTS] List specific technical requirements
[CONSTRAINTS] Specify limitations, compliance needs, naming conventions
[OUTPUT FORMAT] Specify desired code format (Bicep, Terraform, etc.)
[STANDARDS] Reference applicable standards (AVM, organizational policies)
```

### Bicep Module Generation Prompts

**Storage Account Module**:

```
Create a Bicep module for Azure Storage Account with:
- Purpose: Application data storage for [WORKLOAD]
- Required parameters: name, location, environment
- Security: private endpoints, customer-managed keys, deny public access
- Networking: allow Azure services only
- Diagnostic settings: send to Log Analytics workspace
- RBAC: Blob Data Contributor for managed identity
- Naming convention: st-{workload}-{env}-{region}-{instance}
- Follow Azure Verified Modules structure
```

**Virtual Network Module**:

```
Create a Bicep module for Azure Virtual Network with:
- Purpose: Hub network for [WORKLOAD]
- Subnets: GatewaySubnet, AzureFirewallSubnet, PrivateEndpointSubnet
- Address space: 10.0.0.0/16
- DNS: Azure-provided DNS
- DDoS protection: Standard tier
- Diagnostic settings: NSG flow logs to Log Analytics
- Follow naming convention: vnet-{workload}-{env}-{region}-{instance}
```

### Terraform Module Generation Prompts

**Resource Group Module**:

```
Create a Terraform module for Azure Resource Group with:
- Provider: azurerm version 4.0+
- Required variables: name, location, environment, tags
- Validation: name must follow pattern rg-{workload}-{env}-{region}
- Outputs: resource_group_id, resource_group_name, location
- Include lifecycle block to prevent accidental deletion
```

**AKS Cluster Module**:

```
Create a Terraform module for Azure Kubernetes Service with:
- Provider: azurerm version 4.0+
- Required variables: cluster_name, location, node_count, vm_size
- Security: managed identity, Azure CNI, Azure Policy, private cluster
- Networking: integrate with existing VNet
- Monitoring: enable Container Insights
- Outputs: cluster_id, kube_config, identity_principal_id
- Follow HashiCorp module structure
```

### Test Generation Prompts

**Bicep Module Tests**:

```
Generate Pester tests for [MODULE_NAME] Bicep module:
- Parameter validation tests (required params, min/max length, allowed values)
- Security tests (verify private endpoints, encryption, network rules)
- Compliance tests (naming convention, required tags, allowed locations)
- Integration tests (deploy to test environment, verify resources created)
- Use Pester 5.x syntax
```

**Terraform Module Tests**:

```
Generate Terraform tests for [MODULE_NAME] module:
- Unit tests for variable validation
- Integration tests for resource creation
- Security tests for compliance (CIS Azure Benchmark)
- Use Terraform test framework (terraform test)
- Include setup and teardown steps
```

### Security Review Prompts

**Infrastructure Code Security Scan**:

```
Review this [Bicep/Terraform] code for security issues:
[PASTE CODE]

Check for:
- Hardcoded secrets or credentials
- Missing encryption (at rest and in transit)
- Public network access enabled
- Overly permissive RBAC assignments
- Missing diagnostic settings
- Non-compliant resource configurations (CIS Azure Benchmark)
- Deprecated or insecure resource properties

Provide:
- Specific line numbers for each issue
- Severity rating (Critical, High, Medium, Low)
- Remediation code snippets
- Explanation of security impact
```

### Documentation Generation Prompts

**Module README**:

```
Generate a README.md for this [Bicep/Terraform] module:
- Module purpose and description
- Prerequisites and dependencies
- Parameters/variables table with descriptions
- Outputs table with descriptions
- Usage examples for dev, test, prod environments
- Deployment instructions
- Testing instructions
- Security considerations
- Compliance notes
```

### CI/CD Pipeline Generation Prompts

**Azure Pipelines for Bicep**:

```
Generate an Azure Pipeline YAML for Bicep deployment with:
- Trigger: main branch changes to /bicep/**
- Stages: Validate, Plan, Deploy
- Validate stage: bicep lint, bicep build, what-if
- Plan stage: generate deployment plan, require manual approval
- Deploy stage: deploy to dev, test, prod (sequential with approvals)
- Security: run Trivy and Checkov scans, fail on high/critical
- Notifications: Teams webhook on failure
- Use Azure DevOps service connection for authentication
```

**GitHub Actions for Terraform**:

```
Generate a GitHub Actions workflow for Terraform deployment with:
- Trigger: pull request and push to main for /terraform/**
- Jobs: format, validate, plan, apply
- Format job: terraform fmt -check
- Validate job: terraform validate, tflint, trivy, checkov
- Plan job: terraform plan, post plan as PR comment
- Apply job: terraform apply (only on main branch, requires approval)
- Use OIDC authentication to Azure
- Store state in Azure Storage with state locking
```

### Best Practices for Copilot Interactions

**DO** ✅:

- Provide complete context (purpose, requirements, constraints)
- Reference existing patterns in the codebase
- Specify security requirements explicitly
- Request validation and testing code
- Ask for inline documentation
- Iterate and refine suggestions

**DON'T** ❌:

- Accept suggestions without understanding them
- Skip security and compliance checks
- Ignore linting and validation errors
- Use deprecated resource types or properties
- Hardcode secrets or sensitive values
- Deploy without testing in non-production environment

---

## 🎯 Summary: Golden Rules

1. **AVM First** - Always use Azure Verified Modules
2. **No Hardcoding** - Everything in .bicepparam files
3. **Naming Standards** - `{type}-{workload}-{env}-{region}-{instance}`
4. **Security Default** - Deny public access, enable RBAC, use TLS 1.2+
5. **Always Describe** - @description on every parameter
6. **Always Validate** - @allowed, @minLength, @maxLength decorators
7. **Always Tag** - Standard tags on all resources
8. **Always Version** - Pin specific AVM versions
9. **Always Output** - resourceId, name, location minimum
10. **Always Document** - File headers and inline comments

---

_Follow these patterns for consistent, secure, production-ready Bicep infrastructure code._
