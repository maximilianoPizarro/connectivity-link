#!/bin/bash

# Script to update cluster domain references in the repository
# This script replaces the demo cluster domain with your own cluster's base domain

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Default demo cluster domain
OLD_DOMAIN="apps.cluster-gpzvq.gpzvq.sandbox670.opentlc.com"

echo -e "${YELLOW}========================================${NC}"
echo -e "${YELLOW}Cluster Domain Update Script${NC}"
echo -e "${YELLOW}========================================${NC}"
echo ""

# Check if new domain is provided as argument
if [ -z "$1" ]; then
    echo -e "${YELLOW}Usage: $0 <your-cluster-base-domain>${NC}"
    echo ""
    echo "Example: $0 apps.your-cluster.example.com"
    echo ""
    echo -e "${YELLOW}Current domain in files: ${OLD_DOMAIN}${NC}"
    echo ""
    read -p "Enter your cluster base domain (e.g., apps.your-cluster.example.com): " NEW_DOMAIN
else
    NEW_DOMAIN="$1"
fi

# Validate input
if [ -z "$NEW_DOMAIN" ]; then
    echo -e "${RED}Error: Cluster domain cannot be empty${NC}"
    exit 1
fi

# Confirm before proceeding
echo ""
echo -e "${YELLOW}This will replace all occurrences of:${NC}"
echo -e "  ${RED}${OLD_DOMAIN}${NC}"
echo -e "${YELLOW}with:${NC}"
echo -e "  ${GREEN}${NEW_DOMAIN}${NC}"
echo ""
read -p "Do you want to proceed? (y/N): " -n 1 -r
echo ""

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}Operation cancelled.${NC}"
    exit 0
fi

# Count files that will be modified
echo ""
echo -e "${YELLOW}Searching for files to update...${NC}"
FILES_TO_UPDATE=$(grep -r "$OLD_DOMAIN" --include="*.yaml" --include="*.yml" --include="*.sh" --include="*.env" . 2>/dev/null | cut -d: -f1 | sort -u | grep -v node_modules | grep -v ".git" || true)

if [ -z "$FILES_TO_UPDATE" ]; then
    echo -e "${GREEN}No files found with the old domain. Nothing to update.${NC}"
    exit 0
fi

FILE_COUNT=$(echo "$FILES_TO_UPDATE" | wc -l)
echo -e "${GREEN}Found ${FILE_COUNT} file(s) to update${NC}"
echo ""

# Perform the replacement
UPDATED_COUNT=0
for file in $FILES_TO_UPDATE; do
    if [ -f "$file" ]; then
        # Use sed for cross-platform compatibility (works on Linux, macOS, and Git Bash on Windows)
        if [[ "$OSTYPE" == "darwin"* ]]; then
            # macOS
            sed -i '' "s|${OLD_DOMAIN}|${NEW_DOMAIN}|g" "$file"
        else
            # Linux and Git Bash
            sed -i "s|${OLD_DOMAIN}|${NEW_DOMAIN}|g" "$file"
        fi
        echo -e "${GREEN}✓ Updated: ${file}${NC}"
        ((UPDATED_COUNT++))
    fi
done

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Update completed successfully!${NC}"
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Updated ${UPDATED_COUNT} file(s)${NC}"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "1. Review the changes with: git diff"
echo "2. Commit the changes: git add . && git commit -m 'Update cluster domain to ${NEW_DOMAIN}'"
echo "3. Push to your repository: git push"
echo ""

