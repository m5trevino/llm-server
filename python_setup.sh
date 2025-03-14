#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${CYAN}Setting up Python environment...${NC}"

# Install Python and pip
echo -e "${YELLOW}Installing Python and pip...${NC}"
apt-get update
apt-get install -y python3.10-venv python3-pip
echo -e "${GREEN}Python and pip installed${NC}"

# Create virtual environment
echo -e "${YELLOW}Creating Python virtual environment...${NC}"
REPO_DIR=$(pwd)
cd "$REPO_DIR"

pip install virtualenv
if [ ! -d "venv" ]; then
    virtualenv venv
    echo -e "${GREEN}Virtual environment created${NC}"
else
    echo -e "${YELLOW}Virtual environment already exists${NC}"
fi

# Activate virtual environment
echo -e "${YELLOW}Activating virtual environment...${NC}"
source venv/bin/activate
python -m pip install --upgrade pip
echo -e "${GREEN}Virtual environment activated and pip upgraded${NC}"

# Create requirements.txt
echo -e "${YELLOW}Creating requirements.txt...${NC}"
cat > "${REPO_DIR}/api-server/requirements.txt" << 'EOF'
fastapi==0.104.1
uvicorn==0.23.2
pydantic==2.4.2
transformers==4.35.0
torch==2.1.0
accelerate==0.23.0
bitsandbytes==0.41.1
sentencepiece==0.1.99
einops==0.7.0
EOF
echo -e "${GREEN}requirements.txt created${NC}"

# Install requirements
echo -e "${YELLOW}Installing Python requirements...${NC}"
pip install -r "${REPO_DIR}/api-server/requirements.txt"
echo -e "${GREEN}Python requirements installed${NC}"

echo -e "${GREEN}Python environment setup completed!${NC}"