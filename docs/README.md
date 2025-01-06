# 🚀 Post-Installation Guide

A comprehensive guide for post-installation setup and access configuration for the infrastructure stack.

## 🔐 Platform Access Configuration

### EKS Cluster Access
```bash
# Get cluster name and update kubeconfig (fish shell)
set CLUSTER_NAME (aws eks list-clusters --region us-east-2 --query "clusters[?contains(@, 'develop')]|[0]" --output text)
aws eks update-kubeconfig --name $CLUSTER_NAME --region us-east-2
```

### ArgoCD Access
```bash
# Get ArgoCD URL and initial credentials
echo "URL:" && \
kubectl -n argocd get svc argocd-server -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' && \
echo && \
echo "Password:" && \
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d && \
echo
```

### Grafana Setup
```bash
# Get Grafana access details
echo "URL:" && \
kubectl get svc -n monitoring monitoring-grafana -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' && \
echo && \
echo "Credentials:" && \
echo "admin/"$(kubectl get secret -n monitoring monitoring-grafana -o jsonpath="{.data.admin-password}" | base64 --decode) && \
echo
```

#### Grafana Dashboard Configuration
```plaintext
╔══ Node Monitoring Setup ═══════════════════════╗
║ 1. Navigate: Grafana -> Dashboards -> Import   ║
║ 2. Use Dashboard ID: 1860 (Node Exporter)      ║
║    - URL: http://monitoring-prometheus-server  ║
║    - Source: Prometheus                        ║
║ 3. Save & Configure                            ║
╚════════════════════════════════════════════════╝

╔══ Pod Logging Setup ══════════════════════════╗
║ 1. Navigate: Grafana -> Dashboards -> Import  ║
║ 2. Use Dashboard ID: 15141 (Loki Logs)        ║
║    - Source: Loki                             ║
║ 3. Save & Configure                           ║
╚═══════════════════════════════════════════════╝
```

**Dashboard URLs:**
- Node Exporter: https://grafana.com/grafana/dashboards/1860
- Kubernetes: https://grafana.com/grafana/dashboards/315

### 🔒 HashiCorp Vault Configuration

```bash
# Port forwarding setup
kubectl port-forward service/vault 8200:8200 -n vault

# Access URL
http://localhost:8200

# Initialize Vault
kubectl exec -n vault vault-0 -- vault operator init
```

#### Vault Unseal Process
Store these keys securely - losing them means goodbye to your secrets! 🔑
```plaintext
Unseal Key 1: pCTZi4aO+rdGBaDX93G7dwiA5v4mpPe2Djy7mZbPtO+p
Unseal Key 2: JAzAFgq4zagwAWluGVC18t/UxdKPVobF4oWjgJEbbDry
Unseal Key 3: P+MIG/L+pitQwFrmsqQilXqt+fmOd4PkKjTUZEma/HPa
Unseal Key 4: vLk5YR7ybb9Cz9gjJPo4LoOfqcIYfSCIuWG53jtY77jx
Unseal Key 5: w4b14teHsZVyPEgJXyZWZ4J13EurYZXZ3x88D4lPhgtY

Initial Root Token: <VAULT_TOKEN>
```

#### Vault Initialization Commands
```bash
# Unseal Vault (need 3 keys)
kubectl exec -it vault-0 -n vault -- vault operator unseal ${KEY1}
kubectl exec -it vault-0 -n vault -- vault operator unseal ${KEY2}
kubectl exec -it vault-0 -n vault -- vault operator unseal ${KEY3}

# Login and setup
kubectl exec -it vault-0 -n vault -- vault login
kubectl exec -it vault-0 -n vault -- vault secrets enable -path=secret kv-v2

# Manage secrets
kubectl exec -it vault-0 -n vault -- vault kv put secret/database/rds \
    username=myuser \
    password=mypassword

kubectl exec -it vault-0 -n vault -- vault kv get secret/database/rds
```

## 🧹 Infrastructure Cleanup Scripts

### Full Platform Cleanup
```bash
# Critical manual steps first!
# 1. Delete Vault IAM Role manually
# 2. Delete EC2 Volumes manually

# Remove ArgoCD
helm uninstall argocd -n argocd
kubectl delete namespace argocd

# Optional: Remove monitoring with cascade
argocd app delete monitoring --cascade

# Rebuild platform tools
make apply-tools
bash scripts/post-install.sh
```

### Namespace Cleanup Commands
```bash
# Development namespace
kubectl delete all --all -n develop

# Monitoring stack cleanup
kubectl delete -f k8s/argocd/applications/develop/monitoring.yaml
kubectl delete all --all -n monitoring
kubectl delete cm --all -n monitoring
kubectl delete secret --all -n monitoring
kubectl delete serviceaccount --all -n monitoring
kubectl delete rolebinding --all -n monitoring
kubectl delete role --all -n monitoring
kubectl delete pvc --all -n monitoring
kubectl delete clusterrolebinding --selector=release=grafana-prometheus
kubectl delete clusterrole --selector=release=grafana-prometheus
kubectl delete ns monitoring

# Other components
kubectl delete all --all -n vault
kubectl delete all --all -n ingress-nginx
```

## 🛠️ Local Development Setup

### Helm Installation
```bash
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
chmod 700 get_helm.sh && bash get_helm.sh
```

### Kubernetes Aliases Setup
```bash
# For Bash/ZSH (adjust path accordingly)
echo 'alias k="kubectl"
alias kc="kubectl config"
alias kcc="kubectl config current-context"
alias kcg="kubectl config get-contexts"
alias kcs="kubectl config set-context"
alias kcu="kubectl config use-context"
alias ka="kubectl apply -f"
alias kd="kubectl delete"
alias kdf="kubectl delete -f"
alias kdp="kubectl delete pod"
alias kg="kubectl get"
alias kga="kubectl get all"
alias kgaa="kubectl get all --all-namespaces"
alias kgn="kubectl get nodes"
alias kgno="kubectl get nodes -o wide"
alias kgp="kubectl get pods"
alias kgpa="kubectl get pods --all-namespaces"
alias kgpo="kubectl get pods -o wide"
alias kgs="kubectl get services"
alias kgsa="kubectl get services --all-namespaces"
alias kl="kubectl logs"
alias klf="kubectl logs -f"
alias kpf="kubectl port-forward"
alias kex="kubectl exec -it"
alias kdesc="kubectl describe"
alias ktp="kubectl top pod"
alias ktn="kubectl top node"' >> ~/.bashrc && source ~/.bashrc
```

## 🚨 Known Issues & Workarounds

### RDS Endpoint Configuration
```bash
# Get RDS endpoint (note: doesn't work with ArgoCD manifests)
DB_ENDPOINT=$(aws rds describe-db-instances --query 'DBInstances[0].Endpoint.Address' --output text)
kubectl patch configmap api-cm -n develop -p "{\"data\":{\"DB_HOST\":\"$DB_ENDPOINT\"}}"
```
