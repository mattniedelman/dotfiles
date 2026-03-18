# mise Extended Reference

## Tasks

mise includes a task runner for project automation.

### TOML Tasks

```toml
# mise.toml
[tasks.build]
run = "npm run build"
description = "Build the project"

[tasks.test]
run = "pytest"
depends = ["build"]

[tasks.lint]
run = ["ruff check .", "mypy src/"] # Multiple commands

[tasks.dev]
run = "npm run dev"
env = { NODE_ENV = "development" }
```

### File Tasks

Create executable scripts in `.mise/tasks/` or `mise/tasks/`:

```bash
#!/usr/bin/env bash
#MISE description="Deploy to production"
#MISE depends=["build", "test"]
#MISE env={DEPLOY_ENV="production"}

set -euo pipefail
./deploy.sh "$@"
```

### Running Tasks

```bash
mise run build         # Run single task
mise run build test    # Run multiple tasks
mise run lint -- --fix # Pass arguments
mise run -w dev        # Watch mode (re-run on changes)
mise tasks             # List available tasks
```

## Environment Variables

```toml
[env]
# Static values
DATABASE_URL = "postgres://localhost/myapp"

# From file
_.file = ".env"

# From command output
_.source = "op inject -i .env.tpl"

# Conditional
NODE_ENV = { value = "production", if = "{{ env.CI }}" }
```

## Hooks

```toml
# mise.toml
[hooks]
enter = "echo 'Entered project'"
cd = "echo 'Changed directory'"
leave = "echo 'Left project'"
```

## GitHub Actions Integration

```yaml
# .github/workflows/ci.yml
name: CI
on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Install mise
        uses: jdx/mise-action@v2

      - name: Install dependencies
        run: mise run install

      - name: Run tests
        run: mise run test
```

### Generate mise action

```bash
mise generate github-action --write
```

## Comparison to asdf

| Feature | asdf | mise |
|---------|------|------|
| Config file | `.tool-versions` | `mise.toml` (also reads `.tool-versions`) |
| Speed | Slower (bash) | Faster (Rust) |
| Env vars | No | Yes |
| Tasks | No | Yes |
| Backends | Plugins only | npm, cargo, pip, go, github + plugins |

### Migration from asdf

```bash
# mise reads .tool-versions automatically
# Convert to mise.toml (optional):
mise config set tools.node 22
mise config set tools.python 3.12

# Check plugin compatibility
mise plugins ls-remote
```

## direnv Integration

```bash
# .envrc
use mise

# Or for specific tools
use mise node@22 python@3.12
```

Enable direnv support:

```bash
mise settings set experimental.direnv true
```

## Shims vs Activation

| Method | How | When to Use |
|--------|-----|-------------|
| **Activation** | `eval "$(mise activate bash)"` | Interactive shells (default) |
| **Shims** | `mise reshim` | IDEs, non-interactive scripts |

```bash
# Enable shims
mise settings set activate.shims true
mise reshim
```

## Trust and Security

```bash
# Trust a config file
mise trust mise.toml
mise trust --all

# Paranoid mode (require explicit trust)
mise settings set paranoid true
```

## Common Patterns

### Project-local CLI tools

```toml
# mise.toml - project tools not installed globally
[tools]
"npm:prettier" = "3.0"
"npm:eslint" = "8"
"pipx:ruff" = "0.4"
```

### Monorepo with multiple configs

```text
repo/
├── mise.toml           # Root config
├── frontend/
│   └── mise.toml       # Frontend-specific tools
└── backend/
    └── mise.toml       # Backend-specific tools
```

### CI caching

```yaml
- uses: actions/cache@v4
  with:
    path: |
      ~/.local/share/mise
      ~/.cache/mise
    key: mise-${{ hashFiles('mise.toml', 'mise.lock') }}
```
