---
type: "agent_requested"
description: "Example description"
---

# Bicep Configuration-Driven Development

## Configuration Principles
- ALL Bicep deployments MUST be configuration-driven
- No hardcoded values in main deployment files or modules
- Use .bicepparam files as the primary configuration mechanism
- Separate configuration from infrastructure code

## Folder Structure (MANDATORY)
```
bicep/
├── modules/           # Reusable Bicep modules
├── parameters/        # .bicepparam files for configuration
└── environments/      # Environment-specific deployments (dev, test, prod)
```

## Parameter File Standards (.bicepparam)
- Use .bicepparam files instead of JSON parameter files (Bicep best practice)
- Create separate parameter files for each environment
- File naming convention: `{resource-type}.{environment}.bicepparam`
- Example: `storage-account.dev.bicepparam`, `virtual-network.prod.bicepparam`

## Parameter File Structure
```bicep
using '../environments/dev/main.bicep'

param location = 'eastus'
param environment = 'dev'
param tags = {
  Environment: 'Development'
  ManagedBy: 'Bicep'
  CostCenter: 'IT'
}
// Additional parameters...
```

## Configuration Organization
- Store environment-specific parameters in `bicep/parameters/{environment}/`
- Use object parameters for complex configurations
- Leverage parameter arrays for repeatable resource patterns
- Use @secure decorator for sensitive parameters (never in .bicepparam files)

## Environment Management
- Create dedicated folders under `bicep/environments/` for each environment:
  - `bicep/environments/dev/`
  - `bicep/environments/test/`
  - `bicep/environments/prod/`
- Each environment folder contains main orchestration files
- Reference modules from `bicep/modules/`
- Reference parameters from `bicep/parameters/`

## Parameter Best Practices
- Define default values in .bicep files when appropriate
- Use parameter objects to group related configurations
- Validate parameters using decorators (@minLength, @maxLength, @allowed)
- Document all parameters with @description decorator
- Use consistent parameter naming across all files

## Configuration Validation
- Test parameter files with `bicep build-params` before deployment
- Validate configurations against environment requirements
- Use parameter files in deployment commands:
  ```bash
  az deployment sub create --template-file main.bicep --parameters main.bicepparam
  ```

## Sensitive Data Handling
- NEVER store secrets directly in .bicepparam files
- Use Azure Key Vault references for secrets
- Use @secure() decorator in .bicep files for secret parameters
- Reference Key Vault in parameter files:
  ```bicep
  param adminPassword = getSecret('subscription-id', 'rg-name', 'kv-name', 'secret-name')
  ```