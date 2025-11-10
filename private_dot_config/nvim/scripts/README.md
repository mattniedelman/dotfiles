# Neovim Scripts

This directory contains utility scripts for Neovim configuration.

## Scripts

### `kics-wrapper.sh`

Wrapper script for KICS (Keeping Infrastructure as Code Secure) integration with diagnosticls.

**Purpose**: Formats KICS JSON output into a format that diagnosticls can parse and display as LSP diagnostics.

**Usage**: 
```bash
./kics-wrapper.sh /path/to/file.tf
```

This script is automatically called by diagnosticls when scanning IaC files.

**Requirements**:
- KICS installed and in PATH
- jq for JSON parsing

### `install-kics.sh`

Installation script for KICS and its dependencies.

**Purpose**: Automates the installation of KICS for macOS and Linux systems.

**Usage**:
```bash
./install-kics.sh
```

**What it does**:
1. Detects your operating system
2. Installs KICS via the appropriate method (Homebrew on macOS, binary on Linux)
3. Verifies the installation
4. Checks for required dependencies (jq, diagnostic-languageserver)
5. Runs a test scan to ensure everything works

**Supported Systems**:
- macOS (via Homebrew or binary)
- Linux (via binary)

## Adding New Scripts

When adding new scripts to this directory:

1. Make them executable: `chmod +x script-name.sh`
2. Add a shebang line: `#!/usr/bin/env bash`
3. Use `set -euo pipefail` for better error handling
4. Document the script in this README
5. Add usage examples

## Related Documentation

- [KICS Integration Guide](../docs/KICS_INTEGRATION.md)
- [KICS Official Documentation](https://docs.kics.io/)

