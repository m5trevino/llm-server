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

# Function to show progress bar
show_progress() {
    local duration=$1
    local prefix=$2
    local size=40
    local char="▓"
    local empty="░"
  
    echo -ne "${prefix} ["
  
    for ((i=0; i<size; i++)); do
        echo -ne "${empty}"
    done
  
    echo -ne "] 0%"
  
    for ((i=0; i<=size; i++)); do
        sleep 0.1  # Fixed sleep time to avoid bc dependency
        echo -ne "\r${prefix} ["
        
        for ((j=0; j<i; j++)); do
            echo -ne "${CYAN}${char}${NC}"
        done
        
        for ((j=i; j<size; j++)); do
            echo -ne "${empty}"
        done
        
        local percentage=$((i*100/size))
        echo -ne "] ${percentage}%"
    done
    echo -e "\r${prefix} [${CYAN}${char}${char}${char}${char}${char}${char}${char}${char}${char}${char}${char}${char}${char}${char}${char}${char}${char}${char}${char}${char}${char}${char}${char}${char}${char}${char}${char}${char}${char}${char}${char}${char}${char}${char}${char}${char}${char}${char}${char}${char}${char}${NC}] ${GREEN}100%${NC}"
}

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

# Function to print info
print_info() {
    echo -e "${YELLOW}[i] $1${NC}"
}

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    print_error "Please run as root"
    exit 1
fi

# Save current directory
REPO_DIR=$(pwd)
BOLT_DIR="/root/bolt.diy"

# Create requirements.txt if it doesn't exist
if [ ! -f "api-server/requirements.txt" ]; then
    print_error "requirements.txt not found in api-server directory"
    exit 1
fi

print_header "SYSTEM PREPARATION"

# Update system packages
print_step "Updating system packages..."
apt-get update > /dev/null 2>&1
apt-get install -y bc > /dev/null 2>&1  # Install bc for calculations
apt-get upgrade -y > /dev/null 2>&1
show_progress 2 "System update"
print_success "System packages updated"

# Install required packages
print_step "Installing required packages..."
apt-get install -y nano nodejs npm python3.10-venv python3-pip git > /dev/null 2>&1
show_progress 3 "Package installation"
print_success "Required packages installed"

# Install NVM
print_step "Installing Node Version Manager..."
if [ ! -d "$HOME/.nvm" ]; then
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.5/install.sh | bash > /dev/null 2>&1
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
    show_progress 2 "NVM installation"
    print_success "NVM installed"
else
    print_info "NVM already installed"
fi

# Install Node.js LTS
print_step "Installing Node.js LTS..."
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
nvm install --lts > /dev/null 2>&1
show_progress 2 "Node.js installation"
print_success "Node.js $(node -v) installed"

# Install PNPM
print_step "Installing PNPM..."
if ! command -v pnpm &> /dev/null; then
    curl -fsSL https://get.pnpm.io/install.sh | sh - > /dev/null 2>&1
    export PNPM_HOME="/root/.local/share/pnpm"
    export PATH="$PNPM_HOME:$PATH"
    show_progress 2 "PNPM installation"
    print_success "PNPM installed"
else
    print_info "PNPM already installed"
fi

# Install Python virtualenv
print_step "Setting up Python virtual environment..."
pip install virtualenv > /dev/null 2>&1
if [ ! -d "venv" ]; then
    virtualenv venv > /dev/null 2>&1
    show_progress 1 "Virtual environment creation"
    print_success "Python virtual environment created"
else
    print_info "Virtual environment already exists"
fi

# Activate virtual environment
source venv/bin/activate
python -m pip install --upgrade pip > /dev/null 2>&1

# Install Python requirements
print_step "Installing Python requirements..."
pip install -r api-server/requirements.txt > /dev/null 2>&1
show_progress 3 "Python dependencies"
print_success "Python requirements installed"

# Install ngrok
print_step "Installing ngrok..."
if ! command -v ngrok &> /dev/null; then
    wget -q https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-v3-stable-linux-amd64.tgz
    tar -xf ngrok-v3-stable-linux-amd64.tgz > /dev/null 2>&1
    mv ngrok /usr/local/bin > /dev/null 2>&1
    rm ngrok-v3-stable-linux-amd64.tgz
    show_progress 2 "Ngrok installation"
    print_success "Ngrok installed: $(ngrok version)"
else
    print_info "Ngrok already installed: $(ngrok version)"
fi

print_header "BOLT.DIY SETUP"

# Clone bolt.diy if it doesn't exist
if [ ! -d "$BOLT_DIR" ]; then
    print_step "Cloning bolt.diy repository..."
    git clone -b stable https://github.com/stackblitz-labs/bolt.diy "$BOLT_DIR" > /dev/null 2>&1
    show_progress 3 "Repository cloning"
    print_success "bolt.diy cloned successfully"
else
    print_info "bolt.diy already cloned"
fi

# Install bolt.diy dependencies
print_step "Installing bolt.diy dependencies..."
cd "$BOLT_DIR"
export PNPM_HOME="/root/.local/share/pnpm"
export PATH="$PNPM_HOME:$PATH"
pnpm install > /dev/null 2>&1
show_progress 5 "Dependency installation"
print_success "bolt.diy dependencies installed"

# Return to original directory
cd "$REPO_DIR"

print_header "CONFIGURATION"

# Run configuration script
print_step "Running configuration script..."
python configure.py
print_success "Configuration completed"

print_header "PROVIDER SETUP"

# Run setup script
print_step "Setting up LLM providers..."
bash setup.sh > /dev/null 2>&1
show_progress 2 "Provider setup"
print_success "LLM providers set up successfully"

# Create helper scripts
print_step "Creating helper scripts..."

# Create start-api.sh
cat > "${REPO_DIR}/start-api.sh" << 'EOF'
#!/bin/bash
# Cyberpunk-themed colors
CYAN='\033[0;36m'
GREEN='\033[0;32m'
PURPLE='\033[0;35m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BOLD='\033[1m'
NC='\033[0m' # No Color

echo -e "${PURPLE}${BOLD}Starting LLM API Server...${NC}"
echo -e "${CYAN}Model: $1${NC}"

# Activate virtual environment
source venv/bin/activate

# Load environment variables
if [ -f ".env" ]; then
    export $(grep -v '^#' .env | xargs)
fi

# Start the API server
cd "$(dirname "$0")/api-server"
python run.py --model "$1"
EOF

# Create start-bolt.sh
cat > "${REPO_DIR}/start-bolt.sh" << 'EOF'
#!/bin/bash
# Cyberpunk-themed colors
CYAN='\033[0;36m'
GREEN='\033[0;32m'
PURPLE='\033[0;35m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BOLD='\033[1m'
NC='\033[0m' # No Color

echo -e "${PURPLE}${BOLD}Starting bolt.diy...${NC}"
echo -e "${CYAN}Server will be available at http://localhost:5173${NC}"

# Set up Node environment
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
export PNPM_HOME="/root/.local/share/pnpm"
export PATH="$PNPM_HOME:$PATH"

# Start bolt.diy
cd /root/bolt.diy
pnpm run dev
EOF

# Create expose-bolt.sh
cat > "${REPO_DIR}/expose-bolt.sh" << 'EOF'
#!/bin/bash
# Cyberpunk-themed colors
CYAN='\033[0;36m'
GREEN='\033[0;32m'
PURPLE='\033[0;35m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BOLD='\033[1m'
NC='\033[0m' # No Color

echo -e "${PURPLE}${BOLD}Exposing bolt.diy via ngrok...${NC}"

# Load environment variables
if [ -f ".env" ]; then
    export $(grep -v '^#' .env | xargs)
fi

if [ -z "$NGROK_AUTH_TOKEN" ]; then
    echo -e "${RED}Error: NGROK_AUTH_TOKEN is not set. Please run configure.py first.${NC}"
    exit 1
fi

# Configure ngrok
echo -e "${CYAN}Configuring ngrok with auth token...${NC}"
ngrok config add-authtoken "$NGROK_AUTH_TOKEN"

# Start ngrok
echo -e "${GREEN}Starting ngrok tunnel to port 5173...${NC}"
echo -e "${YELLOW}Copy the ngrok URL from below to access bolt.diy from anywhere${NC}"
ngrok http 5173
EOF

chmod +x "${REPO_DIR}/start-api.sh"
chmod +x "${REPO_DIR}/start-bolt.sh"
chmod +x "${REPO_DIR}/expose-bolt.sh"

show_progress 1 "Script creation"
print_success "Helper scripts created"

print_header "SETUP COMPLETE"

echo -e "${GREEN}${BOLD}Your RunPod environment is now ready!${NC}"
echo -e "\n${CYAN}To start the API server:${NC}"
echo -e "  ${YELLOW}./start-api.sh deepseek${NC}  # or ${YELLOW}./start-api.sh codellama${NC}"
echo -e "\n${CYAN}To start bolt.diy:${NC}"
echo -e "  ${YELLOW}./start-bolt.sh${NC}"
echo -e "\n${CYAN}To expose bolt.diy to the internet:${NC}"
echo -e "  ${YELLOW}./expose-bolt.sh${NC}"
echo -e "\n${PURPLE}${BOLD}In bolt.diy, select 'DeepseekLocal' or 'CodeLlamaLocal' provider.${NC}"
echo -e "\n${GREEN}${BOLD}Enjoy your local LLM experience!${NC}\n"