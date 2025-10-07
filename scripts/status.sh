#!/bin/bash

# Show Docker Registry status

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}=== Docker Registry Status ===${NC}\n"

# Show container status
echo -e "${YELLOW}Container Status:${NC}"
docker compose ps

# Show disk usage
echo -e "\n${YELLOW}Disk Usage:${NC}"
docker system df -v | grep -A 10 "Local Volumes"

# Show registry data size
if [ -d "registry/data" ]; then
    REGISTRY_SIZE=$(du -sh registry/data 2>/dev/null | cut -f1)
    echo -e "\n${YELLOW}Registry Data Size:${NC} $REGISTRY_SIZE"
fi

# Try to get catalog (if credentials are available)
if [ -f .env ]; then
    DOMAIN=$(grep REGISTRY_DOMAIN .env | cut -d '=' -f2)
    echo -e "\n${YELLOW}Testing registry endpoint:${NC}"
    curl -s "http://localhost:5000/v2/" || echo "Registry not accessible"
fi

echo
