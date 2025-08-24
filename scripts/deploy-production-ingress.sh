#!/bin/bash

# Production Ingress Deployment Script
# This script deploys the production ingress with your actual domain values

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 Deploying Production Ingress for EKS Microservices${NC}"

# Check if route53-config.yaml exists
if [ ! -f "k8s/route53-config.yaml" ]; then
    echo -e "${RED}❌ Route 53 configuration not found. Please run the setup-namecheap-route53.sh script first.${NC}"
    exit 1
fi

# Extract values from route53-config.yaml
echo -e "${BLUE}📋 Reading configuration from route53-config.yaml...${NC}"

# Function to extract value from ConfigMap
extract_value() {
    local key="$1"
    local value
    value=$(grep "^  $key:" k8s/route53-config.yaml | cut -d':' -f2 | tr -d ' "')
    echo "$value"
}

# Extract configuration values
APP_SUBDOMAIN=$(extract_value "app_subdomain")
ARGOCD_SUBDOMAIN=$(extract_value "argocd_subdomain")
JENKINS_SUBDOMAIN=$(extract_value "jenkins_subdomain")
MONITORING_SUBDOMAIN=$(extract_value "monitoring_subdomain")
SSL_CERTIFICATE_ARN=$(extract_value "ssl_certificate_arn")

# Validate extracted values
if [ -z "$APP_SUBDOMAIN" ] || [ "$APP_SUBDOMAIN" = "yourdomain.com" ]; then
    echo -e "${RED}❌ Invalid app_subdomain in route53-config.yaml${NC}"
    exit 1
fi

if [ -z "$SSL_CERTIFICATE_ARN" ] || [ "$SSL_CERTIFICATE_ARN" = "TO_BE_CREATED" ]; then
    echo -e "${RED}❌ SSL certificate not ready. Please complete the SSL setup first.${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Configuration loaded:${NC}"
echo "   App Domain: $APP_SUBDOMAIN"
echo "   ArgoCD Domain: $ARGOCD_SUBDOMAIN"
echo "   Jenkins Domain: $JENKINS_SUBDOMAIN"
echo "   Monitoring Domain: $MONITORING_SUBDOMAIN"
echo "   SSL Certificate: $SSL_CERTIFICATE_ARN"

# Create a temporary production ingress file with actual values
echo -e "${BLUE}📝 Creating production ingress with actual domain values...${NC}"

# Replace placeholders in the production ingress template
sed "s/\${APP_SUBDOMAIN}/$APP_SUBDOMAIN/g; \
     s/\${ARGOCD_SUBDOMAIN}/$ARGOCD_SUBDOMAIN/g; \
     s/\${JENKINS_SUBDOMAIN}/$JENKINS_SUBDOMAIN/g; \
     s/\${MONITORING_SUBDOMAIN}/$MONITORING_SUBDOMAIN/g; \
     s|\${SSL_CERTIFICATE_ARN}|$SSL_CERTIFICATE_ARN|g" \
     k8s/production-ingress.yaml > /tmp/production-ingress-deployed.yaml

echo -e "${GREEN}✅ Production ingress file created${NC}"

# Backup current ingress
echo -e "${BLUE}💾 Backing up current ingress...${NC}"
if kubectl get ingress app-ingress -n eks-microservices >/dev/null 2>&1; then
    kubectl get ingress app-ingress -n eks-microservices -o yaml > k8s/app-ingress-backup.yaml
    echo -e "${GREEN}✅ Current ingress backed up to k8s/app-ingress-backup.yaml${NC}"
fi

# Deploy the production ingress
echo -e "${BLUE}🚀 Deploying production ingress...${NC}"
kubectl apply -f /tmp/production-ingress-deployed.yaml

echo -e "${GREEN}✅ Production ingress deployed successfully!${NC}"

# Wait for the ingress to get an address
echo -e "${BLUE}⏳ Waiting for ingress to get an address...${NC}"
sleep 30

# Check ingress status
echo -e "${BLUE}📊 Checking ingress status...${NC}"
kubectl get ingress -A

# Get the production ingress address
PROD_INGRESS_ADDRESS=$(kubectl get ingress production-ingress -n eks-microservices -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || echo "")

if [ -n "$PROD_INGRESS_ADDRESS" ]; then
    echo -e "${GREEN}✅ Production ingress address: $PROD_INGRESS_ADDRESS${NC}"
    
    # Test the application
    echo -e "${BLUE}🧪 Testing application access...${NC}"
    
    # Test HTTP (should redirect to HTTPS)
    echo -e "${BLUE}   Testing HTTP access to $APP_SUBDOMAIN...${NC}"
    HTTP_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" "http://$APP_SUBDOMAIN/" || echo "000")
    
    if [ "$HTTP_RESPONSE" = "301" ] || [ "$HTTP_RESPONSE" = "302" ]; then
        echo -e "${GREEN}   ✅ HTTP redirect working (status: $HTTP_RESPONSE)${NC}"
    else
        echo -e "${YELLOW}   ⚠️  HTTP response: $HTTP_RESPONSE${NC}"
    fi
    
    # Test HTTPS
    echo -e "${BLUE}   Testing HTTPS access to $APP_SUBDOMAIN...${NC}"
    HTTPS_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" "https://$APP_SUBDOMAIN/" || echo "000")
    
    if [ "$HTTPS_RESPONSE" = "200" ]; then
        echo -e "${GREEN}   ✅ HTTPS access working (status: $HTTPS_RESPONSE)${NC}"
    else
        echo -e "${YELLOW}   ⚠️  HTTPS response: $HTTPS_RESPONSE${NC}"
    fi
    
else
    echo -e "${YELLOW}⚠️  Production ingress doesn't have an address yet. This may take a few minutes.${NC}"
fi

# Clean up temporary file
rm -f /tmp/production-ingress-deployed.yaml

echo -e "${GREEN}🎉 Production ingress deployment completed!${NC}"
echo -e "${BLUE}📋 Summary:${NC}"
echo "   App Domain: $APP_SUBDOMAIN"
echo "   ArgoCD Domain: $ARGOCD_SUBDOMAIN"
echo "   Jenkins Domain: $JENKINS_SUBDOMAIN"
echo "   Monitoring Domain: $MONITORING_SUBDOMAIN"
echo "   Load Balancer: $PROD_INGRESS_ADDRESS"

echo -e "${YELLOW}⚠️  Next steps:${NC}"
echo "   1. Wait for DNS propagation (if you just updated nameservers)"
echo "   2. Test access to your application at https://$APP_SUBDOMAIN"
echo "   3. Test ArgoCD at https://$ARGOCD_SUBDOMAIN"
echo "   4. Test Jenkins at https://$JENKINS_SUBDOMAIN"
echo "   5. Test Monitoring at https://$MONITORING_SUBDOMAIN"

echo -e "${BLUE}🔗 Your application URLs:${NC}"
echo "   🌐 Main App: https://$APP_SUBDOMAIN"
echo "   🔄 ArgoCD: https://$ARGOCD_SUBDOMAIN"
echo "   🚀 Jenkins: https://$JENKINS_SUBDOMAIN"
echo "   📊 Monitoring: https://$MONITORING_SUBDOMAIN"
