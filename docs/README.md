# Notes of Post-Install process

---

## Login - EKS Cluster

```shell
# Show Name of Cluster and Login (fish)
set CLUSTER_NAME (aws eks list-clusters --region us-east-2 --query "clusters[?contains(@, 'develop')]|[0]" --output text)
aws eks update-kubeconfig --name $CLUSTER_NAME --region us-east-2
```

---

## Login - Argo-CD

```shell
echo "URL:" && \
kubectl -n argocd get svc argocd-server -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' && \
echo && \
echo "Password:" && \
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d && \
echo
```

---

## Login - Grafana

```shell
echo "URL:" && \
kubectl get svc -n monitoring monitoring-grafana -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' && \
echo && \
echo "Credentials:" && \
echo "admin/"$(kubectl get secret -n monitoring monitoring-grafana -o jsonpath="{.data.admin-password}" | base64 --decode) && \
echo
```

```shell
╔════════════════════════════════════════════════╗
║ Node Monitoring Setup:                         ║
║ 1. Grafana -> Dashboards -> Import             ║
║ 2. Import ID: 1860 (Node Exporter Full)        ║
║    - URL: http://monitoring-prometheus-server  ║
║    - Datasource: Prometheus                    ║
║ 3. Import & Configure                          ║
╚════════════════════════════════════════════════╝

╔════════════════════════════════════════════════╗
║ Pods Logging Setup:                            ║
║ 1. Grafana -> Dashboards -> Import             ║
║ 2. Import ID: 15141(Loki Kubernetes Logs)      ║
║    - URL:                                      ║
║    - Datasource: Loki                          ║
║ 3. Import & Configure                          ║
╚════════════════════════════════════════════════╝

# Node Exporter Dashboard: https://grafana.com/grafana/dashboards/1860
# Kubernetes Dashboard: https://grafana.com/grafana/dashboards/315
```

---

## Login - HashiCorp Vault

```shell
# Forvarding of port
kubectl port-forward service/vault 8200:8200 -n vault

# Website after forwarding
http://localhost:8200

# Exec Pod and Init
kubectl exec -n vault vault-0 -- vault operator init
```

> - Unseal Key 1: pCTZi4aO+rdGBaDX93G7dwiA5v4mpPe2Djy7mZbPtO+p
> - Unseal Key 2: JAzAFgq4zagwAWluGVC18t/UxdKPVobF4oWjgJEbbDry
> - Unseal Key 3: P+MIG/L+pitQwFrmsqQilXqt+fmOd4PkKjTUZEma/HPa
> - Unseal Key 4: vLk5YR7ybb9Cz9gjJPo4LoOfqcIYfSCIuWG53jtY77jx
> - Unseal Key 5: w4b14teHsZVyPEgJXyZWZ4J13EurYZXZ3x88D4lPhgtY
>
> - Initial Root Token: <VAULT_TOKEN>

```shell
# Exec Pod three times with Keys
kubectl exec -it vault-0 -n vault -- vault operator unseal pCTZi4aO+rdGBaDX93G7dwiA5v4mpPe2Djy7mZbPtO+p
kubectl exec -it vault-0 -n vault -- vault operator unseal JAzAFgq4zagwAWluGVC18t/UxdKPVobF4oWjgJEbbDry
kubectl exec -it vault-0 -n vault -- vault operator unseal P+MIG/L+pitQwFrmsqQilXqt+fmOd4PkKjTUZEma/HPa

# Login with "Initial Root Token"
kubectl exec -it vault-0 -n vault -- vault login

# Create "KV Engine" for Secrets
kubectl exec -it vault-0 -n vault -- vault secrets enable -path=secret kv-v2


# Create secret
kubectl exec -it vault-0 -n vault -- vault kv put secret/database/rds \
    username=myuser \
    password=mypassword

# Get secret
kubectl exec -it vault-0 -n vault -- vault kv get secret/database/rds
```

### Delete & Re-Apply

```shell
# 1. Delete - IAM Role of Vault - Manually
# 2. Delete - EC2 - Volumes - Manually

# 3. This
helm uninstall argocd -n argocd
kubectl delete namespace argocd

# Need to try
argocd app delete monitoring --cascade

# 4. Only after that
make apply-tools
bash scripts/post-install.sh

# If needs to delete
k delete all --all -n develop

k delete -f k8s/argocd/applications/develop/monitoring.yaml
k delete all --all -n monitoring
k delete cm --all -n monitoring
k delete secret --all -n monitoring
k delete serviceaccount --all -n monitoring
k delete rolebinding --all -n monitoring
k delete role --all -n monitoring
# k delete pv --all -n monitoring
k delete pvc --all -n monitoring
k delete clusterrolebinding --selector=release=grafana-prometheus
k delete clusterrole --selector=release=grafana-prometheus
k delete ns monitoring

k delete all --all -n vault
k delete all --all -n ingress-nginx
```

---

### HELM Install (Local)

```shell
# Download script of installation
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3

# Access to script & run script
chmod 700 get_helm.sh && bash get_helm.sh
```

---

### Kubernetes Aliases

```shell
# For Bash / ZSH (Change "/.bashrc" to "/.zshrc")
echo 'alias k="kubectl" && alias kc="kubectl config" && alias kcc="kubectl config current-context" && alias kcg="kubectl config get-contexts" && alias kcs="kubectl config set-context" && alias kcu="kubectl config use-context" && alias ka="kubectl apply -f" && alias kd="kubectl delete" && alias kdf="kubectl delete -f" && alias kdp="kubectl delete pod" && alias kg="kubectl get" && alias kga="kubectl get all" && alias kgaa="kubectl get all --all-namespaces" && alias kgn="kubectl get nodes" && alias kgno="kubectl get nodes -o wide" && alias kgp="kubectl get pods" && alias kgpa="kubectl get pods --all-namespaces" && alias kgpo="kubectl get pods -o wide" && alias kgs="kubectl get services" && alias kgsa="kubectl get services --all-namespaces" && alias kl="kubectl logs" && alias klf="kubectl logs -f" && alias kpf="kubectl port-forward" && alias kex="kubectl exec -it" && alias kdesc="kubectl describe" && alias ktp="kubectl top pod" && alias ktn="kubectl top node"' >> ~/.bashrc && source ~/.bashrc
```

---

### Piece of Shit

```shell
# Find DB Name & Patch (Not work with Argo-CD Manifests)
DB_ENDPOINT=$(aws rds describe-db-instances --query 'DBInstances[0].Endpoint.Address' --output text)
k patch configmap api-cm -n develop -p "{\"data\":{\"DB_HOST\":\"$DB_ENDPOINT\"}}"
```
