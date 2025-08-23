#!/bin/bash

# EKS Microservices Setup Script
# This script sets up a complete EKS cluster with all necessary components

set -e

# Configuration
CLUSTER_NAME="eks-microservices"
REGION="us-east-1"
NODE_TYPE="t3.medium"
NODES_MIN=2
NODES_MAX=5
NODES_DESIRED=3

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}🚀 Starting EKS Microservices Setup...${NC}"

# Check prerequisites
echo -e "${YELLOW}📋 Checking prerequisites...${NC}"

# Check if AWS CLI is installed
if ! command -v aws &> /dev/null; then
    echo -e "${RED}❌ AWS CLI is not installed. Please install it first.${NC}"
    exit 1
fi

# Check if eksctl is installed
if ! command -v eksctl &> /dev/null; then
    echo -e "${YELLOW}⚠️  eksctl is not installed. Installing...${NC}"
    curl --silent --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp
    sudo mv /tmp/eksctl /usr/local/bin
    echo -e "${GREEN}✅ eksctl installed successfully${NC}"
fi

# Check if kubectl is installed
if ! command -v kubectl &> /dev/null; then
    echo -e "${YELLOW}⚠️  kubectl is not installed. Installing...${NC}"
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    chmod +x kubectl
    sudo mv kubectl /usr/local/bin/
    echo -e "${GREEN}✅ kubectl installed successfully${NC}"
fi

# Check if helm is installed
if ! command -v helm &> /dev/null; then
    echo -e "${YELLOW}⚠️  Helm is not installed. Installing...${NC}"
    curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
    echo -e "${GREEN}✅ Helm installed successfully${NC}"
fi

# Check if argocd CLI is installed
if ! command -v argocd &> /dev/null; then
    echo -e "${YELLOW}⚠️  ArgoCD CLI is not installed. Installing...${NC}"
    curl -sSL -o argocd-linux-amd64 https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
    sudo install -m 555 argocd-linux-amd64 /usr/local/bin/argocd
    rm argocd-linux-amd64
    echo -e "${GREEN}✅ ArgoCD CLI installed successfully${NC}"
fi

echo -e "${GREEN}✅ All prerequisites are satisfied${NC}"

# Configure AWS credentials
echo -e "${YELLOW}🔐 Configuring AWS credentials...${NC}"
aws configure list --profile default || {
    echo -e "${YELLOW}Please configure your AWS credentials:${NC}"
    aws configure
}

# Create EKS cluster
echo -e "${YELLOW}🏗️  Creating EKS cluster...${NC}"
eksctl create cluster \
    --name $CLUSTER_NAME \
    --region $REGION \
    --nodegroup-name standard-workers \
    --node-type $NODE_TYPE \
    --nodes $NODES_DESIRED \
    --nodes-min $NODES_MIN \
    --nodes-max $NODES_MAX \
    --managed \
    --with-oidc \
    --ssh-access \
    --ssh-public-key ~/.ssh/id_rsa \
    --full-ecr-access \
    --alb-ingress-access

echo -e "${GREEN}✅ EKS cluster created successfully${NC}"

# Update kubeconfig
echo -e "${YELLOW}🔧 Updating kubeconfig...${NC}"
aws eks update-kubeconfig --region $REGION --name $CLUSTER_NAME

# Install AWS Load Balancer Controller
echo -e "${YELLOW}🌐 Installing AWS Load Balancer Controller...${NC}"
eksctl utils associate-iam-oidc-provider --region $REGION --cluster $CLUSTER_NAME --approve

# Create IAM policy for ALB controller
aws iam create-policy \
    --policy-name AWSLoadBalancerControllerIAMPolicy \
    --policy-document file://scripts/alb-controller-policy.json \
    --region $REGION || echo "Policy already exists"

# Create service account for ALB controller
eksctl create iamserviceaccount \
    --region $REGION \
    --name aws-load-balancer-controller \
    --namespace kube-system \
    --cluster $CLUSTER_NAME \
    --attach-policy-arn arn:aws:iam::$(aws sts get-caller-identity --query Account --output text):policy/AWSLoadBalancerControllerIAMPolicy \
    --approve \
    --override-existing-serviceaccounts

# Install ALB controller
helm repo add eks https://aws.github.io/eks-charts
helm repo update
helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
    -n kube-system \
    --set clusterName=$CLUSTER_NAME \
    --set serviceAccount.create=false \
    --set serviceAccount.name=aws-load-balancer-controller

# Install metrics server
echo -e "${YELLOW}📊 Installing metrics server...${NC}"
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

# Install ArgoCD
echo -e "${YELLOW}🚀 Installing ArgoCD...${NC}"
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Install Jenkins on EKS
echo -e "${YELLOW}🔧 Installing Jenkins on EKS...${NC}"
kubectl apply -f k8s/jenkins-config.yaml
kubectl apply -f k8s/jenkins.yaml

# Wait for ArgoCD to be ready
echo -e "${YELLOW}⏳ Waiting for ArgoCD to be ready...${NC}"
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=argocd-server -n argocd --timeout=300s

# Deploy ArgoCD applications
echo -e "${YELLOW}🚀 Deploying ArgoCD applications...${NC}"
kubectl apply -f k8s/argocd-application.yaml

# Get ArgoCD admin password
echo -e "${GREEN}🔑 ArgoCD admin password:${NC}"
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
echo

# Install monitoring stack
echo -e "${YELLOW}📈 Installing monitoring stack...${NC}"

# Create monitoring namespace
kubectl create namespace monitoring

# Install Prometheus Operator
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

helm install prometheus prometheus-community/kube-prometheus-stack \
    --namespace monitoring \
    --set prometheus.prometheusSpec.serviceMonitorSelectorNilUsesHelmValues=false \
    --set prometheus.prometheusSpec.podMonitorSelectorNilUsesHelmValues=false \
    --set prometheus.prometheusSpec.ruleSelectorNilUsesHelmValues=false

# Install Grafana
echo -e "${YELLOW}📊 Installing Grafana...${NC}"
kubectl apply -f monitoring/grafana/

# Create ECR repositories
echo -e "${YELLOW}🐳 Creating ECR repositories...${NC}"
aws ecr create-repository --repository-name frontend --region $REGION || echo "Repository already exists"
aws ecr create-repository --repository-name user-service --region $REGION || echo "Repository already exists"
aws ecr create-repository --repository-name product-service --region $REGION || echo "Repository already exists"
aws ecr create-repository --repository-name order-service --region $REGION || echo "Repository already exists"

# Get ECR registry URL
ECR_REGISTRY=$(aws sts get-caller-identity --query Account --output text).dkr.ecr.$REGION.amazonaws.com
echo -e "${GREEN}✅ ECR Registry: $ECR_REGISTRY${NC}"

# Create SSL certificate (optional - for production)
echo -e "${YELLOW}🔒 Creating SSL certificate...${NC}"
# Note: In production, you would use AWS Certificate Manager
# aws acm request-certificate --domain-name "*.eks-microservices.com" --validation-method DNS

# Deploy application
echo -e "${YELLOW}🚀 Deploying application...${NC}"
kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/postgresql.yaml
kubectl apply -f k8s/user-service.yaml

# Wait for services to be ready
echo -e "${YELLOW}⏳ Waiting for services to be ready...${NC}"
kubectl wait --for=condition=ready pod -l app=postgres -n eks-microservices --timeout=300s
kubectl wait --for=condition=ready pod -l app=user-service -n eks-microservices --timeout=300s

# Get cluster info
echo -e "${GREEN}✅ Setup completed successfully!${NC}"
echo -e "${GREEN}📋 Cluster Information:${NC}"
echo -e "  Cluster Name: $CLUSTER_NAME"
echo -e "  Region: $REGION"
echo -e "  ECR Registry: $ECR_REGISTRY"
echo -e "  ArgoCD URL: http://localhost:8080 (after port-forward)"
echo -e "  Grafana URL: http://localhost:3000 (after port-forward)"

# Access URLs (all services run in AWS)
echo -e "${YELLOW}📖 Access URLs (all services run in AWS):${NC}"
echo -e "  1. ArgoCD: http://argocd.eks-microservices.com (after DNS setup)"
echo -e "  2. Jenkins: http://jenkins.eks-microservices.com (after DNS setup)"
echo -e "  3. Frontend: http://app.eks-microservices.com (after DNS setup)"
echo -e "  4. Grafana: http://grafana.eks-microservices.com (after DNS setup)"
echo -e "  5. For local access, use port-forwarding:"
echo -e "     - ArgoCD: kubectl port-forward svc/argocd-server 8080:80 -n argocd"
echo -e "     - Jenkins: kubectl port-forward svc/jenkins 8081:80 -n jenkins"
echo -e "     - Grafana: kubectl port-forward svc/grafana 3000:80 -n monitoring"

echo -e "${GREEN}🎉 EKS Microservices setup completed!${NC}"
