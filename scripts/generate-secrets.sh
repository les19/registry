#!/bin/bash

# Script to generate GitHub Secrets configuration for Docker Registry

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== Docker Registry GitHub Secrets Generator ===${NC}\n"

# Check if openssl is available
if ! command -v openssl &> /dev/null; then
    echo -e "${RED}Error: openssl is not installed${NC}"
    exit 1
fi

echo -e "${BLUE}This script will help you generate all the required GitHub secrets.${NC}"
echo -e "${BLUE}Copy each secret to: GitHub Repository → Settings → Secrets → Actions${NC}\n"

echo -e "${YELLOW}=== SSH Connection Configuration ===${NC}\n"

read -p "Enter your server IP or hostname: " HOST
read -p "Enter SSH username: " USERNAME
read -s -p "Enter SSH password: " PASSWORD
echo
read -p "Enter SSH port [22]: " PORT
PORT=${PORT:-22}
read -p "Enter deployment path [/opt/docker-registry]: " DEPLOY_PATH
DEPLOY_PATH=${DEPLOY_PATH:-/opt/docker-registry}

echo
echo -e "${YELLOW}=== Registry Configuration ===${NC}\n"

read -p "Enter your registry domain (e.g., registry.example.com): " DOMAIN
if [ -z "$DOMAIN" ]; then
    echo -e "${RED}Error: Domain cannot be empty${NC}"
    exit 1
fi

read -p "Enter your email for Let's Encrypt: " EMAIL
if [ -z "$EMAIL" ]; then
    echo -e "${RED}Error: Email cannot be empty${NC}"
    exit 1
fi

echo
echo -e "${YELLOW}Generating random secret...${NC}"
SECRET=$(openssl rand -hex 32)

echo
echo -e "${YELLOW}=== Optional Configuration ===${NC}"
echo -e "${BLUE}Press Enter to use defaults, or type a custom value:${NC}\n"

read -p "Storage directory [/data]: " STORAGE_DIR
STORAGE_DIR=${STORAGE_DIR:-/data}

read -p "Allow image deletion [true]: " DELETE_ENABLED
DELETE_ENABLED=${DELETE_ENABLED:-true}

read -p "Cache type [inmemory]: " CACHE_TYPE
CACHE_TYPE=${CACHE_TYPE:-inmemory}

read -p "Log level (error/warn/info/debug) [info]: " LOG_LEVEL
LOG_LEVEL=${LOG_LEVEL:-info}

read -p "Max concurrent uploads [5]: " MAX_UPLOADS
MAX_UPLOADS=${MAX_UPLOADS:-5}

read -p "Read timeout [5m]: " TIMEOUT_READ
TIMEOUT_READ=${TIMEOUT_READ:-5m}

read -p "Write timeout [10m]: " TIMEOUT_WRITE
TIMEOUT_WRITE=${TIMEOUT_WRITE:-10m}

read -p "Enable health checks [true]: " HEALTH_ENABLED
HEALTH_ENABLED=${HEALTH_ENABLED:-true}

read -p "Health check interval [10s]: " HEALTH_INTERVAL
HEALTH_INTERVAL=${HEALTH_INTERVAL:-10s}

read -p "Health check threshold [3]: " HEALTH_THRESHOLD
HEALTH_THRESHOLD=${HEALTH_THRESHOLD:-3}

# Generate output
echo
echo -e "${GREEN}=== GitHub Secrets Configuration ===${NC}\n"
echo -e "${YELLOW}Copy these to your GitHub repository secrets:${NC}\n"

cat << EOF
${GREEN}# SSH Connection (Required)${NC}
HOST=$HOST
USERNAME=$USERNAME
PASSWORD=$PASSWORD
PORT=$PORT
DEPLOY_PATH=$DEPLOY_PATH

${GREEN}# Registry Configuration (Required)${NC}
REGISTRY_DOMAIN=$DOMAIN
ACME_EMAIL=$EMAIL
REGISTRY_HTTP_SECRET=$SECRET

${GREEN}# Optional Configuration${NC}
REGISTRY_STORAGE_FILESYSTEM_ROOTDIRECTORY=$STORAGE_DIR
REGISTRY_STORAGE_DELETE_ENABLED=$DELETE_ENABLED
REGISTRY_STORAGE_CACHE_BLOBDESCRIPTOR=$CACHE_TYPE
REGISTRY_LOG_LEVEL=$LOG_LEVEL
REGISTRY_HTTP_MAXCONCURRENTUPLOADS=$MAX_UPLOADS
REGISTRY_HTTP_TIMEOUT_READ=$TIMEOUT_READ
REGISTRY_HTTP_TIMEOUT_WRITE=$TIMEOUT_WRITE
REGISTRY_HEALTH_STORAGEDRIVER_ENABLED=$HEALTH_ENABLED
REGISTRY_HEALTH_STORAGEDRIVER_INTERVAL=$HEALTH_INTERVAL
REGISTRY_HEALTH_STORAGEDRIVER_THRESHOLD=$HEALTH_THRESHOLD
EOF

# Save to file
OUTPUT_FILE="github-secrets-$(date +%Y%m%d_%H%M%S).txt"
cat << EOF > "$OUTPUT_FILE"
# GitHub Secrets for Docker Registry
# Generated: $(date)

# SSH Connection
HOST=$HOST
USERNAME=$USERNAME
PASSWORD=$PASSWORD
PORT=$PORT
DEPLOY_PATH=$DEPLOY_PATH

# Registry Configuration
REGISTRY_DOMAIN=$DOMAIN
ACME_EMAIL=$EMAIL
REGISTRY_HTTP_SECRET=$SECRET

# Optional Configuration
REGISTRY_STORAGE_FILESYSTEM_ROOTDIRECTORY=$STORAGE_DIR
REGISTRY_STORAGE_DELETE_ENABLED=$DELETE_ENABLED
REGISTRY_STORAGE_CACHE_BLOBDESCRIPTOR=$CACHE_TYPE
REGISTRY_LOG_LEVEL=$LOG_LEVEL
REGISTRY_HTTP_MAXCONCURRENTUPLOADS=$MAX_UPLOADS
REGISTRY_HTTP_TIMEOUT_READ=$TIMEOUT_READ
REGISTRY_HTTP_TIMEOUT_WRITE=$TIMEOUT_WRITE
REGISTRY_HEALTH_STORAGEDRIVER_ENABLED=$HEALTH_ENABLED
REGISTRY_HEALTH_STORAGEDRIVER_INTERVAL=$HEALTH_INTERVAL
REGISTRY_HEALTH_STORAGEDRIVER_THRESHOLD=$HEALTH_THRESHOLD
EOF

echo
echo -e "${GREEN}✓ Configuration saved to: ${YELLOW}$OUTPUT_FILE${NC}\n"
echo -e "${BLUE}Next steps:${NC}"
echo "1. Go to your GitHub repository"
echo "2. Click Settings → Secrets and variables → Actions"
echo "3. Add each secret from the list above"
echo "4. Create registry password on your server:"
echo -e "   ${YELLOW}ssh $USERNAME@$HOST${NC}"
echo -e "   ${YELLOW}mkdir -p $DEPLOY_PATH/registry${NC}"
echo -e "   ${YELLOW}htpasswd -Bbn username password > $DEPLOY_PATH/registry/registry.password${NC}"
echo "5. Trigger the deployment workflow from GitHub Actions"
echo
