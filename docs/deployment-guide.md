# EKS Microservices Deployment Guide

## 🚀 Quick Start (2 Hours)

This guide will help you deploy the complete EKS Microservices WebApp in approximately 2 hours.

## 📋 Prerequisites

- AWS Account with appropriate permissions
- AWS CLI configured
- Local machine with Docker, kubectl, and helm installed
- Domain name (optional, for production)

## ⏱️ Timeline Breakdown

### Phase 1: Infrastructure Setup (30 minutes)
### Phase 2: Application Deployment (30 minutes)  
### Phase 3: CI/CD Setup (30 minutes)
### Phase 4: Verification & Testing (30 minutes)

---

## 🏗️ Phase 1: Infrastructure Setup (30 mins)

### 1.1 Clone and Setup Repository
```bash
git clone https://github.com/your-username/eks-microservices.git
cd eks-microservices
chmod +x scripts/*.sh
```

### 1.2 Configure AWS
```bash
aws configure
# Enter your AWS Access Key ID, Secret Access Key, Region, and Output format
```

### 1.3 Run EKS Setup Script
```bash
./scripts/setup-eks.sh
```

**What this script does:**
- Creates EKS cluster with 3 t3.medium nodes
- Installs AWS Load Balancer Controller
- Sets up ArgoCD for GitOps
- Installs monitoring stack (Prometheus + Grafana)
- Creates ECR repositories
- Deploys initial application components

**Expected output:**
```
✅ EKS cluster created successfully
✅ ArgoCD installed successfully
✅ Monitoring stack installed
✅ ECR repositories created
```

---

## 🚀 Phase 2: Application Deployment (30 mins)

### 2.1 Deploy Core Services
```bash
# Apply all Kubernetes manifests
kubectl apply -f k8s/

# Verify deployments
kubectl get pods -n eks-microservices
kubectl get services -n eks-microservices
```

### 2.2 Deploy Monitoring
```bash
# Deploy Prometheus and Grafana
kubectl apply -f monitoring/

# Wait for monitoring stack to be ready
kubectl wait --for=condition=ready pod -l app=grafana -n monitoring --timeout=300s
```

### 2.3 Access Services
```bash
# Port forward to access services locally
kubectl port-forward svc/argocd-server 8080:80 -n argocd &
kubectl port-forward svc/grafana 3000:80 -n monitoring &
kubectl port-forward svc/prometheus-operated 9090:9090 -n monitoring &
```

**Access URLs:**
- ArgoCD: http://localhost:8080 (admin / [password from setup])
- Grafana: http://localhost:3000 (admin / admin)
- Prometheus: http://localhost:9090

---

## 🔄 Phase 3: CI/CD Setup (30 mins)

### 3.1 Setup Jenkins
```bash
./scripts/setup-jenkins.sh
```

### 3.2 Configure Jenkins Pipeline
1. Access Jenkins at http://localhost:8080
2. Install suggested plugins
3. Create admin user
4. Create new pipeline job:
   - Name: `eks-microservices-pipeline`
   - Type: Pipeline
   - Definition: Pipeline script from SCM
   - SCM: Git
   - Repository: Your GitHub repo URL
   - Script Path: `jenkins/Jenkinsfile`

### 3.3 Configure Jenkins Credentials
1. Go to Manage Jenkins > Credentials
2. Add AWS credentials:
   - Kind: AWS Credentials
   - ID: aws-credentials
   - Access Key ID: Your AWS Access Key
   - Secret Access Key: Your AWS Secret Key

3. Add ArgoCD token:
   - Kind: Secret text
   - ID: argocd-token
   - Secret: Get from ArgoCD UI

### 3.4 Test Pipeline
```bash
# Trigger first build
curl -X POST http://localhost:8080/job/eks-microservices-pipeline/build
```

---

## ✅ Phase 4: Verification & Testing (30 mins)

### 4.1 Health Checks
```bash
# Check all pods are running
kubectl get pods -A

# Check services
kubectl get services -A

# Check ingress
kubectl get ingress -A
```

### 4.2 Test Endpoints
```bash
# Test user service health
curl http://localhost:3001/health

# Test frontend
curl http://localhost:3000/

# Test database connection
kubectl exec -it deployment/postgres -n eks-microservices -- psql -U postgres -d eks_microservices -c "SELECT version();"
```

### 4.3 Monitor Metrics
1. Open Grafana: http://localhost:3000
2. Login with admin/admin
3. Import dashboards from `monitoring/grafana/dashboards/`
4. Check Prometheus targets: http://localhost:9090/targets

---

## 🔧 Configuration

### Environment Variables
```bash
# Update these in your deployment
export AWS_REGION="us-west-2"
export ECR_REGISTRY="your-account.dkr.ecr.us-west-2.amazonaws.com"
export SSL_CERTIFICATE_ARN="arn:aws:acm:us-west-2:account:certificate/cert-id"
```

### Customization
- **Node Types**: Modify `scripts/setup-eks.sh` to change instance types
- **Scaling**: Update node group min/max values
- **Monitoring**: Customize Prometheus targets in `monitoring/prometheus.yml`
- **CI/CD**: Modify `jenkins/Jenkinsfile` for your specific needs

---

## 🚨 Troubleshooting

### Common Issues

**1. EKS Cluster Creation Fails**
```bash
# Check AWS credentials
aws sts get-caller-identity

# Check IAM permissions
aws iam get-user
```

**2. Pods Not Starting**
```bash
# Check pod events
kubectl describe pod <pod-name> -n <namespace>

# Check logs
kubectl logs <pod-name> -n <namespace>
```

**3. Services Not Accessible**
```bash
# Check service endpoints
kubectl get endpoints -n eks-microservices

# Check ingress status
kubectl describe ingress -n eks-microservices
```

**4. Jenkins Pipeline Fails**
```bash
# Check Jenkins logs
sudo tail -f /var/log/jenkins/jenkins.log

# Check build console output in Jenkins UI
```

---

## 📊 Monitoring & Alerts

### Grafana Dashboards
- **Kubernetes Cluster Overview**: Node metrics, pod status
- **Application Metrics**: Service response times, error rates
- **Database Performance**: PostgreSQL connection pool, query performance

### Prometheus Alerts
- High CPU/Memory usage
- Service down alerts
- Database connection failures
- High error rates

---

## 🔒 Security Considerations

### Network Security
- Use private subnets for worker nodes
- Implement network policies
- Use AWS Security Groups

### Access Control
- RBAC for Kubernetes
- IAM roles for AWS services
- Secrets management with Kubernetes secrets

### Container Security
- Image vulnerability scanning
- Non-root user execution
- Resource limits and requests

---

## 📈 Scaling

### Horizontal Pod Autoscaling
```bash
# Enable HPA for services
kubectl apply -f k8s/hpa/
```

### Cluster Autoscaling
```bash
# Enable cluster autoscaler
kubectl apply -f k8s/cluster-autoscaler/
```

---

## 🎯 Next Steps

1. **Production Hardening**
   - SSL certificates with AWS Certificate Manager
   - Backup and disaster recovery
   - Multi-region deployment

2. **Advanced Monitoring**
   - Splunk integration for log aggregation
   - Custom application metrics
   - Business KPI dashboards

3. **Security Enhancements**
   - Pod security policies
   - Network policies
   - Secrets management with external tools

---

## 📞 Support

- **Documentation**: Check `docs/` directory
- **Issues**: Create GitHub issues
- **Community**: Join our Slack/Discord

---

## ✅ Success Checklist

- [ ] EKS cluster running with 3+ nodes
- [ ] All microservices deployed and healthy
- [ ] ArgoCD accessible and syncing
- [ ] Jenkins pipeline building successfully
- [ ] Monitoring stack collecting metrics
- [ ] Frontend accessible via ingress
- [ ] Database connections working
- [ ] CI/CD pipeline deploying to EKS

**🎉 Congratulations! You've successfully deployed a production-ready microservices application on AWS EKS!**
