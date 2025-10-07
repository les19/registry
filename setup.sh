#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== Docker Registry Setup Script ===${NC}\n"

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo -e "${RED}Error: Docker is not installed${NC}"
    exit 1
fi

# Check if Docker Compose is installed
if ! command -v docker compose &> /dev/null; then
    echo -e "${RED}Error: Docker Compose is not installed${NC}"
    exit 1
fi

# Create registry directory
echo -e "${YELLOW}Creating registry directory...${NC}"
mkdir -p registry

# Create .env file if it doesn't exist
if [ ! -f .env ]; then
    echo -e "${YELLOW}Creating .env file from .env.example...${NC}"
    cp .env.example .env

    # Prompt for domain
    read -p "Enter your registry domain (e.g., registry.example.com): " DOMAIN
    if [ -z "$DOMAIN" ]; then
        echo -e "${RED}Domain cannot be empty${NC}"
        exit 1
    fi

    # Prompt for email
    read -p "Enter your email for Let's Encrypt: " EMAIL
    if [ -z "$EMAIL" ]; then
        echo -e "${RED}Email cannot be empty${NC}"
        exit 1
    fi

    # Generate random secret
    SECRET=$(openssl rand -hex 32)

    # Update .env file
    sed -i "s/REGISTRY_DOMAIN=.*/REGISTRY_DOMAIN=$DOMAIN/" .env
    sed -i "s/CADDY_SERVER_SERVER_NAME=.*/CADDY_SERVER_SERVER_NAME=$DOMAIN/" .env
    sed -i "s/ACME_EMAIL=.*/ACME_EMAIL=$EMAIL/" .env
    sed -i "s/REGISTRY_HTTP_SECRET=.*/REGISTRY_HTTP_SECRET=$SECRET/" .env

    echo -e "${GREEN}✓ .env file created and configured${NC}"
else
    echo -e "${YELLOW}.env file already exists, skipping...${NC}"
fi

# Create htpasswd file if it doesn't exist
if [ ! -f registry/registry.password ]; then
    echo -e "\n${YELLOW}Setting up registry authentication...${NC}"

    # Check if htpasswd is installed
    if ! command -v htpasswd &> /dev/null; then
        echo -e "${YELLOW}htpasswd not found. Installing apache2-utils...${NC}"
        if command -v apt-get &> /dev/null; then
            sudo apt-get update && sudo apt-get install -y apache2-utils
        elif command -v yum &> /dev/null; then
            sudo yum install -y httpd-tools
        else
            echo -e "${RED}Please install apache2-utils (Debian/Ubuntu) or httpd-tools (RHEL/CentOS)${NC}"
            exit 1
        fi
    fi

    # Prompt for username
    read -p "Enter registry username: " USERNAME
    if [ -z "$USERNAME" ]; then
        echo -e "${RED}Username cannot be empty${NC}"
        exit 1
    fi

    # Prompt for password (hidden)
    read -s -p "Enter registry password: " PASSWORD
    echo
    if [ -z "$PASSWORD" ]; then
        echo -e "${RED}Password cannot be empty${NC}"
        exit 1
    fi

    # Confirm password
    read -s -p "Confirm password: " PASSWORD_CONFIRM
    echo
    if [ "$PASSWORD" != "$PASSWORD_CONFIRM" ]; then
        echo -e "${RED}Passwords do not match${NC}"
        exit 1
    fi

    # Generate htpasswd file
    htpasswd -Bbn "$USERNAME" "$PASSWORD" > registry/registry.password
    echo -e "${GREEN}✓ Registry authentication configured${NC}"
else
    echo -e "${YELLOW}registry/registry.password already exists, skipping...${NC}"
fi

# Create .gitkeep for registry directory
touch registry/.gitkeep

echo -e "\n${GREEN}=== Setup Complete ===${NC}"
echo -e "\nNext steps:"
echo -e "1. Review and adjust settings in ${YELLOW}.env${NC}"
echo -e "2. Start the registry: ${YELLOW}docker compose up -d${NC}"
echo -e "3. Check logs: ${YELLOW}docker compose logs -f${NC}"
echo -e "4. Test the registry: ${YELLOW}curl https://\$(grep REGISTRY_DOMAIN .env | cut -d '=' -f2)/v2/${NC}"
echo -e "\nTo login to your registry:"
echo -e "  ${YELLOW}docker login \$(grep REGISTRY_DOMAIN .env | cut -d '=' -f2)${NC}"
echo -e "\nFor production deployment, configure GitHub secrets:"
echo -e "  - HOST: Your server IP/hostname"
echo -e "  - USERNAME: SSH username"
echo -e "  - PASSWORD: SSH password (or use SSH key)"
echo -e "  - PORT: SSH port (default: 22)"
echo -e "  - DEPLOY_PATH: Deployment directory path"
echo -e "  - REPO_URL: Your Git repository URL"
echo
