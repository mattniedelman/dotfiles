#!/usr/bin/env bash
# KICS installation script for Neovim integration
# Supports macOS and Linux

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Detect OS
OS="unknown"
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    OS="linux"
elif [[ "$OSTYPE" == "darwin"* ]]; then
    OS="macos"
else
    echo -e "${RED}Error: Unsupported OS: $OSTYPE${NC}"
    exit 1
fi

echo "=========================================="
echo "KICS Installation for Neovim"
echo "=========================================="
echo ""

# Check if KICS is already installed
if command -v kics &> /dev/null; then
    KICS_VERSION=$(kics version 2>&1 | grep -oP 'v\d+\.\d+\.\d+' || echo "unknown")
    echo -e "${GREEN}✓ KICS is already installed: $KICS_VERSION${NC}"
    read -p "Do you want to reinstall/update? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Skipping KICS installation."
        exit 0
    fi
fi

# Install KICS based on OS
echo ""
echo "Installing KICS..."
echo ""

if [[ "$OS" == "macos" ]]; then
    # macOS installation via Homebrew
    if command -v brew &> /dev/null; then
        echo "Installing KICS via Homebrew..."
        brew install kics
    else
        echo -e "${YELLOW}Warning: Homebrew not found. Installing via binary...${NC}"
        curl -sfL 'https://raw.githubusercontent.com/Checkmarx/kics/master/install.sh' | bash
        sudo mv ./bin/kics /usr/local/bin/kics 2>/dev/null || mv ./bin/kics ~/bin/kics
    fi
elif [[ "$OS" == "linux" ]]; then
    # Linux installation via binary
    echo "Installing KICS via binary..."
    curl -sfL 'https://raw.githubusercontent.com/Checkmarx/kics/master/install.sh' | bash
    
    # Try to move to /usr/local/bin, fallback to ~/bin
    if sudo mv ./bin/kics /usr/local/bin/kics 2>/dev/null; then
        echo -e "${GREEN}✓ KICS installed to /usr/local/bin/kics${NC}"
    else
        mkdir -p ~/bin
        mv ./bin/kics ~/bin/kics
        echo -e "${GREEN}✓ KICS installed to ~/bin/kics${NC}"
        echo -e "${YELLOW}Note: Make sure ~/bin is in your PATH${NC}"
        
        # Check if ~/bin is in PATH
        if [[ ":$PATH:" != *":$HOME/bin:"* ]]; then
            echo ""
            echo "Add this to your ~/.bashrc or ~/.zshrc:"
            echo "  export PATH=\"\$HOME/bin:\$PATH\""
        fi
    fi
    
    # Clean up
    rm -rf ./bin
fi

# Verify installation
echo ""
echo "Verifying installation..."
if command -v kics &> /dev/null; then
    KICS_VERSION=$(kics version 2>&1 | grep -oP 'v\d+\.\d+\.\d+' || echo "unknown")
    echo -e "${GREEN}✓ KICS successfully installed: $KICS_VERSION${NC}"
else
    echo -e "${RED}✗ KICS installation failed${NC}"
    exit 1
fi

# Check for jq
echo ""
echo "Checking for jq (required for parsing KICS output)..."
if command -v jq &> /dev/null; then
    echo -e "${GREEN}✓ jq is installed${NC}"
else
    echo -e "${YELLOW}⚠ jq is not installed${NC}"
    echo ""
    echo "Please install jq:"
    if [[ "$OS" == "macos" ]]; then
        echo "  brew install jq"
    elif [[ "$OS" == "linux" ]]; then
        echo "  sudo apt-get install jq  # Debian/Ubuntu"
        echo "  sudo dnf install jq      # Fedora/RHEL"
        echo "  sudo pacman -S jq        # Arch"
    fi
fi

# Check for diagnostic-languageserver
echo ""
echo "Checking for diagnostic-languageserver..."
if command -v diagnostic-languageserver &> /dev/null; then
    echo -e "${GREEN}✓ diagnostic-languageserver is installed${NC}"
else
    echo -e "${YELLOW}⚠ diagnostic-languageserver is not installed${NC}"
    echo ""
    echo "Install it via Mason in Neovim:"
    echo "  :Mason"
    echo "  Search for 'diagnosticls' and install it"
fi

# Test KICS
echo ""
echo "Testing KICS installation..."
TEMP_DIR=$(mktemp -d)
cat > "$TEMP_DIR/test.tf" << 'EOF'
resource "aws_s3_bucket" "test" {
  bucket = "my-test-bucket"
  acl    = "public-read"  # This should trigger a KICS warning
}
EOF

echo "Running test scan..."
if kics scan --path "$TEMP_DIR/test.tf" --no-progress --silent 2>/dev/null; then
    echo -e "${GREEN}✓ KICS test scan completed successfully${NC}"
else
    echo -e "${YELLOW}⚠ KICS test scan completed (this is normal)${NC}"
fi

# Clean up
rm -rf "$TEMP_DIR"

echo ""
echo "=========================================="
echo "Installation Complete!"
echo "=========================================="
echo ""
echo "Next steps:"
echo "1. Restart Neovim"
echo "2. Open a Terraform, Kubernetes, or Docker file"
echo "3. KICS will automatically scan for security issues"
echo ""
echo "For more information, see:"
echo "  ~/.config/nvim/docs/KICS_INTEGRATION.md"
echo ""

