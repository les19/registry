#!/bin/bash

# Backup Docker Registry data

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

BACKUP_DIR=${1:-./backups}
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_NAME="registry_backup_${TIMESTAMP}.tar.gz"

echo -e "${GREEN}=== Docker Registry Backup ===${NC}\n"

# Create backup directory
mkdir -p "$BACKUP_DIR"

# Check if registry is running
if docker compose ps | grep -q "docker-registry.*Up"; then
    echo -e "${YELLOW}Registry is running. Backup will be performed while running.${NC}"
    RUNNING=true
else
    echo -e "${YELLOW}Registry is stopped.${NC}"
    RUNNING=false
fi

echo -e "\n${YELLOW}Creating backup...${NC}"

# Backup registry data
docker run --rm \
    -v $(pwd)/registry:/backup/registry:ro \
    -v "$BACKUP_DIR":/backup/output \
    alpine tar czf "/backup/output/$BACKUP_NAME" \
    -C /backup registry

# Backup .env file
cp .env "$BACKUP_DIR/.env_${TIMESTAMP}"

BACKUP_SIZE=$(du -h "$BACKUP_DIR/$BACKUP_NAME" | cut -f1)

echo -e "\n${GREEN}✓ Backup complete!${NC}"
echo -e "Backup file: ${YELLOW}$BACKUP_DIR/$BACKUP_NAME${NC} ($BACKUP_SIZE)"
echo -e "Environment: ${YELLOW}$BACKUP_DIR/.env_${TIMESTAMP}${NC}"
echo -e "\nTo restore this backup, extract the tar.gz file to the registry directory."
