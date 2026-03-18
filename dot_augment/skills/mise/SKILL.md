---
name: mise
description: Use when managing dev tools, environment variables, tasks, or installing packages directly from npm/cargo/pip/go - mise is a polyglot tool manager that replaces asdf, nvm, pyenv, etc.
---

# mise (mise-en-place)

Polyglot dev tool and environment manager.
Replaces asdf, nvm, pyenv, rbenv, etc.

## When to Use

- Managing tool versions per-project (`mise.toml`)
- Installing CLI tools from npm, cargo, pip, go, or GitHub releases
- Setting project environment variables
- Running project tasks
- One-off tool execution without global install

## Quick Start

```bash
# Install mise
curl https://mise.run | sh
echo 'eval "$(~/.local/bin/mise activate bash)"' >>~/.bashrc

# Use a tool
mise use node@22             # Install + set as default
mise exec node@22 -- node -v # One-off execution
```

## Package Installation via Backends

**Key feature:** mise can install CLI tools directly from language ecosystems.

### Backend Syntax

| Backend | Syntax | Example |
|---------|--------|---------|
| **npm** | `npm:<package>` | `mise use npm:prettier` |
| **cargo** | `cargo:<crate>` | `mise use cargo:eza` |
| **pipx** | `pipx:<package>` | `mise use pipx:black` |
| **go** | `go:<module>` | `mise use go:github.com/DarthSim/hivemind` |
| **github** | `github:<owner/repo>` | `mise use github:BurntSushi/ripgrep` |
| **ubi** | `ubi:<owner/repo>` | `mise use ubi:astral-sh/uv` |

### Examples

```bash
# NPM packages (uses npm or bun under the hood)
mise use -g npm:prettier
mise use -g npm:@anthropic-ai/claude-code

# Rust crates (uses cargo-binstall if available)
mise use -g cargo:eza
mise use -g cargo:ripgrep
mise use -g cargo:bat

# Python CLIs (uses uvx by default if uv installed)
mise use -g pipx:black
mise use -g pipx:ruff
mise use -g pipx:httpie

# Go modules
mise use -g go:github.com/DarthSim/hivemind
mise use -g go:golang.org/x/tools/gopls

# GitHub releases (prebuilt binaries)
mise use -g github:BurntSushi/ripgrep
mise use -g github:sharkdp/fd
```

### Version Pinning

```bash
# Specific versions
mise use npm:prettier@3.0.0
mise use cargo:eza@0.18.0
mise use pipx:black@24.3.0

# From git
mise use cargo:https://github.com/eza-community/eza@tag:v0.18.0
mise use pipx:git+https://github.com/psf/black.git@main
```

## Configuration (mise.toml)

```toml
[tools]
node = "22"
python = "3.12"
"npm:prettier" = "latest"
"cargo:eza" = "latest"
"pipx:ruff" = "latest"
"go:github.com/DarthSim/hivemind" = "latest"

[env]
NODE_ENV = "development"
DATABASE_URL = "postgres://localhost/myapp"

[tasks]
dev = "npm run dev"
test = "pytest"
lint = "ruff check ."
```

## Common Commands

| Command | Purpose |
|---------|---------|
| `mise use <tool>` | Install and set tool version |
| `mise use -g <tool>` | Install globally |
| `mise install` | Install all tools from mise.toml |
| `mise exec -- <cmd>` | Run command with mise environment |
| `mise run <task>` | Run a task |
| `mise ls` | List installed tools |
| `mise doctor` | Check mise setup |
| `mise search <term>` | Search for tools |

## One-off Execution

```bash
# Run without installing globally
mise exec npm:prettier -- prettier --check .
mise exec pipx:black -- black --check .
mise exec cargo:eza -- eza -la
```

## Tool Options

```toml
[tools]
# Cargo with features
"cargo:cargo-edit" = { version = "latest", features = "add" }

# Cargo from git
"cargo:eza" = { version = "tag:v0.18.0", locked = true }

# Pipx with extras
"pipx:harlequin" = { version = "latest", extras = "postgres,s3" }

# Go with build tags
"go:github.com/golang-migrate/migrate/v4/cmd/migrate" = { version = "latest", tags = "postgres" }
```

## Settings for Backends

```bash
# Use bun instead of npm for npm: packages
mise settings set npm.package_manager bun

# Use cargo-binstall for faster Rust installs (default: true)
mise settings set cargo.binstall true

# pipx uses uvx by default if uv is installed
mise settings set pipx.uvx true
```

## Troubleshooting

| Issue | Solution |
|-------|----------|
| Tool not found after install | Run `mise doctor` to check activation |
| Slow cargo installs | Install `cargo-binstall`: `mise use -g cargo-binstall` |
| pipx package fails | Try `uvx = false` in tool options |
| Python version mismatch after upgrade | `mise install -f "pipx:*"` |

## See Also

- `REFERENCE.md` for tasks, hooks, direnv integration
- <https://mise.jdx.dev/> for full documentation
