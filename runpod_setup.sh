#!/bin/bash

# Cyberpunk-themed colors
CYAN='\033[0;36m'
GREEN='\033[0;32m'
PURPLE='\033[0;35m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# ASCII Art Banner
echo -e "${PURPLE}"
cat << "EOF"
 _    _    __  __    ____  ____ ____    ____ ____
| |   | |   |  \/  |  / ___|| ____|  _ \ \   / / ____|  _ \ 
| |   | |   | |\/| |  \___ \|  _| | |_) \ \ / /|  _| | |_) |
| |___| |___| |  | |   ___) | |___|  _ < \ V / | |___|  _ < 
|____|____|_|  |_|  |____/|____|_| \_\ \_/  |____|_| \_\
  
EOF
echo -e "${CYAN}${BOLD}RunPod Setup for bolt.diy with Local LLM Integration${NC}\n"

# Function to print section header
print_header() {
    echo -e "\n${PURPLE}${BOLD}[+] $1 ${NC}\n"
}

# Function to print step
print_step() {
    echo -e "${CYAN}[*] $1${NC}"
}

# Function to print success
print_success() {
    echo -e "${GREEN}[✓] $1${NC}"
}

# Function to print error
print_error() {
    echo -e "${RED}[✗] $1${NC}"
}

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    print_error "Please run as root"
    exit 1
fi

# Create base directory structure
REPO_DIR=$(pwd)
mkdir -p "${REPO_DIR}/api-server"
mkdir -p "${REPO_DIR}/llm-providers/providers"

# Create .env and .tokens files if they don't exist
ENV_FILE="${REPO_DIR}/.env"
TOKENS_FILE="${REPO_DIR}/.tokens"

if [ ! -f "$ENV_FILE" ]; then
    touch "$ENV_FILE"
    chmod 600 "$ENV_FILE"
fi

if [ ! -f "$TOKENS_FILE" ]; then
    touch "$TOKENS_FILE"
    chmod 600 "$TOKENS_FILE"
fi

print_header "TOKEN CONFIGURATION"

# Ask for HuggingFace API token
print_step "Setting up HuggingFace API token..."
echo -e "${YELLOW}Do you want to configure a HuggingFace API token? (recommended) (y/n)${NC}"
read -r configure_hf
if [[ $configure_hf == "y" || $configure_hf == "Y" ]]; then
    echo -e "${CYAN}Please enter your HuggingFace API token:${NC}"
    read -r hf_token
    
    # Save to both files
    if grep -q "^HUGGINGFACE_API_KEY=" "$ENV_FILE"; then
        sed -i "s|^HUGGINGFACE_API_KEY=.*|HUGGINGFACE_API_KEY=$hf_token|" "$ENV_FILE"
    else
        echo "HUGGINGFACE_API_KEY=$hf_token" >> "$ENV_FILE"
    fi
    
    if grep -q "^HUGGINGFACE_API_KEY=" "$TOKENS_FILE"; then
        sed -i "s|^HUGGINGFACE_API_KEY=.*|HUGGINGFACE_API_KEY=$hf_token|" "$TOKENS_FILE"
    else
        echo "HUGGINGFACE_API_KEY=$hf_token" >> "$TOKENS_FILE"
    fi
    
    print_success "HuggingFace API token saved"
else
    print_step "Skipping HuggingFace API token configuration"
fi

# Ask for ngrok token
print_step "Setting up ngrok authentication token..."
echo -e "${YELLOW}Do you want to configure ngrok for exposing bolt.diy to the internet? (y/n)${NC}"
read -r configure_ngrok
if [[ $configure_ngrok == "y" || $configure_ngrok == "Y" ]]; then
    echo -e "${CYAN}Please enter your ngrok authentication token:${NC}"
    read -r ngrok_token
    
    # Save to both files
    if grep -q "^NGROK_AUTH_TOKEN=" "$ENV_FILE"; then
        sed -i "s|^NGROK_AUTH_TOKEN=.*|NGROK_AUTH_TOKEN=$ngrok_token|" "$ENV_FILE"
    else
        echo "NGROK_AUTH_TOKEN=$ngrok_token" >> "$ENV_FILE"
    fi
    
    if grep -q "^NGROK_AUTH_TOKEN=" "$TOKENS_FILE"; then
        sed -i "s|^NGROK_AUTH_TOKEN=.*|NGROK_AUTH_TOKEN=$ngrok_token|" "$TOKENS_FILE"
    else
        echo "NGROK_AUTH_TOKEN=$ngrok_token" >> "$TOKENS_FILE"
    fi
    
    # Ask for ngrok region
    echo -e "${CYAN}Please enter your preferred ngrok region (us, eu, ap, au, sa, jp, in) [default: us]:${NC}"
    read -r ngrok_region
    ngrok_region=${ngrok_region:-us}
    
    if grep -q "^NGROK_REGION=" "$ENV_FILE"; then
        sed -i "s|^NGROK_REGION=.*|NGROK_REGION=$ngrok_region|" "$ENV_FILE"
    else
        echo "NGROK_REGION=$ngrok_region" >> "$ENV_FILE"
    fi
    
    print_success "ngrok configuration saved"
else
    print_step "Skipping ngrok configuration"
fi

print_header "SYSTEM PREPARATION"

# Update system packages
print_step "Updating system packages..."
apt-get update
apt-get upgrade -y
apt-get install -y nano

print_success "System packages updated"

# Run the modular scripts
print_header "RUNNING SETUP SCRIPTS"

print_step "Setting up bolt.diy..."
chmod +x bolt_setup.sh
./bolt_setup.sh
print_success "bolt.diy setup completed"

print_step "Setting up Python environment..."
chmod +x python_setup.sh
./python_setup.sh
print_success "Python environment setup completed"

print_step "Customizing bolt.diy..."
chmod +x bolt_custom.sh
./bolt_custom.sh
print_success "bolt.diy customization completed"

print_step "Setting up server components..."
chmod +x server_setup.sh
./server_setup.sh
print_success "Server setup completed"

print_step "Running additional configuration..."
chmod +x configure.sh
./configure.sh
print_success "Configuration completed"

print_header "SETUP COMPLETE"
echo -e "${GREEN}All setup scripts have been executed successfully!${NC}"
echo -e "${YELLOW}You can now:${NC}"
echo -e "  ${CYAN}- Launch bolt.diy: ${GREEN}./launch_bolt.sh${NC}"
echo -e "  ${CYAN}- Expose bolt.diy to the internet: ${GREEN}./expose.sh${NC}"
echo -e "  ${CYAN}- Start the LLM server: ${GREEN}./server.sh${NC}"