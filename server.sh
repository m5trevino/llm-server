#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
BOLD='\033[1m'
NC='\033[0m' # No Color

echo -e "${PURPLE}${BOLD}LLM Server Launcher${NC}"

REPO_DIR=$(pwd)
API_SERVER_DIR="${REPO_DIR}/api-server"
ENV_FILE="${REPO_DIR}/.env"
TOKENS_FILE="${REPO_DIR}/.tokens"

# Check if Python virtual environment exists
if [ ! -d "${REPO_DIR}/venv" ]; then
    echo -e "${RED}Python virtual environment not found.${NC}"
    echo -e "${YELLOW}Please run python_setup.sh first.${NC}"
    exit 1
fi

# Activate virtual environment
source "${REPO_DIR}/venv/bin/activate"

# Check for HuggingFace API key
HF_API_KEY=""

# Try to get key from .env file
if [ -f "$ENV_FILE" ]; then
    HF_API_KEY=$(grep "^HUGGINGFACE_API_KEY=" "$ENV_FILE" | cut -d= -f2)
fi

# Try to get key from .tokens file if not found in .env
if [ -z "$HF_API_KEY" ] && [ -f "$TOKENS_FILE" ]; then
    HF_API_KEY=$(grep "^HUGGINGFACE_API_KEY=" "$TOKENS_FILE" | cut -d= -f2)
fi

# If still not found, prompt user
if [ -z "$HF_API_KEY" ]; then
    echo -e "${YELLOW}HuggingFace API key not found.${NC}"
    echo -e "${CYAN}Do you want to enter a HuggingFace API key? (y/n)${NC}"
    read -r enter_key
    
    if [[ $enter_key == "y" || $enter_key == "Y" ]]; then
        echo -e "${CYAN}Please enter your HuggingFace API key:${NC}"
        read -r HF_API_KEY
        
        # Save the key
        if [ ! -f "$TOKENS_FILE" ]; then
            touch "$TOKENS_FILE"
            chmod 600 "$TOKENS_FILE"
        fi
        echo "HUGGINGFACE_API_KEY=$HF_API_KEY" >> "$TOKENS_FILE"
        
        # Also update .env file
        if [ -f "$ENV_FILE" ]; then
            if grep -q "^HUGGINGFACE_API_KEY=" "$ENV_FILE"; then
                sed -i "s|^HUGGINGFACE_API_KEY=.*|HUGGINGFACE_API_KEY=$HF_API_KEY|" "$ENV_FILE"
            else
                echo "HUGGINGFACE_API_KEY=$HF_API_KEY" >> "$ENV_FILE"
            fi
        fi
    fi
fi

# Export HF API key if available
if [ ! -z "$HF_API_KEY" ]; then
    export HUGGINGFACE_API_KEY="$HF_API_KEY"
    echo -e "${GREEN}HuggingFace API key set.${NC}"
else
    echo -e "${YELLOW}No HuggingFace API key provided. Some models may not be available.${NC}"
fi

# Choose model to run
echo -e "\n${CYAN}Which model would you like to run?${NC}"
echo -e "  ${YELLOW}1) CodeLlama (7B, 4-bit quantized)${NC}"
echo -e "  ${YELLOW}2) DeepSeek Coder (6.7B, 4-bit quantized)${NC}"
read -r model_choice

case $model_choice in
    1)
        MODEL="codellama"
        echo -e "${GREEN}Selected CodeLlama model.${NC}"
        ;;
    2)
        MODEL="deepseek"
        echo -e "${GREEN}Selected DeepSeek Coder model.${NC}"
        ;;
    *)
        echo -e "${RED}Invalid choice. Defaulting to CodeLlama.${NC}"
        MODEL="codellama"
        ;;
esac

# Start the server
echo -e "\n${CYAN}Starting LLM server with $MODEL model...${NC}"
echo -e "${YELLOW}Server will be available at http://localhost:8000${NC}"
echo -e "${YELLOW}Press Ctrl+C to stop the server${NC}"

cd "$API_SERVER_DIR"
python run.py --model "$MODEL"