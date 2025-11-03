# Agentic DevOps - Practical Examples

This document provides real-world examples of using AI agents (GitHub Copilot, Claude, Augment Code) for Azure infrastructure as code development.

---

## Example 1: Creating a Secure Storage Account with AI Assistance

### Phase 1: Design (Using Claude or Augment Code)

**Your Prompt**:
```
Design a secure Azure Storage Account for a production web application with:
- Purpose: Store application logs and user-uploaded files
- Environment: Production
- Region: East US
- Security: Private endpoints, customer-managed keys, no public access
- Compliance: Must follow CIS Azure Benchmark
- Monitoring: Send diagnostics to Log Analytics
- Naming: Follow pattern st-{workload}-{env}-{region}-{instance}

Generate Bicep module structure following Azure Verified Modules patterns.
```

**AI Response** (Example):
```bicep
// AI generates module structure
@description('Storage account name')
param storageAccountName string

@description('Location for resources')
param location string = resourceGroup().location

@description('Environment (dev, test, prod)')
@allowed(['dev', 'test', 'prod'])
param environment string

@description('Log Analytics workspace ID for diagnostics')
param logAnalyticsWorkspaceId string

// Storage account with security controls
resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: 'Standard_GRS'
  }
  kind: 'StorageV2'
  properties: {
    allowBlobPublicAccess: false
    minimumTlsVersion: 'TLS1_2'
    supportsHttpsTrafficOnly: true
    encryption: {
      services: {
        blob: {
          enabled: true
        }
        file: {
          enabled: true
        }
      }
      keySource: 'Microsoft.Keyvault'
      keyvaultproperties: {
        keyname: 'storage-encryption-key'
        keyvaulturi: 'https://kv-myapp-prod-eus-001.vault.azure.net/'
      }
    }
    networkAcls: {
      defaultAction: 'Deny'
      bypass: 'AzureServices'
    }
  }
  tags: {
    Environment: environment
    ManagedBy: 'Bicep'
  }
}

// Diagnostic settings
resource diagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'storage-diagnostics'
  scope: storageAccount
  properties: {
    workspaceId: logAnalyticsWorkspaceId
    logs: [
      {
        category: 'StorageRead'
        enabled: true
      }
      {
        category: 'StorageWrite'
        enabled: true
      }
    ]
    metrics: [
      {
        category: 'Transaction'
        enabled: true
      }
    ]
  }
}

output storageAccountId string = storageAccount.id
output storageAccountName string = storageAccount.name
```

**Your Review**:
- ✅ Security controls implemented correctly
- ✅ Naming convention followed
- ✅ Diagnostic settings configured
- ⚠️ Need to add private endpoint
- ⚠️ Need to add RBAC assignment

### Phase 2: Refinement (Iterating with AI)

**Your Prompt**:
```
Add to the storage account module:
1. Private endpoint for blob service
2. RBAC assignment: Blob Data Contributor for managed identity
3. Parameter validation for storage account name (3-24 chars, lowercase, alphanumeric)
```

**AI Response** (Example):
```bicep
// AI adds parameter validation
@description('Storage account name (3-24 chars, lowercase, alphanumeric)')
@minLength(3)
@maxLength(24)
param storageAccountName string

@description('Managed identity principal ID for RBAC')
param managedIdentityPrincipalId string

@description('Virtual network ID for private endpoint')
param vnetId string

@description('Subnet ID for private endpoint')
param subnetId string

// ... (previous storage account code)

// Private endpoint for blob service
resource privateEndpoint 'Microsoft.Network/privateEndpoints@2023-04-01' = {
  name: 'pe-${storageAccountName}-blob'
  location: location
  properties: {
    subnet: {
      id: subnetId
    }
    privateLinkServiceConnections: [
      {
        name: 'blob-connection'
        properties: {
          privateLinkServiceId: storageAccount.id
          groupIds: ['blob']
        }
      }
    ]
  }
}

// RBAC assignment
resource blobContributorRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(storageAccount.id, managedIdentityPrincipalId, 'ba92f5b4-2d11-453d-a403-e96b0029c9fe')
  scope: storageAccount
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'ba92f5b4-2d11-453d-a403-e96b0029c9fe') // Blob Data Contributor
    principalId: managedIdentityPrincipalId
    principalType: 'ServicePrincipal'
  }
}
```

### Phase 3: Testing (AI-Generated Tests)

**Your Prompt**:
```
Generate Pester tests for this storage account module:
- Test parameter validation (name length, allowed characters)
- Test security settings (public access disabled, TLS 1.2, HTTPS only)
- Test encryption configuration
- Test network rules (default deny, Azure services allowed)
- Test diagnostic settings enabled
- Test private endpoint created
- Test RBAC assignment exists
```

**AI Response** (Example):
```powershell
# AI generates comprehensive test suite
Describe 'Storage Account Module Tests' {
    BeforeAll {
        $templateFile = './storage-account.bicep'
        $parameterFile = './storage-account.bicepparam'
    }

    Context 'Parameter Validation' {
        It 'Should reject storage account name shorter than 3 characters' {
            { az bicep build --file $templateFile --parameters storageAccountName='ab' } | Should -Throw
        }

        It 'Should reject storage account name longer than 24 characters' {
            { az bicep build --file $templateFile --parameters storageAccountName='abcdefghijklmnopqrstuvwxyz' } | Should -Throw
        }

        It 'Should reject storage account name with uppercase letters' {
            { az bicep build --file $templateFile --parameters storageAccountName='MyStorage' } | Should -Throw
        }
    }

    Context 'Security Configuration' {
        BeforeAll {
            $deployment = az deployment group create `
                --resource-group 'rg-test' `
                --template-file $templateFile `
                --parameters $parameterFile `
                --query 'properties.outputs' `
                --output json | ConvertFrom-Json

            $storageAccountName = $deployment.storageAccountName.value
            $storageAccount = az storage account show `
                --name $storageAccountName `
                --resource-group 'rg-test' `
                --output json | ConvertFrom-Json
        }

        It 'Should have public blob access disabled' {
            $storageAccount.allowBlobPublicAccess | Should -Be $false
        }

        It 'Should require minimum TLS 1.2' {
            $storageAccount.minimumTlsVersion | Should -Be 'TLS1_2'
        }

        It 'Should require HTTPS traffic only' {
            $storageAccount.supportsHttpsTrafficOnly | Should -Be $true
        }

        It 'Should have encryption enabled for blob service' {
            $storageAccount.encryption.services.blob.enabled | Should -Be $true
        }

        It 'Should use customer-managed keys for encryption' {
            $storageAccount.encryption.keySource | Should -Be 'Microsoft.Keyvault'
        }

        It 'Should have default network action set to Deny' {
            $storageAccount.networkRuleSet.defaultAction | Should -Be 'Deny'
        }

        It 'Should allow Azure services bypass' {
            $storageAccount.networkRuleSet.bypass | Should -Be 'AzureServices'
        }
    }

    Context 'Diagnostic Settings' {
        It 'Should have diagnostic settings configured' {
            $diagnostics = az monitor diagnostic-settings list `
                --resource $deployment.storageAccountId.value `
                --output json | ConvertFrom-Json

            $diagnostics.Count | Should -BeGreaterThan 0
        }
    }

    Context 'Private Endpoint' {
        It 'Should have private endpoint for blob service' {
            $privateEndpoints = az network private-endpoint list `
                --resource-group 'rg-test' `
                --query "[?contains(name, '$storageAccountName')]" `
                --output json | ConvertFrom-Json

            $privateEndpoints.Count | Should -BeGreaterThan 0
        }
    }

    Context 'RBAC Assignment' {
        It 'Should have Blob Data Contributor role assigned' {
            $roleAssignments = az role assignment list `
                --scope $deployment.storageAccountId.value `
                --query "[?roleDefinitionName=='Storage Blob Data Contributor']" `
                --output json | ConvertFrom-Json

            $roleAssignments.Count | Should -BeGreaterThan 0
        }
    }
}
```

### Phase 4: Security Scanning (AI-Assisted)

**Your Commands**:
```bash
# Scan for secrets
gitleaks detect --source . --verbose

# Scan for security issues
trivy config ./bicep

# Scan for compliance violations
checkov -d ./bicep
```

**AI Assistance**:
```
You: "Review the Trivy scan results and suggest fixes for any high/critical findings"

AI: [Analyzes scan output]
"I found 2 high-severity issues:
1. Storage account allows public network access (line 45)
   - Fix: Set 'publicNetworkAccess' to 'Disabled'
2. Missing soft delete configuration for blobs
   - Fix: Add deleteRetentionPolicy with 7-day retention

Here's the remediation code:
[AI provides specific code fixes]"

You: [Review and apply fixes]
```

---

## Example 2: Terraform AKS Cluster with AI Assistance

### Design Phase

**Your Prompt**:
```
Create a Terraform module for Azure Kubernetes Service with:
- Provider: azurerm version 4.0+
- Cluster: 3-node system pool, 2-node user pool
- Networking: Azure CNI, private cluster
- Security: managed identity, Azure Policy, Defender for Containers
- Monitoring: Container Insights enabled
- Outputs: cluster_id, kube_config, identity_principal_id
- Follow HashiCorp module structure
```

**AI Response**: [Generates complete Terraform module with variables.tf, main.tf, outputs.tf]

### Testing Phase

**Your Prompt**:
```
Generate Terraform tests for the AKS module:
- Validate cluster is private
- Validate Azure CNI is configured
- Validate managed identity is used
- Validate Azure Policy is enabled
- Validate Container Insights is enabled
- Use Terraform test framework
```

**AI Response**: [Generates complete test suite with terraform test files]

---

## Example 3: CI/CD Pipeline Generation

**Your Prompt**:
```
Generate an Azure Pipeline YAML for Bicep deployment with:
- Trigger: main branch changes to /bicep/**
- Stages: Validate, Plan, Deploy
- Validate: bicep lint, bicep build, what-if
- Plan: generate deployment plan, require manual approval
- Deploy: deploy to dev, test, prod (sequential with approvals)
- Security: run Trivy and Checkov scans, fail on high/critical
- Notifications: Teams webhook on failure
```

**AI Response**: [Generates complete Azure Pipeline with all stages, security scanning, and approvals]

---

## Best Practices from Real-World Usage

### DO ✅

1. **Provide Complete Context**: Include purpose, requirements, constraints, and standards
2. **Iterate and Refine**: Use multiple rounds of feedback to improve AI output
3. **Validate Everything**: Run linting, validation, and security scans on all AI-generated code
4. **Test Thoroughly**: Deploy to test environment before production
5. **Document Decisions**: Explain why AI suggestions were accepted or rejected
6. **Learn from AI**: Use AI explanations to improve your own understanding

### DON'T ❌

1. **Blindly Deploy**: Never deploy AI-generated code without review and testing
2. **Skip Security**: Always scan for secrets, vulnerabilities, and compliance issues
3. **Ignore Warnings**: Address all linting and validation warnings
4. **Over-Rely on AI**: Use critical thinking to validate AI suggestions
5. **Forget Context**: AI doesn't know your specific organizational requirements
6. **Compromise Security**: Don't accept insecure code for speed

---

## Measuring Success

Track these metrics to measure Agentic DevOps effectiveness:

**Productivity**:
- Time to deploy new infrastructure (baseline vs. AI-assisted)
- Lines of code generated per hour
- Number of iterations to production-ready code

**Quality**:
- Security scan findings (high/critical)
- Compliance violations
- Post-deployment issues
- Code review feedback volume

**Learning**:
- Team skill improvement
- Knowledge base growth
- Pattern reuse rate
- Time to resolve issues

---

## Related Resources

- See `.augment/rules/agentic-devops-patterns.md` for comprehensive AI-assisted development patterns
- See `.github/copilot-instructions.md` for GitHub Copilot-specific guidance
- See `README.md` for complete Agentic DevOps workflow documentation

