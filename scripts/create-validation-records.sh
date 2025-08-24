#!/bin/bash

# Script to create ACM validation records in Route 53
# This is needed if the automatic creation didn't work

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔒 Creating ACM Validation Records in Route 53${NC}"

# Certificate ARN from the setup
CERT_ARN="arn:aws:acm:us-east-1:063278365748:certificate/39cec75e-fe21-4efe-ad10-3c4753824b87"
HOSTED_ZONE_ID="Z090189813515X2U5CS1C"

echo -e "${BLUE}📋 Getting validation records from ACM...${NC}"

# Get validation records
VALIDATION_RECORDS=$(aws acm describe-certificate \
    --certificate-arn "$CERT_ARN" \
    --query 'Certificate.DomainValidationOptions[].ResourceRecord' \
    --output json)

echo -e "${GREEN}✅ Found validation records:${NC}"
echo "$VALIDATION_RECORDS" | jq -r '.[] | "\(.Name) (\(.Type)) -> \(.Value)"'

# Create each validation record
echo -e "${BLUE}🌐 Creating validation records in Route 53...${NC}"

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
            --change-batch file:///tmp/validation-record.json

        echo -e "${GREEN}✅ Created validation record for $name${NC}"
    fi
done

rm -f /tmp/validation-record.json

echo -e "${GREEN}🎉 All validation records created!${NC}"
echo -e "${YELLOW}⚠️  Now you need to:${NC}"
echo "   1. Update nameservers in Namecheap to the Route 53 ones"
echo "   2. Wait for DNS propagation (can take up to 48 hours)"
echo "   3. Check certificate status:"
echo "      aws acm describe-certificate --certificate-arn $CERT_ARN --query 'Certificate.Status'"
