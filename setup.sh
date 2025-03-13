#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Setting up LLM API Server and bolt.diy integration...${NC}"

# Check if bolt.diy directory exists
if [ ! -d "../bolt.diy" ]; then
    echo -e "${YELLOW}bolt.diy directory not found. Please make sure you're running this script from the correct location.${NC}"
    exit 1
fi

# Check if providers directory exists
if [ ! -d "../bolt.diy/app/lib/modules/llm/providers" ]; then
    echo -e "${YELLOW}bolt.diy providers directory not found. Please make sure you have the correct bolt.diy version.${NC}"
    exit 1
fi

# Install API server requirements
echo -e "${YELLOW}Installing API server requirements...${NC}"
pip install -r api-server/requirements.txt

# Copy provider files
echo -e "${YELLOW}Copying provider files to bolt.diy...${NC}"
cp providers/deepseek-local.ts ../bolt.diy/app/lib/modules/llm/providers/
cp providers/codellama-local.ts ../bolt.diy/app/lib/modules/llm/providers/

# Add environment variables to bolt.diy .env file
echo -e "${YELLOW}Adding environment variables to bolt.diy .env file...${NC}"
ENV_FILE="../bolt.diy/.env"

if [ ! -f "$ENV_FILE" ]; then
    touch "$ENV_FILE"
fi

# Add environment variables if they don't exist
grep -q "DEEPSEEK_LOCAL_API_BASE_URL" "$ENV_FILE" || echo "DEEPSEEK_LOCAL_API_BASE_URL=http://localhost:8000/v1" >> "$ENV_FILE"
grep -q "CODELLAMA_LOCAL_API_BASE_URL" "$ENV_FILE" || echo "CODELLAMA_LOCAL_API_BASE_URL=http://localhost:8000/v1" >> "$ENV_FILE"

echo -e "${GREEN}Setup complete!${NC}"
echo -e "${YELLOW}To run the API server:${NC}"
echo -e "  cd api-server"
echo -e "  python run.py --model deepseek  # or codellama"
echo -e "${YELLOW}Then start bolt.diy as usual.${NC}"
echo -e "${YELLOW}In bolt.diy, select 'DeepseekLocal' or 'CodeLlamaLocal' provider.${NC}"