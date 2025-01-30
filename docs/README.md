# 🚀 Post-Installation Guide

A comprehensive guide for post-installation setup and access configuration for the infrastructure stack.

## 🔐 Platform Access Configuration

### EKS Cluster Access
```bash
# Get cluster name and update kubeconfig (fish shell)
set ENVIRONMENT "master"
set CLUSTER_NAME (aws eks list-clusters --region us-east-2 --query "clusters[?contains(@, '$ENVIRONMENT')]|[0]" --output text)
aws eks update-kubeconfig --name $CLUSTER_NAME --region us-east-2
```

---

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

---

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

---

### 🔒 HashiCorp Vault Configuration

#### Vault Initialization Commands

```shell
# Initialize Vault and get unsealing keys - CRITICAL: BACKUP THESE KEYS!
kubectl exec -it vault-0 -n vault -- sh
vault operator init

vault operator unseal KEY1
vault operator unseal KEY2
vault operator unseal KEY3

# Authenticate with root token
vault login ROOT_TOKEN

# Enable KV2 secrets engine and create database credentials
vault secrets enable -path=secret kv-v2

# Update Vault secret
vault kv put secret/database \
    username="jondaw" \
    password="password" \
    dbname="devopsdb"

# Configure Kubernetes authentication
vault auth enable kubernetes

vault write auth/kubernetes/config \
    kubernetes_host="https://kubernetes.default.svc"

# Create API access policy
vault policy write api-policy - <<EOF
path "secret/data/database" {
  capabilities = ["read"]
}
EOF

# Bind ServiceAccount to policy through Kubernetes role
vault write auth/kubernetes/role/api \
    bound_service_account_names=api-sa \
    bound_service_account_namespaces=app \
    policies=api-policy \
    ttl=1h
```

```shell
# Port forwarding setup
kubectl port-forward service/vault 8200:8200 -n vault

# Access URL
http://localhost:8200
```

---

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
