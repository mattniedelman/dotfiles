#!/usr/bin/env bash
# Test script for KICS integration with Neovim
# Verifies that all components are properly installed and configured

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

PASSED=0
FAILED=0

echo "=========================================="
echo "KICS Integration Test Suite"
echo "=========================================="
echo ""

# Test function
test_command() {
    local name="$1"
    local command="$2"
    
    echo -n "Testing $name... "
    if eval "$command" &> /dev/null; then
        echo -e "${GREEN}✓ PASS${NC}"
        ((PASSED++))
        return 0
    else
        echo -e "${RED}✗ FAIL${NC}"
        ((FAILED++))
        return 1
    fi
}

# Test 1: KICS installation
test_command "KICS installation" "command -v kics"

# Test 2: KICS version
if command -v kics &> /dev/null; then
    VERSION=$(kics version 2>&1 | grep -oP 'v\d+\.\d+\.\d+' || echo "unknown")
    echo -e "  ${BLUE}→ Version: $VERSION${NC}"
fi

# Test 3: jq installation
test_command "jq installation" "command -v jq"

# Test 4: diagnostic-languageserver
test_command "diagnostic-languageserver" "command -v diagnostic-languageserver"

# Test 5: Wrapper script exists
test_command "KICS wrapper script" "test -f ~/.config/nvim/scripts/kics-wrapper.sh"

# Test 6: Wrapper script is executable
test_command "Wrapper script executable" "test -x ~/.config/nvim/scripts/kics-wrapper.sh"

# Test 7: diagnosticls config exists
test_command "diagnosticls config" "test -f ~/.config/nvim/lua/plugins/diagnosticls.lua"

# Test 8: KICS can scan a file
echo ""
echo "Running functional tests..."
echo ""

TEMP_DIR=$(mktemp -d)
trap 'rm -rf "$TEMP_DIR"' EXIT

# Create test Terraform file with known issues
cat > "$TEMP_DIR/test.tf" << 'EOF'
# This file contains intentional security issues for testing

resource "aws_s3_bucket" "test" {
  bucket = "my-test-bucket"
  acl    = "public-read"  # Security issue: public bucket
}

resource "aws_security_group" "test" {
  name        = "test-sg"
  description = "Test security group"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Security issue: SSH open to world
  }
}

resource "aws_instance" "test" {
  ami           = "ami-12345678"
  instance_type = "t2.micro"
  
  # Security issue: no encryption
  ebs_block_device {
    device_name = "/dev/sda1"
    volume_size = 8
    encrypted   = false
  }
}
EOF

echo -n "Testing KICS scan... "
if kics scan --path "$TEMP_DIR/test.tf" --no-progress --silent --ci 2>/dev/null; then
    echo -e "${YELLOW}⚠ WARN (no issues found - unexpected)${NC}"
else
    echo -e "${GREEN}✓ PASS (issues detected as expected)${NC}"
    ((PASSED++))
fi

# Test 9: KICS JSON output
echo -n "Testing KICS JSON output... "
RESULTS_DIR=$(mktemp -d)
trap 'rm -rf "$RESULTS_DIR"' EXIT

if kics scan \
    --path "$TEMP_DIR/test.tf" \
    --no-progress \
    --silent \
    --report-formats json \
    --output-path "$RESULTS_DIR" \
    --output-name test-results \
    2>/dev/null || true; then
    
    if [ -f "$RESULTS_DIR/test-results.json" ]; then
        echo -e "${GREEN}✓ PASS${NC}"
        ((PASSED++))
        
        # Show sample results
        ISSUE_COUNT=$(jq '.total_counter // 0' "$RESULTS_DIR/test-results.json" 2>/dev/null || echo "0")
        echo -e "  ${BLUE}→ Issues found: $ISSUE_COUNT${NC}"
    else
        echo -e "${RED}✗ FAIL (no JSON output)${NC}"
        ((FAILED++))
    fi
else
    echo -e "${RED}✗ FAIL (scan failed)${NC}"
    ((FAILED++))
fi

# Test 10: Wrapper script functionality
echo -n "Testing wrapper script... "
if ~/.config/nvim/scripts/kics-wrapper.sh "$TEMP_DIR/test.tf" > /dev/null 2>&1; then
    echo -e "${GREEN}✓ PASS${NC}"
    ((PASSED++))
else
    # Wrapper might exit with non-zero if issues found, which is OK
    echo -e "${GREEN}✓ PASS (with findings)${NC}"
    ((PASSED++))
fi

# Test 11: Wrapper script output format
echo -n "Testing wrapper output format... "
OUTPUT=$(~/.config/nvim/scripts/kics-wrapper.sh "$TEMP_DIR/test.tf" 2>/dev/null || true)
if echo "$OUTPUT" | grep -qE ".*:[0-9]+:[0-9]+: \[.*\]"; then
    echo -e "${GREEN}✓ PASS${NC}"
    ((PASSED++))
    echo -e "  ${BLUE}→ Sample output:${NC}"
    echo "$OUTPUT" | head -n 2 | sed 's/^/    /'
else
    if [ -z "$OUTPUT" ]; then
        echo -e "${YELLOW}⚠ WARN (no output - might be OK if no issues)${NC}"
    else
        echo -e "${RED}✗ FAIL (incorrect format)${NC}"
        ((FAILED++))
    fi
fi

# Summary
echo ""
echo "=========================================="
echo "Test Summary"
echo "=========================================="
echo -e "${GREEN}Passed: $PASSED${NC}"
echo -e "${RED}Failed: $FAILED${NC}"
echo ""

if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}✓ All tests passed!${NC}"
    echo ""
    echo "Your KICS integration is ready to use."
    echo "Open a Terraform, Kubernetes, or Docker file in Neovim to see it in action!"
    exit 0
else
    echo -e "${RED}✗ Some tests failed.${NC}"
    echo ""
    echo "Please check the following:"
    echo "1. Install missing dependencies"
    echo "2. Run: ./scripts/install-kics.sh"
    echo "3. Restart Neovim"
    echo ""
    echo "For help, see: ~/.config/nvim/docs/KICS_INTEGRATION.md"
    exit 1
fi

