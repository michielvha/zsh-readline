#!/bin/bash
# Simple installation script for zsh-readline

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_FILE="$SCRIPT_DIR/zsh-readline.plugin.zsh"
ZSHRC="$HOME/.zshrc"

echo -e "${GREEN}Installing zsh-readline...${NC}"

# Check if plugin file exists
if [[ ! -f "$PLUGIN_FILE" ]]; then
    echo -e "${RED}Error: $PLUGIN_FILE not found!${NC}"
    exit 1
fi

# Check if already installed
if grep -q "zsh-readline.plugin.zsh" "$ZSHRC" 2>/dev/null; then
    echo -e "${YELLOW}zsh-readline appears to be already installed in $ZSHRC${NC}"
    read -p "Do you want to reinstall? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Installation cancelled."
        exit 0
    fi
    # Remove old installation
    sed -i '/zsh-readline.plugin.zsh/d' "$ZSHRC"
fi

# Add to .zshrc
echo "" >> "$ZSHRC"
echo "# zsh-readline plugin" >> "$ZSHRC"
echo "source $PLUGIN_FILE" >> "$ZSHRC"

echo -e "${GREEN}✓ Added zsh-readline to $ZSHRC${NC}"
echo -e "${GREEN}Installation complete!${NC}"
echo ""
echo -e "${YELLOW}To use it, either:${NC}"
echo -e "  1. Restart your terminal, or"
echo -e "  2. Run: ${GREEN}source $ZSHRC${NC}"
echo ""
echo -e "${YELLOW}Optional: Configure in $ZSHRC before the source line:${NC}"
echo -e "  ${GREEN}ZSH_READLINE_MAX_PREDICTIONS=15${NC}"
echo -e "  ${GREEN}ZSH_READLINE_MIN_INPUT=2${NC}"

