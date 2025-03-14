#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
BOLD='\033[1m'
NC='\033[0m' # No Color

echo -e "${PURPLE}${BOLD}Exposing bolt.diy to the internet...${NC}"

# Check if ngrok is installed
if ! command -v ngrok &> /dev/null; then
    echo -e "${YELLOW}ngrok is not installed. Installing...${NC}"
    wget https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-v3-stable-linux-amd64.tgz
    tar -xvzf ngrok-v3-stable-linux-amd64.tgz
    mv ngrok /usr/local/bin
    rm ngrok-v3-stable-linux-amd64.tgz
    echo -e "${GREEN}ngrok installed: $(ngrok version)${NC}"
else
    echo -e "${GREEN}ngrok already installed: $(ngrok version)${NC}"
fi

# Load environment variables
REPO_DIR=$(pwd)
ENV_FILE="${REPO_DIR}/.env"
TOKENS_FILE="${REPO_DIR}/.tokens"

# Check for ngrok auth token
NGROK_AUTH_TOKEN=""

# Try to get token from .env file
if [ -f "$ENV_FILE" ]; then
    NGROK_AUTH_TOKEN=$(grep "^NGROK_AUTH_TOKEN=" "$ENV_FILE" | cut -d= -f2)
fi

# Try to get token from .tokens file if not found in .env
if [ -z "$NGROK_AUTH_TOKEN" ] && [ -f "$TOKENS_FILE" ]; then
    NGROK_AUTH_TOKEN=$(grep "^NGROK_AUTH_TOKEN=" "$TOKENS_FILE" | cut -d= -f2)
fi

# If still not found, prompt user
if [ -z "$NGROK_AUTH_TOKEN" ]; then
    echo -e "${YELLOW}Ngrok auth token not found.${NC}"
    echo -e "${CYAN}Please enter your ngrok auth token:${NC}"
    read -r NGROK_AUTH_TOKEN
    
    # Save the token
    if [ ! -f "$TOKENS_FILE" ]; then
        touch "$TOKENS_FILE"
        chmod 600 "$TOKENS_FILE"
    fi
    echo "NGROK_AUTH_TOKEN=$NGROK_AUTH_TOKEN" >> "$TOKENS_FILE"
    
    # Also update .env file
    if [ -f "$ENV_FILE" ]; then
        if grep -q "^NGROK_AUTH_TOKEN=" "$ENV_FILE"; then
            sed -i "s|^NGROK_AUTH_TOKEN=.*|NGROK_AUTH_TOKEN=$NGROK_AUTH_TOKEN|" "$ENV_FILE"
        else
            echo "NGROK_AUTH_TOKEN=$NGROK_AUTH_TOKEN" >> "$ENV_FILE"
        fi
    fi
fi

# Get ngrok region
NGROK_REGION="us"
if [ -f "$ENV_FILE" ]; then
    REGION_FROM_ENV=$(grep "^NGROK_REGION=" "$ENV_FILE" | cut -d= -f2)
    if [ ! -z "$REGION_FROM_ENV" ]; then
        NGROK_REGION=$REGION_FROM_ENV
    fi
fi

# Configure ngrok
echo -e "${CYAN}Configuring ngrok...${NC}"
ngrok config add-authtoken "$NGROK_AUTH_TOKEN"

# Start ngrok
echo -e "${CYAN}Starting ngrok tunnel to expose bolt.diy...${NC}"
echo -e "${YELLOW}bolt.diy should be running on port 5173${NC}"
echo -e "${YELLOW}Press Ctrl+C to stop the tunnel${NC}"

# Start ngrok in the foreground
ngrok http --region="$NGROK_REGION" 5173