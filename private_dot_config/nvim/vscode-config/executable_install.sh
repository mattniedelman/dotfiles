#!/bin/bash

# VSCode Neovim Configuration Installer
# This script installs the necessary VSCode extensions and copies configuration files

set -e

echo "=========================================="
echo "VSCode Neovim Configuration Installer"
echo "=========================================="
echo ""

# Detect OS
OS="unknown"
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    OS="linux"
    VSCODE_CONFIG_DIR="$HOME/.config/Code/User"
elif [[ "$OSTYPE" == "darwin"* ]]; then
    OS="macos"
    VSCODE_CONFIG_DIR="$HOME/Library/Application Support/Code/User"
else
    echo "Error: Unsupported operating system: $OSTYPE"
    echo "This script supports Linux and macOS only."
    exit 1
fi

echo "Detected OS: $OS"
echo "VSCode config directory: $VSCODE_CONFIG_DIR"
echo ""

# Check if VSCode is installed
if ! command -v code &> /dev/null; then
    echo "Error: VSCode 'code' command not found in PATH"
    echo "Please install VSCode and ensure the 'code' command is available"
    echo "See: https://code.visualstudio.com/docs/setup/setup-overview"
    exit 1
fi

# Check if Neovim is installed
if ! command -v nvim &> /dev/null; then
    echo "Warning: Neovim not found in PATH"
    echo "Please install Neovim before using this configuration"
    echo "See: https://github.com/neovim/neovim/wiki/Installing-Neovim"
    echo ""
    read -p "Continue anyway? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
else
    NVIM_VERSION=$(nvim --version | head -n 1)
    echo "Found Neovim: $NVIM_VERSION"
fi

echo ""
echo "=========================================="
echo "Step 1: Installing VSCode Extensions"
echo "=========================================="
echo ""

# Core extensions
echo "Installing core extensions..."
code --install-extension asvetliakov.vscode-neovim
code --install-extension ms-python.python
code --install-extension detachhead.basedpyright
code --install-extension charliermarsh.ruff

# Check if Augment extension is available
echo ""
echo "Note: Augment Code extension may need to be installed manually"
echo "Visit: https://marketplace.visualstudio.com/items?itemName=augmentcode.augment"
echo ""

# Language support
echo "Installing language support extensions..."
code --install-extension golang.go
code --install-extension redhat.vscode-yaml
code --install-extension ms-azuretools.vscode-docker
code --install-extension tamasfe.even-better-toml

# Git integration
echo "Installing Git extensions..."
code --install-extension eamodio.gitlens
code --install-extension mhutchie.git-graph

# UI enhancements
echo "Installing UI enhancement extensions..."
code --install-extension PKief.material-icon-theme
code --install-extension usernamehw.errorlens
code --install-extension oderwat.indent-rainbow
code --install-extension Gruntfuggly.todo-tree

# Formatters
echo "Installing formatter extensions..."
code --install-extension JohnnyMorganz.stylua
code --install-extension foxundermoon.shell-format

# Color theme
echo "Installing color theme..."
code --install-extension qufiwefefwoyn.kanagawa || {
    echo "Warning: Kanagawa theme not found, trying alternatives..."
    code --install-extension enkia.tokyo-night || echo "Tokyo Night theme not found"
}

echo ""
echo "=========================================="
echo "Step 2: Backing Up Existing Configuration"
echo "=========================================="
echo ""

# Create config directory if it doesn't exist
mkdir -p "$VSCODE_CONFIG_DIR"

# Backup existing configuration
BACKUP_DIR="$VSCODE_CONFIG_DIR/backup-$(date +%Y%m%d-%H%M%S)"
if [ -f "$VSCODE_CONFIG_DIR/settings.json" ] || [ -f "$VSCODE_CONFIG_DIR/keybindings.json" ]; then
    echo "Backing up existing configuration to: $BACKUP_DIR"
    mkdir -p "$BACKUP_DIR"
    
    if [ -f "$VSCODE_CONFIG_DIR/settings.json" ]; then
        cp "$VSCODE_CONFIG_DIR/settings.json" "$BACKUP_DIR/settings.json"
        echo "  - Backed up settings.json"
    fi
    
    if [ -f "$VSCODE_CONFIG_DIR/keybindings.json" ]; then
        cp "$VSCODE_CONFIG_DIR/keybindings.json" "$BACKUP_DIR/keybindings.json"
        echo "  - Backed up keybindings.json"
    fi
else
    echo "No existing configuration found, skipping backup"
fi

echo ""
echo "=========================================="
echo "Step 3: Copying Configuration Files"
echo "=========================================="
echo ""

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Copy settings.json
if [ -f "$SCRIPT_DIR/settings.json" ]; then
    cp "$SCRIPT_DIR/settings.json" "$VSCODE_CONFIG_DIR/settings.json"
    echo "✓ Copied settings.json"
else
    echo "✗ Error: settings.json not found in $SCRIPT_DIR"
    exit 1
fi

# Copy keybindings.json
if [ -f "$SCRIPT_DIR/keybindings.json" ]; then
    cp "$SCRIPT_DIR/keybindings.json" "$VSCODE_CONFIG_DIR/keybindings.json"
    echo "✓ Copied keybindings.json"
else
    echo "✗ Error: keybindings.json not found in $SCRIPT_DIR"
    exit 1
fi

echo ""
echo "=========================================="
echo "Step 4: Updating Neovim Path"
echo "=========================================="
echo ""

# Detect Neovim path
if command -v nvim &> /dev/null; then
    NVIM_PATH=$(which nvim)
    echo "Detected Neovim at: $NVIM_PATH"
    
    # Update settings.json with correct Neovim path
    if [[ "$OS" == "linux" ]]; then
        sed -i "s|\"vscode-neovim.neovimExecutablePaths.linux\": \".*\"|\"vscode-neovim.neovimExecutablePaths.linux\": \"$NVIM_PATH\"|" "$VSCODE_CONFIG_DIR/settings.json"
    elif [[ "$OS" == "macos" ]]; then
        sed -i '' "s|\"vscode-neovim.neovimExecutablePaths.linux\": \".*\"|\"vscode-neovim.neovimExecutablePaths.darwin\": \"$NVIM_PATH\"|" "$VSCODE_CONFIG_DIR/settings.json"
    fi
    echo "✓ Updated Neovim path in settings.json"
else
    echo "⚠ Neovim not found, please update the path manually in settings.json"
fi

echo ""
echo "=========================================="
echo "Installation Complete!"
echo "=========================================="
echo ""
echo "Next steps:"
echo "1. Restart VSCode to apply the new configuration"
echo "2. Open a file and verify Neovim integration is working"
echo "3. Check the MAPPING.md file for detailed documentation"
echo "4. Test keybindings: Space+ff (find files), Space+e (explorer)"
echo ""
echo "If you backed up your configuration, you can restore it from:"
echo "  $BACKUP_DIR"
echo ""
echo "For troubleshooting, see the MAPPING.md file"
echo ""
echo "Enjoy your Neovim experience in VSCode! 🎉"

