---
name: direnv
description: Set up direnv/.envrc for per-project Claude Code environments -- switch API keys, providers, models, and feature flags automatically when entering a directory. Use when the user wants to manage multiple Claude accounts, switch between Anthropic/Bedrock/Vertex per project, or configure per-directory environment variables.
allowed-tools: Bash, Read, Write, Edit, Glob
---

# direnv -- Per-Project Claude Code Environments

Set up `.envrc` files so Claude Code automatically loads the right API keys, provider, model, and feature flags when you `cd` into a project directory.

## Prerequisites

Check that direnv is installed and hooked into the shell:

```bash
which direnv && direnv version
# If missing: suggest installation for their platform
```

Check the shell hook is active:

```bash
grep -q 'direnv' ~/.zshrc ~/.bashrc 2>/dev/null && echo "hook found" || echo "hook missing"
```

If the hook is missing, add it:
- **zsh**: `echo 'eval "$(direnv hook zsh)"' >> ~/.zshrc`
- **bash**: `echo 'eval "$(direnv hook bash)"' >> ~/.bashrc`

## Creating a .envrc

Ask the user which scenario they need (Direct API key, AWS Bedrock, Google
Vertex, Azure Foundry, or layered config), then read
[envrc-recipes.md](envrc-recipes.md) and copy the matching template. That file
holds the per-provider `.envrc` templates, the layered `.envrc` + `.envrc.local`
pair, and the full Claude Code env-var reference table. Read only the recipe for
the chosen scenario.

## Security Checklist

After creating the `.envrc`:

1. **Allow it**: `direnv allow` (required after every edit)
2. **Gitignore it**: Verify `.envrc` is in `.gitignore` -- it may contain secrets

```bash
grep -q '.envrc' .gitignore 2>/dev/null || echo '.envrc' >>.gitignore
```

3. **Never commit API keys** -- if the project is shared, use `direnv allow` locally and keep `.envrc` out of version control.

## Verifying

After setup, verify the environment loads:

```bash
cd /path/to/project
direnv allow
env | grep -E 'ANTHROPIC|CLAUDE_CODE|AWS_PROFILE|CLOUD_ML'
```

Then start `claude` and confirm the right provider/model is active.

## More Recipes

For layered `.envrc` + `.envrc.local` configs, switching between projects, and
the full Claude Code env-var reference table, see
[envrc-recipes.md](envrc-recipes.md).
