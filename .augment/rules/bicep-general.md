---
type: "agent_requested"
description: "Bicep General Best Practices"
---

# Bicep General Best Practices

## Core Principles
- Always follow Bicep best practices and official Microsoft recommendations
- Write clean, maintainable, and reusable Infrastructure as Code
- Use declarative syntax and avoid imperative patterns
- Leverage Bicep's type safety and validation features

## Code Quality Standards
- Use meaningful and descriptive resource names
- Add comprehensive descriptions to parameters and outputs
- Include @description decorators for all parameters
- Use @minLength, @maxLength, and other decorators for parameter validation
- Always specify API versions explicitly (avoid using 'latest')
- Use symbolic names for resources that follow camelCase convention

## File Organization
- Keep individual Bicep files focused and modular
- Separate concerns: main deployment files, modules, and parameters
- Use consistent file naming: kebab-case for files (e.g., `storage-account.bicep`)
- Maximum file size: aim for files under 500 lines

## Documentation Requirements
- Follow the comprehensive documentation standards defined in `bicep-structure.md`
- Include enterprise-grade file header blocks with module title, description, features, dependencies, and deployment scope
- Use 78-character divider lines (`// ============================================================================`) for all section headers
- Organize files into clearly defined sections: PARAMETERS, VARIABLES, RESOURCES, OUTPUTS
- Document all complex logic or non-obvious implementations with inline comments
- Add `@description()` decorators to all parameters and outputs
- Include resource-level comments explaining purpose and configuration
- Maintain a README.md in each module directory explaining usage

## Resource Management
- Always use unique names for globally-named resources (storage, Key Vault, etc.)
- Use existing resources with existing keyword when appropriate
- Implement proper dependencies using dependsOn only when implicit dependencies don't work
- Use child resources with parent property when applicable

## Error Handling
- Validate inputs at the parameter level using decorators
- Use @allowed decorator for enumerated values
- Implement proper error messages in validation
- Use conditions to handle optional resource deployments