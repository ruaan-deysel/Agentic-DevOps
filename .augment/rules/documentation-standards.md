---
type: "always_apply"
description: "Documentation Standards and File Creation Restrictions"
---

# Documentation Standards

## Core Principle

**DO NOT create documentation files unless explicitly requested by the user.**

This rule prevents documentation sprawl, maintains a clean repository structure, and ensures documentation remains focused and maintainable.

## Agentic DevOps Context

In an **Agentic DevOps** environment, AI agents (GitHub Copilot, Claude, Augment Code) may suggest creating documentation files. Apply the same standards: only create documentation when explicitly requested. AI-generated documentation must follow the same rules as human-generated documentation.

---

## ❌ PROHIBITED: Unsolicited Documentation Files

**NEVER CREATE**:

- Summary files: `*_SUMMARY.md`, `IMPLEMENTATION_SUMMARY.md`, `CHANGES_SUMMARY.md`
- Validation files: `VALIDATION.md`, `VERIFICATION.md`, `TESTING_RESULTS.md`, `CHECKLIST.md`
- Reference files: `REFERENCE.md`, `TOOLS_REFERENCE.md`, `API_REFERENCE.md`, `*_REFERENCE.md`
- Tool/Update files: `TOOLS_REFERENCE_PART2.md`, `DEVCONTAINER_UPDATES.md`, `CHANGELOG_DETAILED.md`

**Rationale**: Creates documentation sprawl, becomes outdated, duplicates information

**Instead**: Use commit messages, PR descriptions, existing README, inline comments, official documentation links

## ✅ ALLOWED: Essential Documentation

**You MAY create/update**:

- `README.md`, `CHANGELOG.md` (if exists), `CONTRIBUTING.md` (if exists)
- `.augment/rules/*.md` - Project-specific rules
- Inline code comments and docstrings
- Test documentation within test directories

**Only when explicitly requested**: Architecture diagrams, design documents, deployment guides, troubleshooting guides

## Documentation Best Practices

1. **Prefer Existing Documentation**: Check if information fits in existing README, inline comments, commit messages, or PR descriptions
2. **Keep Documentation Close to Code**: Use inline comments, docstrings, README in module directories, comments in config files
3. **Avoid Duplication**: Link to official docs instead of duplicating tool documentation, configuration options, command syntax
4. **Use Commit Messages**: Good commit messages eliminate need for summary files

---

## Enforcement

**For Augment Agent**:

- ALWAYS: Check if explicitly requested, prefer updating existing docs, use commit messages, add inline comments
- NEVER: Create summary/validation/reference files after completing work

**For GitHub Copilot**: Follow same rules - no unsolicited docs, suggest updating existing, recommend inline comments

## Exceptions

**User Explicitly Requests Documentation**: If user says "Create a TOOLS_REFERENCE.md file" or "I need a summary document", then you MAY create it.

**Always confirm if unclear**: "Would you like me to create a separate documentation file, or update the existing README?"

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
