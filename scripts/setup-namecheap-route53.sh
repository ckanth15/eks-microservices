#!/bin/bash

# Namecheap + Route 53 Setup Script for EKS Microservices
# This script helps you use your Namecheap domain with Route 53 for DNS management

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🌐 Setting up Namecheap Domain with Route 53 for EKS Microservices${NC}"

# Check if AWS CLI is configured
if ! aws sts get-caller-identity &> /dev/null; then
    echo -e "${RED}❌ AWS CLI is not configured. Please run 'aws configure' first.${NC}"
    exit 1
fi

# Get the current region
REGION=$(aws configure get region)
echo -e "${BLUE}📍 Using AWS Region: ${REGION}${NC}"

# Function to get user input
get_domain() {
    local prompt="$1"
    local default="$2"
    local domain
    
    while true; do
        read -p "$prompt [$default]: " domain
        domain=${domain:-$default}
        
        if [[ $domain =~ ^[a-zA-Z0-9][a-zA-Z0-9-]+\.[a-zA-Z]{2,}$ ]]; then
            break
        else
            echo -e "${RED}❌ Invalid domain format. Please enter a valid domain (e.g., example.com)${NC}"
        fi
    done
    
    echo "$domain"
}

# Get domain information from user
echo -e "${YELLOW}Please provide your Namecheap domain information:${NC}"
MAIN_DOMAIN=$(get_domain "Enter your Namecheap domain" "example.com")
APP_SUBDOMAIN="app.$MAIN_DOMAIN"
API_SUBDOMAIN="api.$MAIN_DOMAIN"
ARGOCD_SUBDOMAIN="argocd.$MAIN_DOMAIN"
JENKINS_SUBDOMAIN="jenkins.$MAIN_DOMAIN"
MONITORING_SUBDOMAIN="monitoring.$MAIN_DOMAIN"

echo -e "${GREEN}✅ Domain configuration:${NC}"
echo "   Main Domain: $MAIN_DOMAIN"
echo "   App Subdomain: $APP_SUBDOMAIN"
echo "   API Subdomain: $API_SUBDOMAIN"
echo "   ArgoCD Subdomain: $ARGOCD_SUBDOMAIN"
echo "   Jenkins Subdomain: $JENKINS_SUBDOMAIN"
echo "   Monitoring Subdomain: $MONITORING_SUBDOMAIN"

# Check if hosted zone exists, if not create it
echo -e "${BLUE}🔍 Checking for existing Route 53 hosted zone...${NC}"
HOSTED_ZONE_ID=$(aws route53 list-hosted-zones --query "HostedZones[?Name=='$MAIN_DOMAIN.'].Id" --output text)

if [ -z "$HOSTED_ZONE_ID" ]; then
    echo -e "${YELLOW}⚠️  No hosted zone found for $MAIN_DOMAIN${NC}"
    echo -e "${BLUE}🏗️  Creating new hosted zone for $MAIN_DOMAIN...${NC}"
    
    HOSTED_ZONE_ID=$(aws route53 create-hosted-zone \
        --name "$MAIN_DOMAIN" \
        --caller-reference "$(date +%s)" \
        --query 'HostedZone.Id' \
        --output text)
    
    # Remove /hostedzone/ prefix
    HOSTED_ZONE_ID=${HOSTED_ZONE_ID#/hostedzone/}
    
    echo -e "${GREEN}✅ Created hosted zone with ID: $HOSTED_ZONE_ID${NC}"
else
    # Remove /hostedzone/ prefix
    HOSTED_ZONE_ID=${HOSTED_ZONE_ID#/hostedzone/}
    echo -e "${GREEN}✅ Found existing hosted zone: $HOSTED_ZONE_ID${NC}"
fi

# Get the nameservers for Route 53
echo -e "${BLUE}📋 Getting Route 53 nameservers...${NC}"
NAMESERVERS=$(aws route53 get-hosted-zone --id "$HOSTED_ZONE_ID" \
    --query 'DelegationSet.NameServers' --output text)

echo -e "${YELLOW}⚠️  IMPORTANT: You need to update your Namecheap domain's nameservers to:${NC}"
echo "$NAMESERVERS" | tr '\t' '\n' | nl

echo -e "${BLUE}📝 Instructions for Namecheap:${NC}"
echo "   1. Log into your Namecheap account"
echo "   2. Go to 'Domain List' → Click 'Manage' on $MAIN_DOMAIN"
echo "   3. Go to 'Domain' tab → 'Nameservers' section"
echo "   4. Select 'Custom DNS'"
echo "   5. Enter the nameservers above (one per line)"
echo "   6. Click '✓' to save"
echo "   7. Wait for DNS propagation (can take up to 48 hours)"

# Create SSL certificate
echo -e "${BLUE}🔒 Creating SSL certificate for domains...${NC}"
CERT_ARN=$(aws acm request-certificate \
    --domain-name "$MAIN_DOMAIN" \
    --subject-alternative-names "$APP_SUBDOMAIN" "$API_SUBDOMAIN" "$ARGOCD_SUBDOMAIN" "$JENKINS_SUBDOMAIN" "$MONITORING_SUBDOMAIN" \
    --validation-method DNS \
    --region "$REGION" \
    --query 'CertificateArn' \
    --output text)

echo -e "${GREEN}✅ SSL certificate created: $CERT_ARN${NC}"

# Get validation records
echo -e "${BLUE}📋 Getting DNS validation records...${NC}"
aws acm describe-certificate \
    --certificate-arn "$CERT_ARN" \
    --region "$REGION" \
    --query 'Certificate.DomainValidationOptions[].ResourceRecord' \
    --output table

echo -e "${YELLOW}⚠️  IMPORTANT: You need to create the above DNS records in Route 53.${NC}"
echo -e "${YELLOW}   The certificate will be validated once these records are created and propagated.${NC}"

# Create the validation records in Route 53
echo -e "${BLUE}🌐 Creating DNS validation records in Route 53...${NC}"

# Get validation records and create them
VALIDATION_RECORDS=$(aws acm describe-certificate \
    --certificate-arn "$CERT_ARN" \
    --region "$REGION" \
    --query 'Certificate.DomainValidationOptions[].ResourceRecord')

# Parse and create each validation record
echo "$VALIDATION_RECORDS" | jq -r '.[] | "\(.Name) \(.Type) \(.Value)"' | while read -r name type value; do
    if [ -n "$name" ] && [ -n "$type" ] && [ -n "$value" ]; then
        echo "Creating record: $name ($type) -> $value"
        
        cat > /tmp/validation-record.json << EOF
{
    "Changes": [
        {
            "Action": "UPSERT",
            "ResourceRecordSet": {
                "Name": "$name",
                "Type": "$type",
                "TTL": 300,
                "ResourceRecords": [
                    {
                        "Value": "$value"
                    }
                ]
            }
        }
    ]
}
EOF

        aws route53 change-resource-record-sets \
            --hosted-zone-id "$HOSTED_ZONE_ID" \
            --change-batch file:///tmp/validation-record.json > /dev/null 2>&1
        
        echo -e "${GREEN}✅ Created validation record for $name${NC}"
    fi
done

rm -f /tmp/validation-record.json

# Wait for certificate validation
echo -e "${BLUE}⏳ Waiting for certificate validation...${NC}"
echo -e "${YELLOW}   This may take several minutes. You can check the status in the AWS Console.${NC}"

# Function to check certificate status
check_certificate_status() {
    local status
    status=$(aws acm describe-certificate \
        --certificate-arn "$CERT_ARN" \
        --region "$REGION" \
        --query 'Certificate.Status' \
        --output text)
    echo "$status"
}

# Wait for validation (check every 30 seconds for up to 10 minutes)
MAX_ATTEMPTS=20
ATTEMPT=0

while [ $ATTEMPT -lt $MAX_ATTEMPTS ]; do
    STATUS=$(check_certificate_status)
    
    if [ "$STATUS" = "ISSUED" ]; then
        echo -e "${GREEN}✅ Certificate is now validated and issued!${NC}"
        break
    elif [ "$STATUS" = "FAILED" ]; then
        echo -e "${RED}❌ Certificate validation failed. Please check the DNS records.${NC}"
        exit 1
    else
        echo -e "${BLUE}⏳ Certificate status: $STATUS (attempt $((ATTEMPT + 1))/$MAX_ATTEMPTS)${NC}"
        ATTEMPT=$((ATTEMPT + 1))
        sleep 30
    fi
done

if [ $ATTEMPT -eq $MAX_ATTEMPTS ]; then
    echo -e "${YELLOW}⚠️  Certificate validation is taking longer than expected.${NC}"
    echo -e "${YELLOW}   Please check the status manually in the AWS Console.${NC}"
fi

# Get the load balancer DNS name
echo -e "${BLUE}🌐 Getting load balancer DNS name...${NC}"
LB_DNS=$(kubectl get ingress app-ingress -n eks-microservices -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || echo "")

if [ -n "$LB_DNS" ]; then
    echo -e "${GREEN}✅ Load balancer DNS: $LB_DNS${NC}"
    
    # Create A record for app subdomain
    echo -e "${BLUE}🌐 Creating DNS record for $APP_SUBDOMAIN...${NC}"
    
    cat > /tmp/app-record.json << EOF
{
    "Changes": [
        {
            "Action": "UPSERT",
            "ResourceRecordSet": {
                "Name": "$APP_SUBDOMAIN",
                "Type": "A",
                "AliasTarget": {
                    "HostedZoneId": "Z35SXDOTRQ7X7K",
                    "DNSName": "$LB_DNS",
                    "EvaluateTargetHealth": true
                }
            }
        }
    ]
}
EOF

    aws route53 change-resource-record-sets \
        --hosted-zone-id "$HOSTED_ZONE_ID" \
        --change-batch file:///tmp/app-record.json

    echo -e "${GREEN}✅ Created DNS record for $APP_SUBDOMAIN pointing to $LB_DNS${NC}"
    rm -f /tmp/app-record.json
else
    echo -e "${YELLOW}⚠️  Load balancer not ready yet. You can create the DNS record later.${NC}"
fi

# Update the Route 53 config with the actual values
echo -e "${BLUE}📝 Updating Route 53 configuration...${NC}"
cat > k8s/route53-config.yaml << EOF
# Route 53 Configuration for EKS Microservices
# This file contains the configuration for setting up domain names

apiVersion: v1
kind: ConfigMap
metadata:
  name: route53-config
  namespace: eks-microservices
data:
  # Domain configuration
  main_domain: "$MAIN_DOMAIN"
  app_subdomain: "$APP_SUBDOMAIN"
  api_subdomain: "$API_SUBDOMAIN"
  argocd_subdomain: "$ARGOCD_SUBDOMAIN"
  jenkins_subdomain: "$JENKINS_SUBDOMAIN"
  monitoring_subdomain: "$MONITORING_SUBDOMAIN"
  
  # Route 53 hosted zone ID
  hosted_zone_id: "$HOSTED_ZONE_ID"
  
  # Load balancer DNS name
  load_balancer_dns: "$LB_DNS"
  
  # SSL certificate ARN
  ssl_certificate_arn: "$CERT_ARN"
  
  # Nameservers (for reference)
  nameservers: "$(echo $NAMESERVERS | tr '\t' ' ')"
EOF

echo -e "${GREEN}✅ Route 53 configuration updated in k8s/route53-config.yaml${NC}"

echo -e "${GREEN}🎉 Namecheap + Route 53 setup completed!${NC}"
echo -e "${BLUE}📋 Summary:${NC}"
echo "   Domain: $MAIN_DOMAIN"
echo "   Certificate ARN: $CERT_ARN"
echo "   Hosted Zone ID: $HOSTED_ZONE_ID"
echo "   App Domain: $APP_SUBDOMAIN"
echo "   Configuration saved to: k8s/route53-config.yaml"

echo -e "${YELLOW}⚠️  IMPORTANT NEXT STEPS:${NC}"
echo "   1. Update nameservers in Namecheap (see instructions above)"
echo "   2. Wait for DNS propagation (can take up to 48 hours)"
echo "   3. Update your ingress to use the new domain and SSL certificate"
echo "   4. Test the HTTPS access to your application"

echo -e "${BLUE}🔗 Useful links:${NC}"
echo "   Route 53 Console: https://console.aws.amazon.com/route53/"
echo "   ACM Console: https://console.aws.amazon.com/acm/"
echo "   Namecheap Domain Management: https://ap.www.namecheap.com/Domains/DomainControlPanel"
