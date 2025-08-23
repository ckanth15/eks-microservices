# ArgoCD Setup Guide - EKS Microservices

## 🚀 **What is ArgoCD?**

ArgoCD is a **GitOps continuous delivery tool** that automatically syncs your Kubernetes cluster with your Git repository. It ensures that your cluster's actual state matches the desired state defined in your Git repository.

## 🏗️ **ArgoCD Architecture in Our Setup**

### **Components Deployed:**
- **ArgoCD Server**: Web UI and API server
- **ArgoCD Repo Server**: Git repository access
- **ArgoCD Application Controller**: Syncs applications
- **Redis**: Caching and session storage

### **Applications Managed:**
1. **eks-microservices**: Main application stack
2. **monitoring**: Prometheus, Grafana, and monitoring tools
3. **jenkins**: CI/CD pipeline server

## 🔧 **ArgoCD Configuration**

### **Application Definitions**

#### **1. Main Application (eks-microservices)**
```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: eks-microservices
spec:
  source:
    repoURL: https://github.com/your-username/eks-microservices.git
    path: k8s
  destination:
    namespace: eks-microservices
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
```

#### **2. Monitoring Stack**
```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: monitoring
spec:
  source:
    repoURL: https://github.com/your-username/eks-microservices.git
    path: monitoring
  destination:
    namespace: monitoring
```

#### **3. Jenkins CI/CD**
```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: jenkins
spec:
  source:
    repoURL: https://github.com/your-username/eks-microservices.git
    path: k8s/jenkins.yaml
  destination:
    namespace: jenkins
```

## 🌐 **Accessing ArgoCD**

### **Production Access**
```
URL: http://argocd.eks-microservices.com
Username: admin
Password: [retrieved from setup]
```

### **Local Development Access**
```bash
# Port forward to access ArgoCD locally
kubectl port-forward svc/argocd-server 8080:80 -n argocd

# Access at: http://localhost:8080
```

## 🔑 **Getting ArgoCD Admin Password**

```bash
# Get the initial admin password
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d
```

## 📊 **ArgoCD Dashboard Features**

### **Applications View**
- **Sync Status**: Synced, Out of Sync, Error
- **Health Status**: Healthy, Degraded, Missing
- **Last Sync**: Timestamp of last successful sync
- **Repository**: Git repository information

### **Application Details**
- **Resources**: All Kubernetes resources managed
- **Events**: Sync events and history
- **Logs**: Application logs and sync logs
- **Settings**: Application configuration

## 🔄 **GitOps Workflow**

### **1. Developer Workflow**
```bash
# 1. Make changes to your code
git add .
git commit -m "Update user service configuration"
git push origin main
```

### **2. ArgoCD Automatic Sync**
- ArgoCD detects changes in Git repository
- Automatically syncs changes to EKS cluster
- Updates application state
- Reports sync status and health

### **3. Monitoring and Alerts**
- Sync status monitoring
- Health check alerts
- Failed sync notifications
- Resource drift detection

## ⚙️ **ArgoCD Configuration Options**

### **Sync Policies**

#### **Automated Sync**
```yaml
syncPolicy:
  automated:
    prune: true        # Remove resources not in Git
    selfHeal: true     # Auto-correct drift
```

#### **Manual Sync**
```yaml
syncPolicy:
  syncOptions:
    - CreateNamespace=true
    - PrunePropagationPolicy=foreground
```

### **Sync Options**
- **CreateNamespace**: Automatically create namespaces
- **PrunePropagationPolicy**: Resource cleanup policy
- **PruneLast**: Clean up after successful sync
- **ServerSideApply**: Use server-side apply

## 🚨 **Troubleshooting ArgoCD**

### **Common Issues**

#### **1. Sync Failures**
```bash
# Check application status
kubectl get applications -n argocd

# Check application events
kubectl describe application eks-microservices -n argocd

# Check ArgoCD logs
kubectl logs -n argocd deployment/argocd-application-controller
```

#### **2. Repository Access Issues**
```bash
# Check repository connectivity
kubectl get repos -n argocd

# Test Git access
kubectl exec -n argocd deployment/argocd-repo-server -- git ls-remote <repo-url>
```

#### **3. Resource Conflicts**
```bash
# Check for resource conflicts
kubectl get applications -n argocd -o yaml

# Force sync if needed
kubectl patch application eks-microservices -n argocd \
  --type='merge' -p='{"spec":{"syncPolicy":{"automated":{"prune":true}}}}'
```

### **Health Checks**

#### **Application Health**
- **Healthy**: All resources are in desired state
- **Degraded**: Some resources have issues
- **Missing**: Resources not found in cluster
- **Unknown**: Health status cannot be determined

#### **Sync Status**
- **Synced**: Cluster matches Git repository
- **Out of Sync**: Cluster differs from Git
- **Error**: Sync operation failed
- **Unknown**: Sync status unclear

## 🔒 **Security Considerations**

### **RBAC Configuration**
```yaml
# Example RBAC for ArgoCD
apiVersion: v1
kind: ServiceAccount
metadata:
  name: argocd-application-controller
  namespace: argocd
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: argocd-application-controller
rules:
  - apiGroups: [""]
    resources: ["*"]
    verbs: ["*"]
```

### **SSO Integration**
- **OIDC**: OpenID Connect authentication
- **SAML**: SAML 2.0 authentication
- **LDAP**: LDAP authentication
- **GitHub**: GitHub OAuth

## 📈 **Monitoring ArgoCD**

### **Metrics to Track**
- **Sync Success Rate**: Percentage of successful syncs
- **Sync Duration**: Time taken for sync operations
- **Resource Count**: Number of managed resources
- **Error Rate**: Frequency of sync failures

### **Grafana Dashboards**
- **ArgoCD Overview**: General health and status
- **Sync Performance**: Sync timing and success rates
- **Resource Management**: Resource counts and health
- **Error Tracking**: Failed syncs and issues

## 🎯 **Best Practices**

### **1. Repository Structure**
```
eks-microservices/
├── k8s/                    # Main application manifests
├── monitoring/             # Monitoring stack
├── argocd/                 # ArgoCD configuration
└── jenkins/                # Jenkins configuration
```

### **2. Application Organization**
- **Group related resources** in single applications
- **Use consistent naming** conventions
- **Implement proper labels** and annotations
- **Separate environments** (dev, staging, prod)

### **3. Sync Strategies**
- **Automated sync** for development environments
- **Manual sync** for production environments
- **Prune resources** to maintain consistency
- **Self-heal** to correct drift automatically

### **4. Security**
- **Limit repository access** to necessary repos
- **Use service accounts** with minimal permissions
- **Implement RBAC** for ArgoCD access
- **Regular password rotation** for admin accounts

## 🚀 **Next Steps**

1. **Customize Applications**: Update repository URLs and paths
2. **Configure SSO**: Set up authentication integration
3. **Set Up Alerts**: Configure monitoring and notifications
4. **Implement Policies**: Add sync policies and restrictions
5. **Backup Configuration**: Export and backup ArgoCD configs

## 📚 **Additional Resources**

- [ArgoCD Official Documentation](https://argo-cd.readthedocs.io/)
- [ArgoCD GitHub Repository](https://github.com/argoproj/argo-cd)
- [GitOps Best Practices](https://www.gitops.tech/)
- [Kubernetes GitOps Patterns](https://kubernetes.io/blog/tags/gitops/)

ArgoCD provides the foundation for a robust GitOps workflow, ensuring that your EKS cluster always reflects the desired state defined in your Git repository.
