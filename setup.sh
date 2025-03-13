#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Setting up Local LLM API Server for bolt.diy on RunPod...${NC}"

# Define paths for RunPod environment
REPO_DIR=$(pwd)
BOLT_DIR="/root/bolt.diy"
PROVIDERS_DIR="${BOLT_DIR}/app/lib/modules/llm/providers"

# Check if bolt.diy directory exists
if [ ! -d "${BOLT_DIR}" ]; then
    echo -e "${RED}bolt.diy directory not found at ${BOLT_DIR}${NC}"
    echo -e "${YELLOW}Would you like to clone bolt.diy repository? (y/n)${NC}"
    read -r clone_bolt
    
    if [[ $clone_bolt == "y" || $clone_bolt == "Y" ]]; then
        echo -e "${YELLOW}Cloning bolt.diy repository...${NC}"
        cd /root
        git clone https://github.com/stackblitz/bolt.diy.git
        cd "${REPO_DIR}"
        
        # Install dependencies
        echo -e "${YELLOW}Installing bolt.diy dependencies...${NC}"
        cd "${BOLT_DIR}"
        npm install
        cd "${REPO_DIR}"
    else
        echo -e "${RED}Please clone bolt.diy repository and run this script again.${NC}"
        exit 1
    fi
fi

# Check if providers directory exists
if [ ! -d "${PROVIDERS_DIR}" ]; then
    echo -e "${YELLOW}Creating providers directory...${NC}"
    mkdir -p "${PROVIDERS_DIR}"
fi

# Install API server requirements
echo -e "${YELLOW}Installing API server requirements...${NC}"
pip install -r "${REPO_DIR}/api-server/requirements.txt"

# Copy provider files
echo -e "${YELLOW}Copying provider files to bolt.diy...${NC}"
cp "${REPO_DIR}/llm-providers/providers/deepseek-local.ts" "${PROVIDERS_DIR}/"
cp "${REPO_DIR}/llm-providers/providers/codellama-local.ts" "${PROVIDERS_DIR}/"

# Update vite.config.ts to allow ngrok connections
echo -e "${YELLOW}Updating vite.config.ts to allow ngrok connections...${NC}"
if [ -f "${BOLT_DIR}/vite.config.ts" ]; then
    # Check if ngrok is already allowed
    if ! grep -q "allowedHosts: \['.ngrok-free.app'\]" "${BOLT_DIR}/vite.config.ts"; then
        # Add ngrok to allowed hosts
        sed -i 's/server: {/server: {\n      allowedHosts: [".ngrok-free.app"],\n      host: true, \/\/ Allow external access/' "${BOLT_DIR}/vite.config.ts"
    fi
fi

# Add environment variables to bolt.diy .env file
echo -e "${YELLOW}Adding environment variables to bolt.diy .env file...${NC}"
ENV_FILE="${BOLT_DIR}/.env"

if [ ! -f "$ENV_FILE" ]; then
    touch "$ENV_FILE"
fi

# Add environment variables if they don't exist
grep -q "DEEPSEEK_LOCAL_API_BASE_URL" "$ENV_FILE" || echo "DEEPSEEK_LOCAL_API_BASE_URL=http://localhost:8000/v1" >> "$ENV_FILE"
grep -q "CODELLAMA_LOCAL_API_BASE_URL" "$ENV_FILE" || echo "CODELLAMA_LOCAL_API_BASE_URL=http://localhost:8000/v1" >> "$ENV_FILE"

# Create a simple script to start the API server
cat > "${REPO_DIR}/start-api.sh" << 'EOF'
#!/bin/bash
cd "$(dirname "$0")/api-server"
python run.py --model "$1"
EOF

chmod +x "${REPO_DIR}/start-api.sh"

# Create a simple script to start bolt.diy
cat > "${REPO_DIR}/start-bolt.sh" << 'EOF'
#!/bin/bash
cd /root/bolt.diy
npm run dev
EOF

chmod +x "${REPO_DIR}/start-bolt.sh"

# Create a script to expose bolt.diy via ngrok
cat > "${REPO_DIR}/expose-bolt.sh" << 'EOF'
#!/bin/bash
# Load environment variables
source /root/.env

if [ -z "$NGROK_AUTH_TOKEN" ]; then
    echo "Error: NGROK_AUTH_TOKEN is not set. Please run configure.py first."
    exit 1
fi

# Configure ngrok
ngrok config add-authtoken "$NGROK_AUTH_TOKEN"

# Start ngrok
ngrok http 5173
EOF

chmod +x "${REPO_DIR}/expose-bolt.sh"

echo -e "${GREEN}Setup complete!${NC}"
echo -e "${YELLOW}To run the API server:${NC}"
echo -e "  ${GREEN}./start-api.sh deepseek${NC}  # or ${GREEN}./start-api.sh codellama${NC}"
echo -e "${YELLOW}To start bolt.diy:${NC}"
echo -e "  ${GREEN}./start-bolt.sh${NC}"
echo -e "${YELLOW}To expose bolt.diy to the internet:${NC}"
echo -e "  ${GREEN}./expose-bolt.sh${NC}"
echo -e "${YELLOW}In bolt.diy, select 'DeepseekLocal' or 'CodeLlamaLocal' provider.${NC}"