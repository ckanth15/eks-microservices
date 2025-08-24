# 🚀 Production Setup Guide for EKS Microservices

This guide will walk you through setting up your EKS microservices application for production use with your Namecheap domain, Route 53 DNS management, SSL certificates, and production-ready ingress.

## 📋 Prerequisites

- ✅ EKS cluster running with microservices deployed
- ✅ AWS CLI configured with appropriate permissions
- ✅ kubectl configured to access your EKS cluster
- ✅ Namecheap domain registered
- ✅ AWS Load Balancer Controller working (already completed)

## 🌐 Step 1: Domain and DNS Setup

### Option A: Use Your Namecheap Domain with Route 53 (Recommended)

This approach gives you the best of both worlds:
- **Keep domain registration with Namecheap** (cheaper fees)
- **Use Route 53 for DNS management** (better AWS integration)

#### 1.1 Run the Namecheap + Route 53 Setup Script

```bash
./scripts/setup-namecheap-route53.sh
```

This script will:
- Create a Route 53 hosted zone for your domain
- Create SSL certificates for all subdomains
- Provide you with nameservers to update in Namecheap
- Create DNS validation records
- Wait for certificate validation

#### 1.2 Update Nameservers in Namecheap

1. Log into your Namecheap account
2. Go to 'Domain List' → Click 'Manage' on your domain
3. Go to 'Domain' tab → 'Nameservers' section
4. Select 'Custom DNS'
5. Enter the Route 53 nameservers provided by the script
6. Click '✓' to save
7. Wait for DNS propagation (can take up to 48 hours)

### Option B: Use Route 53 for Both Registration and DNS

If you prefer to transfer your domain to Route 53:

```bash
./scripts/setup-ssl.sh
```

## 🔒 Step 2: SSL Certificate Setup

The setup scripts automatically create SSL certificates for:
- `yourdomain.com`
- `app.yourdomain.com`
- `api.yourdomain.com`
- `argocd.yourdomain.com`
- `jenkins.yourdomain.com`
- `monitoring.yourdomain.com`

**Note**: Certificate validation happens automatically once DNS records are created.

## 🚀 Step 3: Deploy Production Ingress

Once your SSL certificate is validated, deploy the production ingress:

```bash
./scripts/deploy-production-ingress.sh
```

This script will:
- Read your domain configuration from `k8s/route53-config.yaml`
- Create production ingress with HTTPS and SSL redirect
- Deploy ingress for all services (app, ArgoCD, Jenkins, monitoring)
- Test the deployment

## 📊 Step 4: Verify Production Setup

### 4.1 Check Ingress Status

```bash
kubectl get ingress -A
```

### 4.2 Test Application Access

```bash
# Test your main application
curl -I https://app.yourdomain.com

# Test ArgoCD
curl -I https://argocd.yourdomain.com

# Test Jenkins
curl -I https://jenkins.yourdomain.com

# Test Monitoring
curl -I https://monitoring.yourdomain.com
```

### 4.3 Check Load Balancer

```bash
aws elbv2 describe-load-balancers --region us-east-1 --query "LoadBalancers[?contains(Tags[?Key=='kubernetes.io/cluster/eks-microservices'].Value, 'owned')]"
```

## 🔄 Step 5: ArgoCD GitOps Deployment

### 5.1 Deploy Enhanced ArgoCD Configuration

```bash
kubectl apply -f k8s/argocd-enhanced.yaml
```

### 5.2 Verify ArgoCD Applications

```bash
kubectl get applications -n argocd
```

### 5.3 Access ArgoCD UI

Navigate to `https://argocd.yourdomain.com` and log in with:
- Username: `admin`
- Password: Get from the secret:
  ```bash
  kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
  ```

## 🚀 Step 6: Jenkins CI/CD Setup

### 6.1 Access Jenkins

Navigate to `https://jenkins.yourdomain.com`

### 6.2 Get Initial Admin Password

```bash
kubectl exec -n jenkins deployment/jenkins -- cat /run/secrets/additional/chart-admin-password
```

### 6.3 Configure Jenkins Pipeline

The Jenkins pipeline is already configured in `Jenkinsfile` and will automatically:
- Build Docker images
- Push to ECR
- Deploy to EKS via ArgoCD

## 📊 Step 7: Monitoring and Observability

### 7.1 Access Grafana

Navigate to `https://monitoring.yourdomain.com`

### 7.2 Default Credentials

- Username: `admin`
- Password: `prom-operator`

### 7.3 Import Dashboards

Pre-configured dashboards for:
- Kubernetes cluster metrics
- Microservices performance
- Application metrics

## 🔧 Step 8: Production Configuration

### 8.1 Environment Variables

Update your microservices with production environment variables:

```bash
kubectl edit configmap -n eks-microservices app-config
```

### 8.2 Resource Limits

Ensure proper resource limits are set:

```bash
kubectl get hpa -A
```

### 8.3 Backup and Recovery

Set up automated backups for:
- Database (RDS snapshots)
- Configuration (Git repository)
- Persistent volumes

## 🧪 Testing Your Production Setup

### Test Application Endpoints

```bash
# Health checks
curl https://app.yourdomain.com/health
curl https://app.yourdomain.com/api/users/health
curl https://app.yourdomain.com/api/products/health
curl https://app.yourdomain.com/api/orders/health

# API endpoints
curl https://app.yourdomain.com/api/users
curl https://app.yourdomain.com/api/products
curl https://app.yourdomain.com/api/orders
```

### Test SSL/TLS

```bash
# Check SSL certificate
openssl s_client -connect app.yourdomain.com:443 -servername app.yourdomain.com

# Test SSL redirect
curl -I http://app.yourdomain.com
# Should return 301/302 redirect to HTTPS
```

## 🚨 Troubleshooting

### Common Issues

#### 1. Certificate Validation Failed
- Check DNS records in Route 53
- Verify nameservers are updated in Namecheap
- Wait for DNS propagation

#### 2. Ingress Not Getting Address
- Check AWS Load Balancer Controller logs
- Verify IAM permissions
- Check ingress events

#### 3. DNS Resolution Issues
- Verify nameservers in Namecheap
- Check Route 53 hosted zone
- Wait for DNS propagation

#### 4. SSL/TLS Issues
- Verify certificate is issued
- Check ingress configuration
- Verify domain names match

### Useful Commands

```bash
# Check ingress status
kubectl describe ingress -A

# Check controller logs
kubectl logs -n kube-system deployment/aws-load-balancer-controller

# Check certificate status
aws acm describe-certificate --certificate-arn YOUR_CERT_ARN

# Check DNS records
aws route53 list-resource-record-sets --hosted-zone-id YOUR_HOSTED_ZONE_ID
```

## 📈 Next Steps

### Performance Optimization
- Set up horizontal pod autoscaling
- Configure resource requests and limits
- Implement caching strategies

### Security Hardening
- Network policies
- Pod security policies
- RBAC configuration
- Secrets management

### Monitoring and Alerting
- Set up Prometheus alerts
- Configure notification channels
- Create custom dashboards

### Backup and Disaster Recovery
- Automated backups
- Multi-region deployment
- Disaster recovery procedures

## 🔗 Useful Links

- [AWS Route 53 Console](https://console.aws.amazon.com/route53/)
- [AWS Certificate Manager](https://console.aws.amazon.com/acm/)
- [Namecheap Domain Management](https://ap.www.namecheap.com/Domains/DomainControlPanel)
- [ArgoCD Documentation](https://argo-cd.readthedocs.io/)
- [Jenkins Documentation](https://www.jenkins.io/doc/)
- [Prometheus Documentation](https://prometheus.io/docs/)

## 📞 Support

If you encounter issues:
1. Check the troubleshooting section above
2. Review logs and events
3. Verify configuration files
4. Check AWS service status

---

**🎉 Congratulations!** You now have a production-ready EKS microservices application with:
- ✅ Custom domain names
- ✅ SSL/TLS encryption
- ✅ Production ingress
- ✅ GitOps deployment
- ✅ CI/CD pipeline
- ✅ Monitoring and observability
