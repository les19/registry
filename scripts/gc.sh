#!/bin/bash

# Docker Registry Garbage Collection Script
# This script runs garbage collection to remove unreferenced layers

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}=== Docker Registry Garbage Collection ===${NC}\n"

# Check if registry is running
if ! docker compose ps | grep -q "docker-registry.*Up"; then
    echo -e "${RED}Error: Registry container is not running${NC}"
    exit 1
fi

echo -e "${YELLOW}This will run garbage collection on the registry.${NC}"
echo -e "${YELLOW}The registry will be in read-only mode during this process.${NC}"
read -p "Continue? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Cancelled."
    exit 0
fi

# Set registry to read-only mode
echo -e "\n${YELLOW}Setting registry to read-only mode...${NC}"
docker compose stop registry

# Run garbage collection
echo -e "${YELLOW}Running garbage collection...${NC}"
docker compose run --rm registry garbage-collect /etc/docker/registry/config.yml

# Start registry in normal mode
echo -e "${YELLOW}Restarting registry in normal mode...${NC}"
docker compose start registry

echo -e "\n${GREEN}✓ Garbage collection complete!${NC}"
echo -e "Registry is back in read-write mode.\n"
