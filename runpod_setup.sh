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

print_step "Running configuration..."
chmod +x configure.sh
./configure.sh
print_success "Configuration completed"

print_header "SETUP COMPLETE"
echo -e "${GREEN}All setup scripts have been executed successfully!${NC}"
echo -e "${YELLOW}You can now:${NC}"
echo -e "  ${CYAN}- Launch bolt.diy: ${GREEN}./launch_bolt.sh${NC}"
echo -e "  ${CYAN}- Expose bolt.diy to the internet: ${GREEN}./expose.sh${NC}"
echo -e "  ${CYAN}- Start the LLM server: ${GREEN}./server.sh${NC}"