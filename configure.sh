#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
BOLD='\033[1m'
NC='\033[0m' # No Color

echo -e "${PURPLE}${BOLD}Configuration Wizard${NC}"

REPO_DIR=$(pwd)
ENV_FILE="${REPO_DIR}/.env"
TOKENS_FILE="${REPO_DIR}/.tokens"

# Function to get a configuration value
get_config() {
    local key=$1
    local default=$2
    local prompt=$3
    local current=""
    
    # Check if the key exists in the .env file
    if [ -f "$ENV_FILE" ]; then
        current=$(grep "^$key=" "$ENV_FILE" | cut -d= -f2)
    fi
    
    # If current is empty, use default
    if [ -z "$current" ]; then
        current=$default
    fi
    
    # Prompt user for input
    echo -e "${YELLOW}$prompt (current: $current):${NC}"
    read -r value
    
    # If user didn't enter anything, use current value
    if [ -z "$value" ]; then
        value=$current
    fi
    
    echo "$value"
}

# Function to update a configuration value
update_config() {
    local key=$1
    local value=$2
    
    # Check if the key exists in the .env file
    if [ -f "$ENV_FILE" ] && grep -q "^$key=" "$ENV_FILE"; then
        # Update the key - fixed the sed command here
        sed -i "s|^$key=.*|$key=$value|" "$ENV_FILE"
    else
        # Add the key
        echo "$key=$value" >> "$ENV_FILE"
    fi
}

# Function to save a token
save_token() {
    local key=$1
    local value=$2
    
    # Create tokens file if it doesn't exist
    if [ ! -f "$TOKENS_FILE" ]; then
        touch "$TOKENS_FILE"
        chmod 600 "$TOKENS_FILE"
    fi
    
    # Check if the key exists in the tokens file
    if grep -q "^$key=" "$TOKENS_FILE"; then
        # Update the key - fixed the sed command here
        sed -i "s|^$key=.*|$key=$value|" "$TOKENS_FILE"
    else
        # Add the key
        echo "$key=$value" >> "$TOKENS_FILE"
    fi
}

# Main configuration menu
echo -e "${CYAN}Welcome to the configuration wizard!${NC}"
echo -e "${CYAN}This wizard will help you configure your LLM server.${NC}"

# Model configuration
echo -e "\n${PURPLE}${BOLD}Model Configuration${NC}"
model=$(get_config "MODEL_NAME" "codellama/CodeLlama-7b-Instruct-hf" "Enter the model name")
update_config "MODEL_NAME" "$model"

ctx=$(get_config "DEFAULT_NUM_CTX" "4096" "Enter the context window size")
update_config "DEFAULT_NUM_CTX" "$ctx"

max_tokens=$(get_config "DEFAULT_MAX_TOKENS" "2000" "Enter the maximum tokens to generate")
update_config "DEFAULT_MAX_TOKENS" "$max_tokens"

temp=$(get_config "DEFAULT_TEMPERATURE" "0.7" "Enter the temperature")
update_config "DEFAULT_TEMPERATURE" "$temp"

top_p=$(get_config "DEFAULT_TOP_P" "0.95" "Enter the top_p value")
update_config "DEFAULT_TOP_P" "$top_p"

# API Keys
echo -e "\n${PURPLE}${BOLD}API Keys${NC}"
echo -e "${CYAN}Do you want to configure HuggingFace API key? (y/n)${NC}"
read -r configure_hf
if [[ $configure_hf == "y" || $configure_hf == "Y" ]]; then
    hf_key=$(get_config "HUGGINGFACE_API_KEY" "" "Enter your HuggingFace API key")
    update_config "HUGGINGFACE_API_KEY" "$hf_key"
    save_token "HUGGINGFACE_API_KEY" "$hf_key"
fi

# Ngrok configuration
echo -e "\n${PURPLE}${BOLD}Ngrok Configuration${NC}"
echo -e "${CYAN}Do you want to configure Ngrok? (y/n)${NC}"
read -r configure_ngrok
if [[ $configure_ngrok == "y" || $configure_ngrok == "Y" ]]; then
    ngrok_token=$(get_config "NGROK_AUTH_TOKEN" "" "Enter your Ngrok auth token")
    update_config "NGROK_AUTH_TOKEN" "$ngrok_token"
    save_token "NGROK_AUTH_TOKEN" "$ngrok_token"
    
    ngrok_region=$(get_config "NGROK_REGION" "us" "Enter your Ngrok region (us, eu, ap, au, sa, jp, in)")
    update_config "NGROK_REGION" "$ngrok_region"
fi

echo -e "\n${GREEN}Configuration completed!${NC}"
echo -e "${CYAN}Your settings have been saved to ${ENV_FILE}${NC}"