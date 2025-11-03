---
type: "always_apply"
---

# Agentic DevOps Patterns and Best Practices

## Core Principle

**Agentic DevOps** is an AI-assisted approach to IaC development leveraging AI agents (GitHub Copilot, Claude, Augment Code) to enhance productivity, quality, and innovation while maintaining human oversight.

**Key Principle**: AI agents are **assistants**, not replacements. Human expertise validates all AI-generated code.

## AI Tools Stack

- **GitHub Copilot**: Real-time code completion for Bicep/Terraform/Ansible
- **Claude**: Complex reasoning, architecture design, security analysis
- **Augment Code**: Codebase-aware assistant with task management

## AI-Assisted Development Lifecycle

### Phase 1: Design & Architecture

**Human**: Define requirements, constraints, business objectives
**AI**: Generate architecture proposals, suggest Azure services
**Workflow**: Describe requirements → AI generates architecture → Human reviews → AI generates code structure

### Phase 2: Implementation

**Human**: Review code, validate requirements, customize
**AI**: Generate Bicep/Terraform modules, implement security controls
**Workflow**: AI generates modules → Human reviews → AI refines → Human validates

### Phase 3: Testing & Validation

**Human**: Define test scenarios, validate coverage
**AI**: Generate test cases, validation scripts
**Workflow**: AI generates tests → AI creates validation scripts → Human reviews coverage

### Phase 4: Security & Compliance Review

**Human**: Approve security controls, validate compliance
**AI**: Scan for vulnerabilities, suggest improvements
**Workflow**: AI runs scanners (Trivy, Checkov, Gitleaks) → AI suggests fixes → Human prioritizes → AI generates remediation

### Phase 5: Deployment & Monitoring

**Human**: Approve deployment, monitor, validate
**AI**: Generate deployment scripts, monitoring dashboards
**Workflow**: AI generates plan → Human approves → AI creates deployment scripts → AI generates monitoring

## Prompt Engineering for IaC

**Effective Prompt Structure**: `[CONTEXT] [REQUIREMENTS] [CONSTRAINTS] [OUTPUT FORMAT] [STANDARDS]`

**See `.github/copilot-instructions.md` for detailed prompt templates for Bicep, Terraform, and Ansible.**

## AI-Assisted Code Review Patterns

**Security Checklist**: No hardcoded secrets, encryption enabled, network security configured, managed identities, private endpoints, diagnostic settings, RBAC least privilege, Key Vault integration

**Compliance Checklist**: Naming conventions, required tags, allowed locations, approved SKUs, backup/DR, monitoring, cost optimization

**Quality Checklist**: IaC best practices, modular/reusable, documented, parameter validation, error handling, idempotent, no deprecated resources

## Validating AI-Generated Code

**NEVER deploy AI-generated code without**:

1. **Syntax Validation**: `az bicep build`, `az bicep lint`, `terraform fmt`, `terraform validate`
2. **Security Scanning**: `gitleaks detect`, `trivy config`, `checkov -d`
3. **Plan/What-If Review**: `az deployment sub what-if`, `terraform plan`
4. **Human Review**: Verify logic, validate requirements, check compliance
5. **Testing**: Run automated tests, deploy to test environment

**Quality Gates**: Naming conventions, security controls, no hardcoded values, error handling, documentation, linting passes, security scans pass, plan reviewed, test coverage, peer review

## AI in CI/CD Pipelines

**Use AI to create**: Azure Pipelines YAML, GitHub Actions workflows, deployment scripts, testing stages, security scanning steps

**Integrate AI for**: Automated code review, security explanations, compliance details, optimization suggestions, cost analysis

## Continuous Learning with AI

**Feedback Loops**: AI analyzes deployment failures, security findings, performance issues, cost overruns

**Knowledge Base**: AI maintains patterns library, troubleshooting guides, best practices, lessons learned

## Best Practices for Human-AI Collaboration

### DO

✅ **Provide Clear Context**: Give AI complete requirements and constraints
✅ **Validate Everything**: Never trust AI-generated code without verification
✅ **Iterate**: Refine AI output through multiple rounds of feedback
✅ **Document**: Explain why AI suggestions were accepted or rejected
✅ **Learn**: Use AI explanations to improve your own understanding
✅ **Test Thoroughly**: AI-generated code needs the same testing as human code
✅ **Review Security**: Always scan AI code for security issues
✅ **Follow Standards**: Ensure AI output follows organizational policies

### DON'T

❌ **Blindly Accept**: Don't deploy AI code without understanding it
❌ **Skip Validation**: Don't bypass linting, scanning, or testing
❌ **Ignore Warnings**: Don't dismiss security scanner findings
❌ **Over-Rely**: Don't let AI replace critical thinking
❌ **Forget Context**: Don't assume AI knows your specific requirements
❌ **Skip Review**: Don't merge AI code without peer review
❌ **Compromise Security**: Don't accept insecure code for speed
❌ **Ignore Standards**: Don't let AI violate organizational policies

---

## Measuring Agentic DevOps Success

### Key Metrics

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

## Related Standards

- See `iac-general.md` for general IaC best practices
- See `iac-security.md` for security requirements
- See `iac-testing.md` for testing standards
- See `documentation-standards.md` for documentation rules
- See `.github/copilot-instructions.md` for GitHub Copilot guidance

---

## Summary

**Agentic DevOps** enhances traditional DevOps with AI assistance while maintaining:

- Human oversight and validation
- Security and compliance standards
- Quality gates and testing requirements
- Systematic task-based workflows

**Golden Rule**: AI accelerates development, but humans ensure correctness, security, and compliance.
