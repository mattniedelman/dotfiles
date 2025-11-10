---
type: always_apply
---

# Development Environment Configuration

## CRITICAL: Always Verify Working Directory and Paths

**Before ANY file operation, ALWAYS:**

1. **Check the current working directory** - Don't assume where you are
2. **Verify the workspace root** - Understand what paths are relative to
3. **Test path resolution** - Ensure paths resolve to the intended location
4. **Use absolute paths when uncertain** - Eliminates ambiguity

**Why This Matters:**

- Prevents creating files in wrong locations (e.g., `.augment/.augment/rules/`
  instead of `.augment/rules/`)
- Avoids confusion between workspace root and current directory
- Ensures file operations target the correct repository/directory
- Critical when working across multiple repositories or directories

**How to Verify:**

```bash
# Always check where you are
pwd

# List directory to confirm structure
ls -la

# Verify a path resolves correctly before using it
realpath <path>
```

**Path Resolution Rules:**

- Relative paths are resolved from the **workspace root** (for save-file,
  str-replace-editor, codebase-retrieval)
- Relative paths are resolved from the **current working directory** (for
  launch-process with wait=true)
- When in doubt, use absolute paths or verify with `pwd` first

## Workspace Structure

**Current Workspace:** `/home/mattniedelman/.augment`

- This is a **configuration directory** for Augment/Auggie, not a code
  repository
- Contains rules, settings, and Augment-specific configuration
- When working in this workspace, use relative paths (e.g., `rules/file.md`, not
  `.augment/rules/file.md`)

**Code Repositories:** `/home/mattniedelman/git/`

- All actual code repositories are located under `/home/mattniedelman/git/`
- Examples:
  `/home/mattniedelman/git/project1/`, `/home/mattniedelman/git/project2/`
- When working with code repositories, use absolute paths starting from
  `/home/mattniedelman/git/`

## Tool Management

**mise for Binary Management:**

- This environment uses **mise** for managing binary versions and tools
- All development tools (Node.js, Python, Go, etc.) are managed through mise
- Check `.mise.toml` or `.tool-versions` for current tool versions
- Run `mise install` to ensure all tools are available
- mise configuration may exist at multiple levels (global, per-repo)

## Language Server Configuration

**MCP Server Location:**

- Language server MCPs are configured **above the git repository level**
- Language servers are positioned to see all repositories under
  `/home/mattniedelman/git/`
- **Always use absolute paths** when interacting with language server MCPs
- The language servers can see all repositories but require absolute path
  references

**Path Requirements:**

- ✅ Correct:
  `/home/mattniedelman/git/myproject/src/main.py`
- ❌ Incorrect:
  `~/git/myproject/src/main.py` (tilde expansion may not work)
- ❌ Incorrect:
  `git/myproject/src/main.py` (relative path won't work)

## Repository Structure

**Organization:**

- Multiple code repositories are organized under `/home/mattniedelman/git/`
- Each repository is independent with its own git history
- Cross-repository references should use absolute paths
- MCP servers provide context across all repositories

**Working Across Repositories:**

- When referencing files in code repositories, always use absolute paths
- When working within a single repository, relative paths are acceptable
- Be explicit about which repository you're working in

## Path Conventions Summary

**When working with code repositories:**

- Use absolute paths:
  `/home/mattniedelman/git/project/src/file.py`
- Required for language server MCP interactions
- Ensures clarity when working across multiple repositories

**General Guidelines:**

- Prefer absolute paths for cross-repository work
- Use relative paths within a single repository context
- Always use absolute paths when interacting with language server tools
