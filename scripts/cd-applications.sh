#!/bin/bash -e

# Set up logging
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_DIR="${SCRIPT_DIR}/../logs"
mkdir -p "${LOG_DIR}"
LOG_FILE="${LOG_DIR}/deployment-$(date +%Y%m%d-%H%M%S).log"

# Logging function
log() {
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[${timestamp}] $1" | tee -a "${LOG_FILE}"
}

# Error handling
handle_error() {
    local exit_code=$?
    log "ERROR: Command failed with exit code: ${exit_code}"
    log "Error occurred on line: ${BASH_LINENO[0]}"
    exit "${exit_code}"
}
trap handle_error ERR

# Get environment from first argument or use develop as default
ENVIRONMENT=${1:-develop}
log "Starting deployment to environment: ${ENVIRONMENT}"

# Connecting to EKS Cluster
log "Looking for EKS cluster..."
CLUSTER_NAME=$(aws eks list-clusters --region us-east-2 --query "clusters[?contains(@, '${ENVIRONMENT}')]|[0]" --output text)
if [ -z "$CLUSTER_NAME" ]; then
    log "Error: Cluster not found for environment ${ENVIRONMENT}!"
    exit 1
fi
log "Connecting to cluster: ${CLUSTER_NAME}"
aws eks update-kubeconfig --name $CLUSTER_NAME --region us-east-2

# Function to wait for deployment
wait_for_deployment() {
    local namespace=$1
    local label=$2
    local timeout=${3:-300s}

    log "Waiting for deployment in namespace ${namespace} with label ${label}..."
    if ! kubectl wait --for=condition=Available deployment -n "${namespace}" -l "${label}" --timeout="${timeout}"; then
        log "Deployment failed! Pod status:"
        kubectl get pods -n "${namespace}" -l "${label}" -o wide
        exit 1
    fi
}

# Create Infrastructure
log "Creating base infrastructure..."
kubectl apply -f k8s/infrastructure/namespaces.yaml
kubectl apply -f k8s/infrastructure/network-policies.yaml

# Install Applications via ArgoCD
log "Installing via ArgoCD..."

# Metrics Server
log "Deploying Metrics Server..."
kubectl apply -f k8s/argocd/applications/${ENVIRONMENT}/metrics-server.yaml
wait_for_deployment "kube-system" "app.kubernetes.io/name=metrics-server"

# AWS EBS CSI Driver
log "Deploying AWS EBS CSI Driver..."
kubectl apply -f k8s/argocd/applications/${ENVIRONMENT}/aws-ebs-csi-driver.yaml
wait_for_deployment "kube-system" "app.kubernetes.io/name=aws-ebs-csi-driver"

# Ingress Nginx
log "Deploying Ingress Nginx..."
kubectl apply -f k8s/argocd/applications/${ENVIRONMENT}/ingress-nginx.yaml
wait_for_deployment "ingress-nginx" "app.kubernetes.io/name=ingress-nginx"

# Monitoring
log "Deploying monitoring stack..."
kubectl apply -f k8s/argocd/applications/${ENVIRONMENT}/monitoring.yaml
wait_for_deployment "monitoring" "app.kubernetes.io/name=prometheus"
wait_for_deployment "monitoring" "app.kubernetes.io/name=grafana"

# Vault
log "Deploying Vault..."
kubectl apply -f k8s/argocd/applications/${ENVIRONMENT}/vault.yaml
wait_for_deployment "vault" "app.kubernetes.io/name=vault"

# Applications
# log "Deploying applications..."
# kubectl apply -f k8s/argocd/applications/${ENVIRONMENT}/api.yaml
# wait_for_deployment "app" "app.kubernetes.io/name=api"
# kubectl apply -f k8s/argocd/applications/${ENVIRONMENT}/web.yaml
# wait_for_deployment "app" "app.kubernetes.io/name=web"

log "Deployment completed successfully! Logs saved to: ${LOG_FILE}"
