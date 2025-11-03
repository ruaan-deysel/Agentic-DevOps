---
type: "always_apply"
description: "Documentation Standards and File Creation Restrictions"
---

# Documentation Standards

## Core Principle

**DO NOT create documentation files unless explicitly requested by the user.**

This rule prevents documentation sprawl, maintains a clean repository structure, and ensures documentation remains focused and maintainable.

---

## ❌ PROHIBITED: Unsolicited Documentation Files

### Summary Files (NEVER CREATE)

**DO NOT create files like:**
- `*_SUMMARY.md`
- `IMPLEMENTATION_SUMMARY.md`
- `CHANGES_SUMMARY.md`
- `UPDATE_SUMMARY.md`
- `DEPLOYMENT_SUMMARY.md`
- `MIGRATION_SUMMARY.md`

**Rationale:**
- Summary information should be in commit messages, PR descriptions, or existing documentation
- Creates redundant documentation that becomes outdated
- Clutters repository with unnecessary files

**Instead:**
- Add summary to commit messages
- Include in PR description
- Update existing README or documentation
- Add inline code comments

---

### Validation/Verification Files (NEVER CREATE)

**DO NOT create files like:**
- `VALIDATION.md`
- `VERIFICATION.md`
- `TESTING_RESULTS.md`
- `CHECKLIST.md`
- `VERIFICATION_STEPS.md`

**Rationale:**
- Validation steps belong in testing documentation or CI/CD pipelines
- Creates one-time documentation that becomes stale
- Testing procedures should be automated or in official test documentation

**Instead:**
- Add to existing testing documentation
- Include in CI/CD pipeline definitions
- Document in test files or test README
- Use automated testing tools

---

### Reference Documentation Files (NEVER CREATE)

**DO NOT create files like:**
- `REFERENCE.md`
- `TOOLS_REFERENCE.md`
- `API_REFERENCE.md`
- `COMMANDS_REFERENCE.md`
- `CONFIGURATION_REFERENCE.md`
- `*_REFERENCE.md`

**Rationale:**
- Reference documentation should be in official project documentation
- Creates maintenance burden with duplicate information
- Information often available in tool's official documentation

**Instead:**
- Link to official tool documentation
- Add to existing project README
- Include in inline code comments
- Use tool's built-in help (`--help`, man pages)

---

### Tool/Update Documentation Files (NEVER CREATE)

**DO NOT create files like:**
- `TOOLS_REFERENCE_PART2.md`
- `DEVCONTAINER_UPDATES.md`
- `CHANGELOG_DETAILED.md`
- `INSTALLATION_GUIDE.md`
- `SETUP_INSTRUCTIONS.md`

**Rationale:**
- Tool information should be in devcontainer configuration or README
- Update information belongs in CHANGELOG or commit history
- Creates fragmented documentation across multiple files

**Instead:**
- Update existing README or documentation
- Add to CHANGELOG (if it exists)
- Include in commit messages
- Document in configuration files (devcontainer.json comments)

---

## ✅ ALLOWED: Essential Documentation

### When Documentation IS Appropriate

**You MAY create/update these files:**
- `README.md` - Project overview and getting started
- `CHANGELOG.md` - Version history (if already exists)
- `CONTRIBUTING.md` - Contribution guidelines (if already exists)
- `.augment/rules/*.md` - Project-specific rules and standards
- Inline code comments and docstrings
- Test documentation within test directories

**Only when explicitly requested by user:**
- Architecture diagrams
- Design documents
- Deployment guides
- Troubleshooting guides

---

## Documentation Best Practices

### 1. Prefer Existing Documentation

**Before creating new documentation:**
1. Check if information fits in existing README
2. Consider inline code comments
3. Evaluate if commit message is sufficient
4. Determine if PR description is appropriate

### 2. Keep Documentation Close to Code

**Good practices:**
- Inline comments for complex logic
- Docstrings for functions/classes
- README in module directories
- Comments in configuration files

**Bad practices:**
- Separate reference files for code
- Duplicate information in multiple files
- Summary files that restate commit messages

### 3. Avoid Documentation Duplication

**Don't duplicate:**
- Tool documentation (link to official docs)
- Configuration options (use inline comments)
- Command syntax (use `--help` or man pages)
- API specifications (use code comments or OpenAPI)

### 4. Use Commit Messages Effectively

**Good commit message structure:**
```
feat: add Kubernetes deployment support

- Added kubectl and Helm to devcontainer
- Configured k9s for cluster management
- Updated testing workflow with kubectl validation

Closes #123
```

**This eliminates need for:**
- IMPLEMENTATION_SUMMARY.md
- CHANGES_SUMMARY.md
- UPDATE_NOTES.md

---

## Examples

### ❌ BAD: Creating Unsolicited Documentation

```
User: "Add Terraform support to the project"

Agent: 
1. Adds Terraform to Dockerfile
2. Creates TERRAFORM_SETUP.md
3. Creates TOOLS_REFERENCE.md
4. Creates IMPLEMENTATION_SUMMARY.md
5. Creates VALIDATION_CHECKLIST.md
```

**Problems:**
- 4 unnecessary documentation files created
- Information duplicated across multiple files
- Repository cluttered with redundant documentation

### ✅ GOOD: Minimal Documentation Approach

```
User: "Add Terraform support to the project"

Agent:
1. Adds Terraform to Dockerfile
2. Updates existing README with Terraform section
3. Adds inline comments in Dockerfile
4. Provides summary in commit message
```

**Benefits:**
- No unnecessary files created
- Information in appropriate locations
- Clean repository structure maintained

---

## Enforcement

### For Augment Agent

**ALWAYS:**
- Check if documentation file creation is explicitly requested
- Prefer updating existing documentation
- Use commit messages for summaries
- Add inline comments instead of separate reference files

**NEVER:**
- Create summary files after completing work
- Create validation/verification documentation
- Create reference documentation for tools
- Create update/changelog files (unless CHANGELOG.md exists)

### For GitHub Copilot

**Follow same rules:**
- No unsolicited documentation files
- Suggest updating existing documentation
- Recommend inline comments
- Link to official documentation instead of creating reference files

---

## Exceptions

### User Explicitly Requests Documentation

**If user says:**
- "Create a TOOLS_REFERENCE.md file"
- "I need a summary document"
- "Generate API reference documentation"

**Then you MAY create the requested file.**

**Always confirm if unclear:**
- "Would you like me to create a separate documentation file, or update the existing README?"
- "Should I add this to the README or create a new guide?"

---

## Related Standards

- See `iac-general.md` for IaC-specific documentation practices
- See `.github/copilot-instructions.md` for Copilot-specific guidance
- See repository README for project documentation structure

---

## Summary

**Golden Rule:** Only create documentation files when explicitly requested by the user.

**Default Actions:**
1. Update existing documentation (README, inline comments)
2. Use commit messages for summaries
3. Link to official documentation
4. Keep repository clean and focused

**Prohibited Actions:**
1. Creating summary files after completing work
2. Creating validation/verification documentation
3. Creating reference documentation for tools
4. Creating update/changelog files without explicit request

This approach maintains a clean, maintainable repository with focused documentation that doesn't become outdated or redundant.

