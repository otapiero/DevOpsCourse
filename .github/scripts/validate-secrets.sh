#!/bin/bash

# GitHub Actions Secrets Validation Script
# This script helps validate that all required secrets are properly configured

set -e

echo "🔍 GitHub Actions Secrets Validation"
echo "===================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to check if a secret exists (this will be run in GitHub Actions)
check_secret() {
    local secret_name=$1
    local secret_value=$2
    local is_required=$3
    
    if [ -z "$secret_value" ]; then
        if [ "$is_required" = "true" ]; then
            echo -e "${RED}❌ MISSING: $secret_name (REQUIRED)${NC}"
            return 1
        else
            echo -e "${YELLOW}⚠️  OPTIONAL: $secret_name (not set)${NC}"
            return 0
        fi
    else
        echo -e "${GREEN}✅ FOUND: $secret_name${NC}"
        return 0
    fi
}

# Function to validate secret format
validate_secret_format() {
    local secret_name=$1
    local secret_value=$2
    local expected_format=$3
    
    if [ -z "$secret_value" ]; then
        return 0  # Skip validation if secret is not set
    fi
    
    case $expected_format in
        "docker_token")
            if [[ $secret_value =~ ^dckr_pat_.+ ]]; then
                echo -e "${GREEN}✅ FORMAT: $secret_name (valid Docker Hub token format)${NC}"
            else
                echo -e "${YELLOW}⚠️  FORMAT: $secret_name (should start with 'dckr_pat_')${NC}"
            fi
            ;;
        "ssh_key")
            if [[ $secret_value =~ ^-----BEGIN.+PRIVATE.KEY----- ]]; then
                echo -e "${GREEN}✅ FORMAT: $secret_name (valid SSH private key format)${NC}"
            else
                echo -e "${RED}❌ FORMAT: $secret_name (should be a valid SSH private key)${NC}"
                return 1
            fi
            ;;
        "hostname")
            if [[ $secret_value =~ ^[a-zA-Z0-9.-]+$ ]]; then
                echo -e "${GREEN}✅ FORMAT: $secret_name (valid hostname format)${NC}"
            else
                echo -e "${YELLOW}⚠️  FORMAT: $secret_name (should be a valid hostname or IP)${NC}"
            fi
            ;;
        "username")
            if [[ $secret_value =~ ^[a-zA-Z0-9_-]+$ ]]; then
                echo -e "${GREEN}✅ FORMAT: $secret_name (valid username format)${NC}"
            else
                echo -e "${YELLOW}⚠️  FORMAT: $secret_name (should be a valid username)${NC}"
            fi
            ;;
    esac
}

echo "Checking required secrets..."
echo ""

# Track validation results
VALIDATION_FAILED=false

# Required Docker Hub secrets
echo -e "${BLUE}Docker Hub Configuration:${NC}"
if ! check_secret "DOCKER_HUB_USERNAME" "$DOCKER_HUB_USERNAME" "true"; then
    VALIDATION_FAILED=true
fi
validate_secret_format "DOCKER_HUB_USERNAME" "$DOCKER_HUB_USERNAME" "username"

if ! check_secret "DOCKER_HUB_ACCESS_TOKEN" "$DOCKER_HUB_ACCESS_TOKEN" "true"; then
    VALIDATION_FAILED=true
fi
validate_secret_format "DOCKER_HUB_ACCESS_TOKEN" "$DOCKER_HUB_ACCESS_TOKEN" "docker_token"

echo ""

# Required VM secrets
echo -e "${BLUE}VM Deployment Configuration:${NC}"
if ! check_secret "VM_HOST" "$VM_HOST" "true"; then
    VALIDATION_FAILED=true
fi
validate_secret_format "VM_HOST" "$VM_HOST" "hostname"

if ! check_secret "VM_USERNAME" "$VM_USERNAME" "true"; then
    VALIDATION_FAILED=true
fi
validate_secret_format "VM_USERNAME" "$VM_USERNAME" "username"

if ! check_secret "VM_SSH_KEY" "$VM_SSH_KEY" "true"; then
    VALIDATION_FAILED=true
fi
validate_secret_format "VM_SSH_KEY" "$VM_SSH_KEY" "ssh_key"

echo ""

# Optional notification secrets
echo -e "${BLUE}Optional Notification Configuration:${NC}"
check_secret "SLACK_WEBHOOK_URL" "$SLACK_WEBHOOK_URL" "false"
check_secret "TEAMS_WEBHOOK_URL" "$TEAMS_WEBHOOK_URL" "false"

echo ""
echo "===================================="

# Test Docker Hub connectivity (if secrets are available)
if [ -n "$DOCKER_HUB_USERNAME" ] && [ -n "$DOCKER_HUB_ACCESS_TOKEN" ]; then
    echo -e "${BLUE}Testing Docker Hub connectivity...${NC}"
    
    # Login to Docker Hub
    if echo "$DOCKER_HUB_ACCESS_TOKEN" | docker login docker.io -u "$DOCKER_HUB_USERNAME" --password-stdin > /dev/null 2>&1; then
        echo -e "${GREEN}✅ Docker Hub authentication successful${NC}"
        
        # Test if we can access the repositories
        FRONTEND_IMAGE="${DOCKER_HUB_USERNAME}/notes-frontend"
        BACKEND_IMAGE="${DOCKER_HUB_USERNAME}/notes-backend"
        
        echo "Testing repository access..."
        if docker pull "$FRONTEND_IMAGE:latest" > /dev/null 2>&1 || [ $? -eq 0 ]; then
            echo -e "${GREEN}✅ Frontend repository accessible: $FRONTEND_IMAGE${NC}"
        else
            echo -e "${YELLOW}⚠️  Frontend repository not found (will be created on first push): $FRONTEND_IMAGE${NC}"
        fi
        
        if docker pull "$BACKEND_IMAGE:latest" > /dev/null 2>&1 || [ $? -eq 0 ]; then
            echo -e "${GREEN}✅ Backend repository accessible: $BACKEND_IMAGE${NC}"
        else
            echo -e "${YELLOW}⚠️  Backend repository not found (will be created on first push): $BACKEND_IMAGE${NC}"
        fi
        
        docker logout docker.io > /dev/null 2>&1
    else
        echo -e "${RED}❌ Docker Hub authentication failed${NC}"
        echo -e "${YELLOW}   Please verify DOCKER_HUB_USERNAME and DOCKER_HUB_ACCESS_TOKEN${NC}"
        VALIDATION_FAILED=true
    fi
    echo ""
fi

# Test VM connectivity (if secrets are available)
if [ -n "$VM_HOST" ] && [ -n "$VM_USERNAME" ] && [ -n "$VM_SSH_KEY" ]; then
    echo -e "${BLUE}Testing VM connectivity...${NC}"
    
    # Create temporary SSH key file
    SSH_KEY_FILE=$(mktemp)
    echo "$VM_SSH_KEY" > "$SSH_KEY_FILE"
    chmod 600 "$SSH_KEY_FILE"
    
    # Add VM to known hosts
    ssh-keyscan -H "$VM_HOST" >> ~/.ssh/known_hosts 2>/dev/null || true
    
    # Test SSH connection
    if ssh -i "$SSH_KEY_FILE" -o ConnectTimeout=10 -o StrictHostKeyChecking=no "$VM_USERNAME@$VM_HOST" "echo 'SSH connection successful'" > /dev/null 2>&1; then
        echo -e "${GREEN}✅ SSH connection to VM successful${NC}"
        
        # Test Docker availability on VM
        if ssh -i "$SSH_KEY_FILE" -o ConnectTimeout=10 "$VM_USERNAME@$VM_HOST" "docker --version" > /dev/null 2>&1; then
            echo -e "${GREEN}✅ Docker is available on VM${NC}"
        else
            echo -e "${RED}❌ Docker is not available on VM${NC}"
            echo -e "${YELLOW}   Please install Docker on the target VM${NC}"
            VALIDATION_FAILED=true
        fi
        
        # Test Docker Compose availability on VM
        if ssh -i "$SSH_KEY_FILE" -o ConnectTimeout=10 "$VM_USERNAME@$VM_HOST" "docker-compose --version" > /dev/null 2>&1; then
            echo -e "${GREEN}✅ Docker Compose is available on VM${NC}"
        else
            echo -e "${RED}❌ Docker Compose is not available on VM${NC}"
            echo -e "${YELLOW}   Please install Docker Compose on the target VM${NC}"
            VALIDATION_FAILED=true
        fi
        
        # Test port availability
        echo "Testing port availability on VM..."
        if ssh -i "$SSH_KEY_FILE" -o ConnectTimeout=10 "$VM_USERNAME@$VM_HOST" "netstat -tlnp | grep -E ':(3000|5000)'" > /dev/null 2>&1; then
            echo -e "${YELLOW}⚠️  Ports 3000 or 5000 are already in use on VM${NC}"
            echo -e "${YELLOW}   This may cause deployment conflicts${NC}"
        else
            echo -e "${GREEN}✅ Ports 3000 and 5000 are available on VM${NC}"
        fi
        
    else
        echo -e "${RED}❌ SSH connection to VM failed${NC}"
        echo -e "${YELLOW}   Please verify VM_HOST, VM_USERNAME, and VM_SSH_KEY${NC}"
        echo -e "${YELLOW}   Ensure the SSH public key is added to ~/.ssh/authorized_keys on the VM${NC}"
        VALIDATION_FAILED=true
    fi
    
    # Cleanup
    rm -f "$SSH_KEY_FILE"
    echo ""
fi

# Final validation result
echo "===================================="
if [ "$VALIDATION_FAILED" = "true" ]; then
    echo -e "${RED}❌ VALIDATION FAILED${NC}"
    echo -e "${YELLOW}Please fix the issues above before running the CI/CD pipeline.${NC}"
    echo ""
    echo -e "${BLUE}For setup instructions, see:${NC}"
    echo "  .github/DEPLOYMENT_SETUP.md"
    exit 1
else
    echo -e "${GREEN}✅ VALIDATION PASSED${NC}"
    echo -e "${GREEN}All required secrets are properly configured!${NC}"
    echo ""
    echo -e "${BLUE}Your CI/CD pipeline is ready to use.${NC}"
    exit 0
fi