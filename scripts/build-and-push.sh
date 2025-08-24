#!/bin/bash

# Build and Push Docker Images to ECR
# This script builds all microservices and pushes them to ECR

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
AWS_REGION="us-east-1"
AWS_ACCOUNT_ID="063278365748"
ECR_REGISTRY="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"

# Services to build
SERVICES=("user-service" "product-service" "order-service" "frontend")

echo -e "${BLUE}🚀 Starting Docker build and push to ECR...${NC}"
echo -e "${BLUE}📍 Region: ${AWS_REGION}${NC}"
echo -e "${BLUE}🏢 Account: ${AWS_ACCOUNT_ID}${NC}"
echo -e "${BLUE}📦 Registry: ${ECR_REGISTRY}${NC}"
echo ""

# Check if AWS CLI is configured
if ! aws sts get-caller-identity &> /dev/null; then
    echo -e "${RED}❌ AWS CLI not configured. Please run 'aws configure' first.${NC}"
    exit 1
fi

# Check if Docker is running
if ! docker info &> /dev/null; then
    echo -e "${RED}❌ Docker is not running. Please start Docker first.${NC}"
    exit 1
fi

# Login to ECR
echo -e "${YELLOW}🔐 Logging in to ECR...${NC}"
aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${ECR_REGISTRY}

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Successfully logged in to ECR${NC}"
else
    echo -e "${RED}❌ Failed to login to ECR${NC}"
    exit 1
fi

echo ""

# Build and push each service
for service in "${SERVICES[@]}"; do
    echo -e "${BLUE}🏗️  Building ${service}...${NC}"
    
    # Determine Dockerfile path
    if [ "$service" = "frontend" ]; then
        DOCKERFILE="docker/Dockerfile.frontend"
        BUILD_CONTEXT="."
    else
        DOCKERFILE="docker/Dockerfile.${service}"
        BUILD_CONTEXT="."
    fi
    
    # Build the image
    echo -e "${YELLOW}📦 Building Docker image for ${service}...${NC}"
    docker build -f ${DOCKERFILE} -t ${service}:latest ${BUILD_CONTEXT}
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ Successfully built ${service} image${NC}"
    else
        echo -e "${RED}❌ Failed to build ${service} image${NC}"
        exit 1
    fi
    
    # Tag for ECR
    echo -e "${YELLOW}🏷️  Tagging image for ECR...${NC}"
    docker tag ${service}:latest ${ECR_REGISTRY}/${service}:latest
    
    # Push to ECR
    echo -e "${YELLOW}📤 Pushing ${service} to ECR...${NC}"
    docker push ${ECR_REGISTRY}/${service}:latest
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ Successfully pushed ${service} to ECR${NC}"
    else
        echo -e "${RED}❌ Failed to push ${service} to ECR${NC}"
        exit 1
    fi
    
    echo ""
done

echo -e "${GREEN}🎉 All services successfully built and pushed to ECR!${NC}"
echo ""
echo -e "${BLUE}📋 Summary:${NC}"
for service in "${SERVICES[@]}"; do
    echo -e "  ✅ ${service}: ${ECR_REGISTRY}/${service}:latest"
done
echo ""
echo -e "${BLUE}🚀 Next steps:${NC}"
echo -e "  1. Deploy the microservices to EKS"
echo -e "  2. Set up ArgoCD for GitOps"
echo -e "  3. Configure monitoring stack"
echo ""
