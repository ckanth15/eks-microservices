# EKS Microservices WebApp

A comprehensive microservices web application designed for AWS EKS deployment with modern DevOps practices.

## 🚀 Features

- **Frontend**: React-based web application
- **Backend**: Node.js microservices (User Service, Product Service, Order Service)
- **Database**: PostgreSQL with connection pooling
- **Containerization**: Docker multi-stage builds
- **Orchestration**: Kubernetes with Helm charts and Kustomize
- **CI/CD**: Jenkins pipelines for automated builds and deployments
- **GitOps**: ArgoCD for Kubernetes deployment automation
- **Monitoring**: Prometheus, Grafana, and Splunk integration
- **Infrastructure**: AWS EKS cluster configuration

## 🏗️ Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Frontend      │    │   Backend       │    │   Database      │
│   (React)       │◄──►│   (Node.js)     │◄──►│   (PostgreSQL)  │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         ▼                       ▼                       ▼
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Ingress       │    │   Services      │    │   Persistent    │
│   Controller    │    │   (K8s)         │    │   Volumes       │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         ▼                       ▼                       ▼
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Load Balancer │    │   ArgoCD        │    │   Monitoring    │
│   (AWS ALB)     │    │   (GitOps)      │    │   Stack         │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

## 🛠️ Prerequisites

- AWS CLI configured with appropriate permissions
- kubectl installed
- Docker installed
- Jenkins server (or Jenkins on Kubernetes)
- ArgoCD CLI installed
- Helm 3.x installed

## 🚀 Quick Start (2 Hours Setup)

### 1. Infrastructure Setup (30 mins)
```bash
# Deploy EKS cluster
./scripts/setup-eks.sh

# Install required tools
./scripts/install-tools.sh
```

### 2. Application Deployment (30 mins)
```bash
# Deploy ArgoCD
kubectl apply -f argocd/

# Deploy monitoring stack
kubectl apply -f monitoring/

# Deploy application
kubectl apply -f k8s/
```

### 3. CI/CD Setup (30 mins)
```bash
# Configure Jenkins
./scripts/setup-jenkins.sh

# Import Jenkins pipelines
# (Manual step: Import Jenkinsfile from jenkins/ directory)
```

### 4. Verification (30 mins)
```bash
# Check all services
kubectl get all -A

# Access ArgoCD UI
kubectl port-forward svc/argocd-server 8080:80

# Access Grafana
kubectl port-forward svc/grafana 3000:80
```

## 📁 Project Structure

```
├── frontend/                 # React web application
├── backend/                  # Node.js microservices
├── k8s/                     # Kubernetes manifests
├── helm/                    # Helm charts
├── docker/                  # Docker configurations
├── jenkins/                 # Jenkins pipelines
├── argocd/                  # ArgoCD configurations
├── monitoring/              # Prometheus, Grafana, Splunk
├── scripts/                 # Setup and deployment scripts
├── terraform/               # Infrastructure as Code (optional)
└── docs/                    # Documentation
```

## 🔧 Configuration

### Environment Variables
- `DB_HOST`: PostgreSQL host
- `DB_PORT`: PostgreSQL port
- `DB_NAME`: Database name
- `DB_USER`: Database user
- `DB_PASSWORD`: Database password
- `JWT_SECRET`: JWT signing secret
- `AWS_REGION`: AWS region for EKS

### AWS Resources
- EKS Cluster
- RDS PostgreSQL instance
- Application Load Balancer
- ECR repositories
- S3 buckets for logs

## 📊 Monitoring

- **Prometheus**: Metrics collection
- **Grafana**: Dashboards and visualization
- **Splunk**: Log aggregation and analysis
- **Custom metrics**: Application-specific KPIs

## 🔄 CI/CD Pipeline

1. **Build**: Docker image building and testing
2. **Test**: Unit and integration tests
3. **Scan**: Security vulnerability scanning
4. **Push**: Push to ECR
5. **Deploy**: ArgoCD deployment to EKS
6. **Verify**: Health checks and monitoring

## 🚨 Troubleshooting

Common issues and solutions are documented in `docs/troubleshooting.md`.

## 📚 Documentation

- [Architecture Details](docs/architecture.md)
- [Deployment Guide](docs/deployment.md)
- [Monitoring Setup](docs/monitoring.md)
- [Troubleshooting](docs/troubleshooting.md)

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.