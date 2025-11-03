---
type: "always_apply"
description: "General IaC Best Practices for Bicep and Terraform"
---

# Infrastructure as Code General Best Practices

## Core Principles
- Follow official best practices (Microsoft for Bicep, HashiCorp for Terraform)
- Write clean, maintainable, and reusable code
- Use declarative syntax consistently
- Leverage type safety and validation features
- Use latest stable versions (Bicep latest, Terraform 1.9+)

## Code Quality Standards
- Use meaningful, descriptive names (Bicep: camelCase, Terraform: snake_case)
- Add descriptions to all parameters/variables and outputs
- Use validation rules for constraints
- Always specify provider/API versions explicitly
- Group related resources logically
- Maximum file size: 500 lines

## File Organization

### Bicep Standard Files
- `main.bicep` - Primary deployment orchestration
- `{resource}.bicep` - Individual resource modules
- `{resource}.bicepparam` - Parameter files per environment

### Terraform Standard Files
- `main.tf` - Primary resource definitions
- `variables.tf` - Input variable declarations
- `outputs.tf` - Output value declarations
- `versions.tf` - Provider version constraints
- `terraform.tfvars` - Configuration values

## Module/Wrapper Best Practices
- Create reusable modules for common patterns
- Use Azure Verified Modules (AVM) for Bicep when available
- Keep modules focused on single responsibility
- Document all inputs and outputs
- Provide usage examples

## Resource Management
- Use unique names for globally-named resources
- Implement proper dependencies (use implicit when possible)
- Use lifecycle blocks for critical resources
- Leverage data sources for existing resources

## Systematic Task-Based Development Workflow (MANDATORY)

### Requirements
ALL IaC development MUST follow systematic task-based workflow:

**BEFORE Starting:**
- Create granular tasks (30-60 min each)
- Break complex work into small, testable units
- Document task dependencies

**DURING Development:**
- Work ONE task at a time
- Mark task IN_PROGRESS before starting
- Focus exclusively on current task
- Test after each task
- Mark COMPLETE only after verification

**AFTER Each Task:**
- Run format/lint tools
- Run validation
- Fix ALL errors immediately
- Document issues

**Task Progression:**
- Move to next task ONLY after previous is complete
- NEVER batch multiple tasks
- Create new tasks for issues found

### Example Task Breakdown
For new storage account:
1. Create module structure
2. Add parameter/variable validation
3. Configure security settings
4. Run format/lint (TEST)
5. Run validate (TEST)
6. Create config file for dev
7. Run plan/what-if (TEST)
8. Deploy to dev
9. Verify deployment (TEST)
10. Update documentation

### Enforcement
- Task-based workflow is NON-NEGOTIABLE
- Code reviews verify task management
- PRs must reference completed tasks
- No deployments without task completion

## Documentation Standards

**IMPORTANT:** Do NOT create unsolicited documentation files.

See `documentation-standards.md` for complete guidelines on:
- Prohibited documentation files (summary, validation, reference files)
- When documentation creation is appropriate
- Best practices for maintaining clean repository structure

**Key Rules:**
- ❌ NO summary files (`*_SUMMARY.md`, `IMPLEMENTATION_SUMMARY.md`)
- ❌ NO validation files (`VALIDATION.md`, `VERIFICATION.md`)
- ❌ NO reference files (`TOOLS_REFERENCE.md`, `API_REFERENCE.md`)
- ✅ Update existing documentation (README, inline comments)
- ✅ Use commit messages for summaries
- ✅ Only create documentation when explicitly requested by user
