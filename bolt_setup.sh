#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${CYAN}Setting up bolt.diy...${NC}"

# Install required packages
echo -e "${YELLOW}Installing required packages...${NC}"
apt-get update
apt-get install -y nodejs npm git

# Install NVM
echo -e "${YELLOW}Installing Node Version Manager...${NC}"
if [ ! -d "$HOME/.nvm" ]; then
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.5/install.sh | bash
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
    echo -e "${GREEN}NVM installed${NC}"
else
    echo -e "${YELLOW}NVM already installed${NC}"
fi

# Install Node.js LTS
echo -e "${YELLOW}Installing Node.js LTS...${NC}"
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
nvm install --lts
echo -e "${GREEN}Node.js $(node -v) installed${NC}"

# Install PNPM
echo -e "${YELLOW}Installing PNPM...${NC}"
if ! command -v pnpm &> /dev/null; then
    curl -fsSL https://get.pnpm.io/install.sh | sh -
    export PNPM_HOME="/root/.local/share/pnpm"
    export PATH="$PNPM_HOME:$PATH"
    echo -e "${GREEN}PNPM installed${NC}"
else
    echo -e "${YELLOW}PNPM already installed${NC}"
fi

# Clone bolt.diy if it doesn't exist
BOLT_DIR="/root/bolt.diy"
if [ ! -d "$BOLT_DIR" ]; then
    echo -e "${YELLOW}Cloning bolt.diy repository...${NC}"
    cd /root
    git clone -b stable https://github.com/stackblitz-labs/bolt.diy.git
    echo -e "${GREEN}bolt.diy cloned successfully${NC}"
else
    echo -e "${YELLOW}bolt.diy already exists${NC}"
fi

# Install bolt.diy dependencies
echo -e "${YELLOW}Installing bolt.diy dependencies...${NC}"
cd "$BOLT_DIR"
export PNPM_HOME="/root/.local/share/pnpm"
export PATH="$PNPM_HOME:$PATH"
if command -v pnpm &> /dev/null; then
    pnpm install
else
    npm install
fi
echo -e "${GREEN}bolt.diy dependencies installed${NC}"

echo -e "${GREEN}bolt.diy setup completed!${NC}"