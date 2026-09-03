---
name: no-broad-search
description: Predict where something lives before searching. Form a location hypothesis and go straight there. Use the built-in grep/glob tools rather than bash find/grep. Broad searches rooted at /, ~, or $HOME are the last resort, not the first move.
scope: bash
condition: '\b(find|grep|rg)\b[^\n]*(\s/(\s|$)|~|\$HOME)'
interruptMode: never
---

# Predict Location First; Scope Searches

```
FORM A HYPOTHESIS ABOUT WHERE SOMETHING LIVES, THEN GO STRAIGHT THERE. SEARCHING IS NOT THE FIRST MOVE.
```

When you need to find a file, definition, or config: predict its location from
conventions, then go directly there. Most things have a predictable home.

## Preferred approach

1. **Ask the authoritative source first.** `--help`, man page, or docs name the
   config path. For code: semantic search, entry points, naming conventions.
2. **Go directly to the conventional location.** Config: `$XDG_CONFIG_HOME/<tool>/`,
   `$HOME/.<tool>rc`, `/etc/<tool>/`. Binaries: `command -v <tool>`.
3. **Use built-in tools, not bash.** Use the `grep` tool (not bash `grep`/`rg`)
   and `glob` tool (not bash `find`) -- they are faster, scope-aware, and don't
   enumerate your local filesystem.
4. **Scope any search to one directory.** Root it at the one place your
   hypothesis named -- never at `/`, `~`, or `$HOME`.
5. **Broad sweep only if all else fails.** After prediction is exhausted; and
   justify why the narrower options were insufficient before broadening.

## Before running any search

1. Have I formed a hypothesis about where this should be?
2. Did I check the authoritative source (docs/help/conventions) first?
3. Is the search scoped to the one place my hypothesis named?

If #1 is "searching to avoid thinking" -- stop and predict first.
