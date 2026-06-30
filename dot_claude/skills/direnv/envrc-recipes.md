# direnv .envrc Recipes for Claude Code

Per-provider `.envrc` templates, a layered `.envrc` + `.envrc.local` pair, and
the full Claude Code environment variable reference. Pick the one provider
scenario the user needs, copy the template, then return to the skill body for
the security checklist and verification steps.

## Provider Templates

Pick exactly one provider block below.

### Direct API Key (personal / hobby)

```bash
# .envrc
export ANTHROPIC_API_KEY="sk-ant-..."
```

### AWS Bedrock

```bash
# .envrc
export CLAUDE_CODE_USE_BEDROCK=1
export AWS_PROFILE=my-bedrock-profile
export AWS_REGION=us-east-1
# Optional: override model
# export ANTHROPIC_MODEL="us.anthropic.claude-sonnet-4-20250514-v1:0"
```

### Google Vertex AI

```bash
# .envrc
export CLAUDE_CODE_USE_VERTEX=1
export CLOUD_ML_REGION=us-east5
export ANTHROPIC_VERTEX_PROJECT_ID=my-project-id
```

### Microsoft Azure Foundry

```bash
# .envrc
export CLAUDE_CODE_USE_FOUNDRY=1
export ANTHROPIC_FOUNDRY_BASE_URL="https://my-resource.services.ai.azure.com/api"
export ANTHROPIC_FOUNDRY_API_KEY="..."
```

### Feature Flags / Tuning

Append to any of the provider blocks above:

```bash
# .envrc -- append to any provider block
export ANTHROPIC_MODEL="claude-opus-4-6"
export CLAUDE_CODE_MAX_OUTPUT_TOKENS=64000
export CLAUDE_CODE_EFFORT_LEVEL=high
export CLAUDE_CODE_AUTOCOMPACT_PCT_OVERRIDE=99
```

## Layered Configs: .envrc + .envrc.local

Keep non-secret defaults in the committed `.envrc` and secrets in a gitignored
`.envrc.local`:

```bash
# .envrc (committed, non-secret defaults)
export CLAUDE_CODE_EFFORT_LEVEL=high
export CLAUDE_CODE_MAX_OUTPUT_TOKENS=64000

# Source local overrides if present
source_env_if_exists .envrc.local
```

```bash
# .envrc.local (gitignored, secrets)
export ANTHROPIC_API_KEY="sk-ant-..."
```

### Switching between projects

No action needed -- direnv automatically loads/unloads when you `cd`. Just set
up each project's `.envrc` once.

## Reference: Key Claude Code Env Vars

| Variable | Purpose |
|----------|---------|
| `ANTHROPIC_API_KEY` | Direct API authentication |
| `ANTHROPIC_MODEL` | Model selection |
| `CLAUDE_CODE_USE_BEDROCK` | Enable AWS Bedrock provider |
| `CLAUDE_CODE_USE_VERTEX` | Enable Google Vertex provider |
| `CLAUDE_CODE_USE_FOUNDRY` | Enable Azure Foundry provider |
| `CLAUDE_CODE_EFFORT_LEVEL` | low / medium / high |
| `CLAUDE_CODE_MAX_OUTPUT_TOKENS` | Max output tokens (up to 64000) |
| `CLAUDE_CODE_AUTOCOMPACT_PCT_OVERRIDE` | Auto-compaction threshold (1-100) |
| `CLAUDE_CODE_SUBAGENT_MODEL` | Model for subagents |
| `CLAUDE_CODE_SHELL` | Override shell detection |
| `CLAUDE_CONFIG_DIR` | Custom config directory |
