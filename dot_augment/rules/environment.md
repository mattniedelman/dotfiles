---
type: always_apply
priority: HIGH
description: Workspace configuration, path resolution, shell (bash), and environment setup
last_updated: 2026-02-18
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

## CLI Command Name

**IMPORTANT:** The Augment CLI command is `auggie`, NOT `augment`.

- ✅ Correct:
  `auggie`, `auggie --help`, `auggie chat`
- ❌ Incorrect:
  `augment`, `augment --help`

When referring to the product/company, use "Augment".
When referring to running the CLI, use `auggie`.

## Workspace Structure

**Current Workspace:** `/home/mattniedelman/.augment`

- This is a **configuration directory** for the Augment CLI (`auggie`), not a
  code repository
- Contains rules, settings, and Augment-specific configuration
- When working in this workspace, use relative paths (e.g., `rules/file.md`, not
  `.augment/rules/file.md`)

**Code Repositories:** `/home/mattniedelman/git/`

- All actual code repositories are located under `/home/mattniedelman/git/`
- Examples:
  `/home/mattniedelman/git/project1/`, `/home/mattniedelman/git/project2/`
- When working with code repositories, use absolute paths starting from
  `/home/mattniedelman/git/`
- **Note:** `/home/mattniedelman/git` is symlinked to
  `/mnt/2b20906f-1847-4c8e-94e4-b841290bddc3`
- Both paths refer to the same location; the system may resolve to the actual
  mount point

## Tool Management

**mise for Binary Management:**

- This environment uses **mise** for managing binary versions and tools
- All development tools (Node.js, Python, Go, etc.) are managed through mise
- Check `.mise.toml` or `.tool-versions` for current tool versions
- Run `mise install` to ensure all tools are available
- mise configuration may exist at multiple levels (global, per-repo)

## Language Server Configuration

**MCP Server Dynamic Workspace:**

- Language server MCPs are configured to use `$PWD` for dynamic workspace
  detection
- When Auggie is launched from a directory, the language servers automatically
  use that directory as their workspace
- Language servers will analyze files relative to the directory where Auggie was
  started
- This allows language servers to work with any project without hardcoded paths

**How It Works:**

- Configuration uses `$PWD` in `settings.json`:
  `"--workspace", "$PWD"`
- Shell expands `$PWD` to the current working directory when MCP servers start
- Language servers automatically adapt to whichever project directory you're in
- No need to reconfigure language servers when switching between projects

**Path Requirements for Language Server Tools:**

- ✅ Correct:
  `/home/mattniedelman/git/myproject/src/main.py` (absolute path)
- ✅ Correct:
  `src/main.py` (relative to workspace where Auggie was launched)
- ❌ Incorrect:
  `~/git/myproject/src/main.py` (tilde expansion may not work)
- ⚠️ Note:
  Relative paths work when they're relative to the directory where Auggie was
  launched

**Best Practices:**

- Launch Auggie from the root of the project you want to work on
- Language servers will automatically use that project as their workspace
- Use absolute paths for cross-project references
- Use relative paths for files within the current project

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
- Use relative paths within a single repository context when Auggie is launched
  from that repository
- Language server tools work with both absolute and relative paths (relative to
  launch directory)

## ⚠️ File and Directory Operation Authorization Policy ⚠️

### Directory Creation

**Allowed without explicit permission:**

- Creating standard project directories (src/, tests/, docs/, lib/, bin/, etc.)
  in current workspace
- Creating **pycache**, .pytest_cache, and other tool-generated directories
- Creating subdirectories within existing project structure

**Requires explicit permission:**

- Creating directories outside the current workspace
- Creating directories in system locations (/etc, /usr, /opt)
- Creating directories in user home directory (~/)
- Creating hidden directories (starting with .) that are not standard tool
  directories

**Before creating non-standard directories:**

```text
I will create the following directories:
- /path/to/new/directory

Location: [inside/outside workspace]
Purpose: [explanation]

Proceed? (yes/no)
```

### Configuration File Modification

**Operations requiring explicit permission:**

- Modifying .gitignore when adding sensitive patterns (credentials, secrets,
  personal data)
- Modifying pyproject.toml, package.json, or other package configuration
- Modifying .env files
- Modifying CI/CD configuration (.github/workflows, .gitlab-ci.yml)
- Modifying Docker configuration
- Modifying any configuration in /etc or system directories

**Allowed without explicit permission:**

- Adding standard ignore patterns to .gitignore (*.pyc, **pycache**/, .venv/,
  node_modules/, etc.)
- Adding tool-generated directories to .gitignore

**Before modifying configuration files:**

```text
I will modify the following configuration:

File: [filename]
Changes:
- [specific changes]

This will affect:
- [impact description]

Proceed? (yes/no)
```

### Path Safety Checks

**Before ANY file operation outside workspace:**

1. Verify the path is intentional
2. Confirm with user:

   ```text
   ⚠️  OPERATION OUTSIDE WORKSPACE

   This operation will affect: /path/outside/workspace

   Current workspace: /home/user/project
   Target location: /different/location

   Is this intentional? (yes/no)
   ```
