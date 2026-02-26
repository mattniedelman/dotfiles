---
type: always_apply
priority: HIGH
description: Workspace configuration, path resolution, and environment setup
last_updated: 2026-02-26
---

# Development Environment Configuration

## System Information

| Property | Value |
|----------|-------|
| **OS** | Ubuntu (not Arch) |
| **Shell** | fish (user's interactive shell) |
| **Desktop** | GNOME |
| **Display server** | Wayland |

**Notes:**

- Scripts and hooks are written in bash for portability
- When giving advice to the user (package installation, shell config, etc.), reference Ubuntu and fish appropriately
- Package manager is `apt`, not `pacman`
- Shell config is `~/.config/fish/config.fish`, not `~/.bashrc` or `~/.zshrc`

## CRITICAL: Path Verification

**Before ANY file operation:** verify paths resolve correctly.

**Path Resolution:**

| Tool | Resolved From |
|------|---------------|
| save-file, str-replace-editor, codebase-retrieval | Workspace root |
| launch-process (wait=true) | Current working directory |

When uncertain, use absolute paths or verify with `pwd`.

## CLI Command

The Augment CLI is `auggie`, NOT `augment`.

## Workspace Structure

| Location | Purpose |
|----------|---------|
| `/home/mattniedelman/.augment` | Augment config (rules, settings) |
| `/home/mattniedelman/git/` | Code repositories |

Note:
`/home/mattniedelman/git` symlinks to
`/mnt/2b20906f-1847-4c8e-94e4-b841290bddc3`

## Desktop Environment

- **Desktop:** GNOME
- **Primary browser:** Brave
- **App cache refresh:** `update-desktop-database ~/.local/share/applications/`

## Tool Management

**mise** manages all binary versions (Node.js, Python, Go, etc.).
Check `.mise.toml` or `.tool-versions` for versions.

## Language Server MCP

- MCPs use `$PWD` for dynamic workspace detection
- Launch Auggie from project root for correct workspace
- Use absolute paths for cross-project references
- Tilde expansion (`~`) may not work - use full paths

## File/Directory Authorization

**Allowed without permission:**

- Standard project dirs (src/, tests/, docs/, lib/)
- Tool dirs (`__pycache__`, .pytest_cache)
- Standard .gitignore patterns (*.pyc, .venv/, node_modules/)

**Requires permission:**

- Dirs outside workspace or in system locations
- Config files (pyproject.toml, package.json, .env, CI/CD, Docker)
- .gitignore with sensitive patterns

**Operations outside workspace:** Always confirm with user first.

## System Detection

**Do not assume system details when they can be trivially checked:**

| Detail | Check Command |
|--------|---------------|
| Desktop environment | `echo $XDG_CURRENT_DESKTOP` |
| Default browser | `xdg-settings get default-web-browser` |
| Display server | `echo $XDG_SESSION_TYPE` |
| App cache refresh | `update-desktop-database ~/.local/share/applications/` |
