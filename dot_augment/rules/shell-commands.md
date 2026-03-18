---
type: always_apply
priority: HIGH
description: Shell command formatting for launch-process tool
---

# Shell Command Formatting

## Multi-line Commands with Backslash Continuations

**CRITICAL**:
When writing multi-line shell commands with `\` line continuations, they MUST be
wrapped in a bash heredoc.
Otherwise each line executes as a separate command.

### ❌ WRONG - Lines execute separately

```bash
thv run grafana \
 --env FOO=bar \
 --tools tool1
```

### ✅ CORRECT - Use heredoc wrapper

```bash
bash <<'EOF'
thv run grafana \
    --env FOO=bar \
    --tools tool1
EOF
```

### Alternative: Single line (when short enough)

```bash
thv run grafana --env FOO=bar --tools tool1
```

## Why This Matters

The `launch-process` tool may split multi-line commands at newlines before
execution.
The heredoc wrapper ensures the entire block is passed to bash as a single unit,
preserving line continuation behavior.

## When to Use Heredoc

- Any command with `\` line continuations
- Multi-line scripts that should execute as one unit
- Commands with complex quoting that benefit from heredoc's literal handling
