#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
BOLD='\033[1m'
NC='\033[0m' # No Color

echo -e "${PURPLE}${BOLD}Launching bolt.diy...${NC}"

# Set up Node environment
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
export PNPM_HOME="/root/.local/share/pnpm"
export PATH="$PNPM_HOME:$PATH"

# Check if bolt.diy exists
BOLT_DIR="/root/bolt.diy"
if [ ! -d "$BOLT_DIR" ]; then
    echo -e "${RED}bolt.diy directory not found at ${BOLT_DIR}${NC}"
    echo -e "${YELLOW}Please run bolt_setup.sh first.${NC}"
    exit 1
fi

# Start bolt.diy
echo -e "${CYAN}Starting bolt.diy...${NC}"
echo -e "${YELLOW}Server will be available at http://localhost:5173${NC}"
cd "$BOLT_DIR"

# Check if pnpm is available
if command -v pnpm &> /dev/null; then
    pnpm run dev
else
    npm run dev
fi