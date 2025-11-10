# Modern CLI Tool Replacements

This Fish configuration automatically uses modern CLI tools when available in interactive sessions, while preserving standard tool behavior in scripts and pipes.

## ✅ Setup Complete

All modern tools are installed via **mise** and configured with smart TTY detection!

## How It Works

Functions in `~/.config/fish/functions/` check if:
1. Output is going to a terminal (`isatty stdout`)
2. The modern tool is installed (`command -q <tool>`)

If both conditions are met, the modern tool is used. Otherwise, the standard tool is used.

## Installed Replacements

| Standard Tool | Modern Replacement | Function File | Description |
|---------------|-------------------|---------------|-------------|
| `cat` | `bat` | `cat.fish` | Syntax highlighting, git integration |
| `ls` | `eza` | `ls.fish` | Modern ls with colors, icons |
| `grep` | `rg` (ripgrep) | `grep.fish` | Faster, better defaults |
| `find` | `fd` | `find.fish` | Simpler syntax, faster |
| `df` | `duf` | `df.fish` | Better disk usage display |
| `du` | `dust` | `du.fish` | Better directory sizes |
| `ps` | `procs` | `ps.fish` | Modern process viewer |
| `top` | `btm` (bottom) | `top.fish` | Better system monitor |

## Additional Aliases

Defined in `aliases.fish`:
- `ll` - Long listing (eza or ls -lh)
- `la` - Long listing with hidden files
- `lt` - Tree view (eza only)
- `l` - Detailed listing with all info
- `catp` - Plain cat output (bat without styling)
- `htop` - Alias to bottom

## Installation

All modern tools are managed via **mise** and defined in `~/.config/mise/config.toml`.

### Already Installed ✅

All tools are already installed and configured:
- `bat` - via mise
- `eza` - via mise (cargo:eza)
- `ripgrep` (rg) - via mise
- `fd` - via mise
- `duf` - via mise (cargo:duf)
- `dust` - via mise (cargo:du-dust)
- `procs` - via mise (cargo:procs)
- `bottom` (btm) - via mise (cargo:bottom)

### To Update

```bash
mise upgrade
```

### To Reinstall

```bash
mise install
```

## Testing

Test that tools fall back correctly in pipes:

```bash
# Interactive - uses bat with syntax highlighting
cat config.fish

# Piped - uses standard cat
cat config.fish | head

# Script - uses standard cat
echo "cat config.fish" | fish
```

## Optional Additional Tools

Consider installing these as well:
- `delta` - Better git diffs (configure in `.gitconfig`)
- `zoxide` - Smarter cd (requires separate setup)
- `fzf` - Fuzzy finder
- `tldr` - Simplified man pages
- `httpie` - Better curl for APIs

## Customization

To modify behavior, edit the function files in `~/.config/fish/functions/`.
Each function follows this pattern:

```fish
function <command> --wraps=<modern-tool> --description 'Description'
    if isatty stdout; and command -q <modern-tool>
        command <modern-tool> $argv
    else
        command <standard-tool> $argv
    end
end
```

