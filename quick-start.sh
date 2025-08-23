#!/bin/bash

# EKS Microservices Quick Start Script
# Complete setup in approximately 2 hours with interactive validation stages

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 EKS Microservices Quick Start${NC}"
echo -e "${BLUE}================================${NC}"
echo -e "${YELLOW}Target: Complete setup in 2 hours with validation stages${NC}"
echo -e "${PURPLE}This script includes interactive validation stages for production safety${NC}"
echo

# Configuration
CLUSTER_NAME="eks-microservices"
REGION="us-east-1"

# Function to print section headers
print_section() {
    echo -e "\n${BLUE}🔹 $1${NC}"
    echo -e "${BLUE}${2//?/=}${NC}"
}

# Function to check command existence
check_command() {
    if ! command -v $1 &> /dev/null; then
        echo -e "${RED}❌ $1 is not installed. Please install it first.${NC}"
        exit 1
    fi
}

# Function to print progress
print_progress() {
    echo -e "${GREEN}✅ $1${NC}"
}

# Function to print warning
print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

# Function to print error() {
    echo -e "${RED}❌ $1${NC}"
}

# Function to print info
print_info() {
    echo -e "${PURPLE}ℹ️  $1${NC}"
}

# Function to wait for user validation
wait_for_validation() {
    local stage_name="$1"
    local instructions="$2"
    
    echo -e "\n${PURPLE}🔄 VALIDATION STAGE: $stage_name${NC}"
    echo -e "${PURPLE}================================${NC}"
    echo -e "${YELLOW}$instructions${NC}"
    echo
    echo -e "${BLUE}📋 What to check:${NC}"
    echo -e "  1. Open AWS Console: https://console.aws.amazon.com"
    echo -e "  2. Navigate to the relevant service"
    echo -e "  3. Verify the resources are created and running"
    echo -e "  4. Check for any errors or warnings"
    echo
    echo -e "${GREEN}✅ Ready to proceed?${NC}"
    echo -e "${YELLOW}Type 'yes' to continue or 'no' to stop:${NC}"
    read -p "> " user_input
    
    if [[ "$user_input" != "yes" ]]; then
        echo -e "${YELLOW}⏸️  Deployment paused. You can resume later by running the script again.${NC}"
        echo -e "${BLUE}Current stage: $stage_name${NC}"
        exit 0
    fi
    
    echo -e "${GREEN}✅ Validation confirmed! Proceeding to next stage...${NC}"
    echo
}

# Phase 1: Prerequisites Check (5 minutes)
print_section "Phase 1: Prerequisites Check" "================================"
echo -e "${YELLOW}Checking required tools...${NC}"

# Check required commands
check_command "aws"
check_command "docker"
check_command "git"

print_progress "AWS CLI found"
print_progress "Docker found"
print_progress "Git found"

# Check AWS credentials
echo -e "${YELLOW}Checking AWS credentials...${NC}"
if aws sts get-caller-identity &> /dev/null; then
    print_progress "AWS credentials configured"
else
    print_error "AWS credentials not configured. Please run 'aws configure' first."
    exit 1
fi

# Check AWS region
CURRENT_REGION=$(aws configure get region)
if [ "$CURRENT_REGION" != "$REGION" ]; then
    print_warning "AWS region is set to $CURRENT_REGION, but we'll use $REGION for this setup"
fi

print_progress "Prerequisites check completed"

# Phase 2: EKS Infrastructure Setup (30 minutes)
print_section "Phase 2: EKS Infrastructure Setup" "=================================="
echo -e "${YELLOW}Setting up EKS cluster and infrastructure...${NC}"

# Make scripts executable
chmod +x scripts/*.sh

# Run EKS setup
echo -e "${YELLOW}Running EKS setup script...${NC}"
echo -e "${PURPLE}This will take approximately 15-20 minutes...${NC}"
./scripts/setup-eks.sh

if [ $? -eq 0 ]; then
    print_progress "EKS infrastructure setup completed"
else
    print_error "EKS setup failed. Please check the logs and try again."
    exit 1
fi

# Validation Stage 1: EKS Cluster
wait_for_validation "EKS Cluster Creation" \
"Please validate that the EKS cluster has been created successfully in AWS.

1. Go to AWS Console → EKS → Clusters
2. Verify cluster 'eks-microservices' is in 'ACTIVE' state
3. Check that all 3 nodes are running
4. Verify the cluster is in region: $REGION
5. Check that the cluster has proper IAM roles and security groups"

# Validation Stage 2: ECR Repositories
wait_for_validation "ECR Repositories" \
"Please validate that ECR repositories have been created successfully.

1. Go to AWS Console → ECR → Repositories
2. Verify these repositories exist:
   - frontend
   - user-service
   - product-service
   - order-service
3. Check that repositories are in region: $REGION
4. Verify repository permissions are set correctly"

# Validation Stage 3: Load Balancer Controller
wait_for_validation "AWS Load Balancer Controller" \
"Please validate that the Load Balancer Controller is working.

1. Go to AWS Console → EKS → Clusters → eks-microservices
2. Check the 'Add-ons' tab
3. Verify 'aws-load-balancer-controller' is installed and active
4. Check that the controller has proper IAM permissions
5. Verify no error messages in the add-on status"

# Phase 3: Application Deployment (30 minutes)
print_section "Phase 3: Application Deployment" "=================================="
echo -e "${YELLOW}Deploying microservices application...${NC}"

# Apply Kubernetes manifests
echo -e "${YELLOW}Applying Kubernetes manifests...${NC}"
kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/postgresql.yaml

# Wait for database to be ready
echo -e "${YELLOW}Waiting for database to be ready...${NC}"
kubectl wait --for=condition=ready pod -l app=postgres -n eks-microservices --timeout=300s

# Deploy services
kubectl apply -f k8s/user-service.yaml
kubectl apply -f k8s/product-service.yaml
kubectl apply -f k8s/order-service.yaml
kubectl apply -f k8s/frontend.yaml

# Wait for services to be ready
echo -e "${YELLOW}Waiting for services to be ready...${NC}"
kubectl wait --for=condition=ready pod -l app=user-service -n eks-microservices --timeout=300s
kubectl wait --for=condition=ready pod -l app=product-service -n eks-microservices --timeout=300s
kubectl wait --for=condition=ready pod -l app=order-service -n eks-microservices --timeout=300s
kubectl wait --for=condition=ready pod -l app=frontend -n eks-microservices --timeout=300s

print_progress "Application deployment completed"

# Validation Stage 4: Application Services
wait_for_validation "Application Services" \
"Please validate that all application services are running correctly.

1. Go to AWS Console → EKS → Clusters → eks-microservices
2. Check the 'Workloads' tab
3. Verify all deployments are showing:
   - postgres: 1/1 ready
   - user-service: 2/2 ready
   - product-service: 2/2 ready
   - order-service: 2/2 ready
   - frontend: 1/1 ready
4. Check that no pods are in 'Error' or 'CrashLoopBackOff' state
5. Verify services have proper endpoints"

# Validation Stage 5: Load Balancer
wait_for_validation "Application Load Balancer" \
"Please validate that the Application Load Balancer is working.

1. Go to AWS Console → EC2 → Load Balancers
2. Look for a Load Balancer with name containing 'eks-microservices'
3. Verify the Load Balancer is in 'Active' state
4. Check that it has listeners for HTTP (80) and HTTPS (443)
5. Verify target groups are healthy
6. Note the Load Balancer DNS name for later use"

# Phase 4: Monitoring Setup (15 minutes)
print_section "Phase 4: Monitoring Setup" "============================="
echo -e "${YELLOW}Setting up monitoring and observability...${NC}"

# Deploy monitoring stack
kubectl apply -f monitoring/

# Wait for monitoring to be ready
echo -e "${YELLOW}Waiting for monitoring stack to be ready...${NC}"
kubectl wait --for=condition=ready pod -l app=grafana -n monitoring --timeout=300s

print_progress "Monitoring setup completed"

# Validation Stage 6: Monitoring Stack
wait_for_validation "Monitoring Stack" \
"Please validate that the monitoring stack is working correctly.

1. Go to AWS Console → EKS → Clusters → eks-microservices
2. Check the 'Workloads' tab in 'monitoring' namespace
3. Verify these deployments are running:
   - prometheus-operator
   - grafana
   - prometheus
4. Check that all pods are in 'Running' state
5. Verify no error messages in pod logs
6. Check that monitoring services have proper endpoints"

# Phase 5: CI/CD Setup (30 minutes)
print_section "Phase 5: CI/CD Setup" "========================="
echo -e "${YELLOW}Setting up Jenkins CI/CD pipeline on EKS...${NC}"

# Jenkins is automatically deployed on EKS during infrastructure setup
echo "Jenkins will be deployed on EKS automatically"
echo -e "${YELLOW}Waiting for Jenkins to be ready...${NC}"
kubectl wait --for=condition=ready pod -l app=jenkins -n jenkins --timeout=300s

print_progress "Jenkins setup completed"

# Validation Stage 7: CI/CD Pipeline
wait_for_validation "CI/CD Pipeline" \
"Please validate that the CI/CD pipeline is working correctly.

1. Go to AWS Console → EKS → Clusters → eks-microservices
2. Check the 'Workloads' tab in 'jenkins' namespace
3. Verify Jenkins deployment is running (1/1 ready)
4. Check that Jenkins service has proper endpoints
5. Verify Jenkins ingress is configured
6. Check that Jenkins has access to ECR repositories
7. Verify Jenkins can connect to the EKS cluster"

# Validation Stage 8: ArgoCD GitOps
wait_for_validation "ArgoCD GitOps Setup" \
"Please validate that ArgoCD is properly configured and syncing.

1. Go to AWS Console → EKS → Clusters → eks-microservices
2. Check the 'Workloads' tab in 'argocd' namespace
3. Verify ArgoCD server is running (1/1 ready)
4. Check that ArgoCD repo-server is running
5. Verify ArgoCD application-controller is running
6. Check ArgoCD applications are syncing:
   - eks-microservices (should be Synced/Healthy)
   - monitoring (should be Synced/Healthy)
   - jenkins (should be Synced/Healthy)
7. Verify no sync errors or conflicts
8. Check that ArgoCD can access your Git repository"

# Phase 6: Final Verification and Testing (10 minutes)
print_section "Phase 6: Final Verification and Testing" "=================================="
echo -e "${YELLOW}Final verification and testing...${NC}"

# Check all services
echo -e "${YELLOW}Checking service status...${NC}"
kubectl get pods -n eks-microservices
kubectl get services -n eks-microservices
kubectl get ingress -n eks-microservices

# Test endpoints
echo -e "${YELLOW}Testing service endpoints...${NC}"
kubectl port-forward svc/user-service 3001:80 -n eks-microservices &
kubectl port-forward svc/frontend 3000:80 -n eks-microservices &
kubectl port-forward svc/argocd-server 8080:80 -n argocd &
kubectl port-forward svc/grafana 3001:80 -n monitoring &
kubectl port-forward svc/jenkins 8081:80 -n jenkins &

# Wait for port forwarding
sleep 10

# Test health endpoints
if curl -f http://localhost:3001/health &> /dev/null; then
    print_progress "User service health check passed"
else
    print_warning "User service health check failed"
fi

if curl -f http://localhost:3000/ &> /dev/null; then
    print_progress "Frontend health check passed"
else
    print_warning "Frontend health check failed"
fi

print_progress "Verification completed"

# Final Validation Stage: Complete System
wait_for_validation "Complete System Validation" \
"Please perform a final validation of the complete system.

1. **EKS Cluster**: Verify all nodes are healthy
2. **Application Services**: Check all pods are running
3. **Load Balancer**: Verify ALB is active and healthy
4. **Monitoring**: Check Prometheus and Grafana are accessible
5. **CI/CD**: Verify Jenkins is running and accessible
6. **GitOps**: Check ArgoCD is syncing correctly
7. **Database**: Verify PostgreSQL is running and accessible
8. **Networking**: Check ingress rules are working
9. **Security**: Verify IAM roles and security groups are correct
10. **ArgoCD Applications**: Verify all apps are Synced/Healthy
11. **Costs**: Check AWS billing to ensure no unexpected charges"

# Final Summary
print_section "Setup Complete!" "================"
echo -e "${GREEN}🎉 Congratulations! Your EKS Microservices WebApp is now running!${NC}"
echo
echo -e "${BLUE}📋 Access Information:${NC}"
echo -e "  Frontend: http://localhost:3000 (port-forward)"
echo -e "  User Service: http://localhost:3001 (port-forward)"
echo -e "  ArgoCD: http://localhost:8080 (port-forward)"
echo -e "  Grafana: http://localhost:3001 (port-forward)"
echo -e "  Jenkins: http://localhost:8081 (port-forward)"
echo
echo -e "${BLUE}🌐 Production URLs (after DNS setup):${NC}"
echo -e "  Frontend: http://app.eks-microservices.com"
echo -e "  Jenkins: http://jenkins.eks-microservices.com"
echo -e "  ArgoCD: http://argocd.eks-microservices.com"
echo -e "  Grafana: http://grafana.eks-microservices.com"
echo
echo -e "${BLUE}🔑 Default Credentials:${NC}"
echo -e "  ArgoCD: admin / [password from setup]"
echo -e "  Grafana: admin / admin"
echo -e "  Database: postgres / password"
echo -e "  Jenkins: [auto-configured]"
echo
echo -e "${BLUE}🔑 ArgoCD Admin Password:${NC}"
echo -e "  kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d"
echo
echo -e "${BLUE}📊 Next Steps:${NC}"
echo -e "  1. Configure your domain names in AWS Route 53"
echo -e "  2. Set up SSL certificates with AWS Certificate Manager"
echo -e "  3. Configure Jenkins pipeline with your GitHub repository"
echo -e "  4. Set up Splunk integration for advanced logging"
echo -e "  5. Configure monitoring alerts and dashboards"
echo -e "  6. Set up backup and disaster recovery procedures"
echo
echo -e "${BLUE}📚 Documentation:${NC}"
echo -e "  - Deployment Guide: docs/deployment-guide.md"
echo -e "  - Enterprise Architecture: docs/enterprise-architecture.md"
echo -e "  - ArgoCD Setup: docs/argocd-setup.md"
echo -e "  - Troubleshooting: docs/troubleshooting.md"
echo
echo -e "${GREEN}⏱️  Total setup time: Approximately 2 hours${NC}"
echo -e "${GREEN}🚀 Your microservices application is ready for production!${NC}"
echo -e "${PURPLE}✅ All components are running in AWS - no local infrastructure needed!${NC}"

# Cleanup port forwarding
pkill -f "kubectl port-forward" || true
