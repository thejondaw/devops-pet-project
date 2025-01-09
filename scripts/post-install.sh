#!/bin/bash

# Get environment from first argument or use develop as default
ENVIRONMENT=${1:-develop}

# Connecting to EKS Cluster
CLUSTER_NAME=$(aws eks list-clusters --region us-east-2 --query "clusters[?contains(@, '${ENVIRONMENT}')]|[0]" --output text)
if [ -z "$CLUSTER_NAME" ]; then
  echo "Error: Cluster not found for environment ${ENVIRONMENT}!"
  exit 1
fi
aws eks update-kubeconfig --name $CLUSTER_NAME --region us-east-2

# Create Infrastructure
kubectl apply -f k8s/infrastructure/namespaces.yaml
kubectl apply -f k8s/infrastructure/network-policies.yaml

# Build Helm dependencies
cd helm/charts/aws-ebs-csi-driver && helm dependency build && cd ../../..
cd helm/charts/ingress-nginx && helm dependency build && cd ../../..
cd helm/charts/monitoring && helm dependency build && cd ../../..
cd helm/charts/vault && helm dependency build && cd ../../..

# Install Applications via ArgoCD
kubectl apply -f k8s/argocd/applications/${ENVIRONMENT}/metrics-server.yaml
kubectl apply -f k8s/argocd/applications/${ENVIRONMENT}/aws-ebs-csi-driver.yaml
kubectl apply -f k8s/argocd/applications/${ENVIRONMENT}/ingress-nginx.yaml
kubectl apply -f k8s/argocd/applications/${ENVIRONMENT}/monitoring.yaml
kubectl apply -f k8s/argocd/applications/${ENVIRONMENT}/vault.yaml

# Commented out for now
# kubectl apply -f k8s/argocd/applications/${ENVIRONMENT}/api.yaml
# kubectl apply -f k8s/argocd/applications/${ENVIRONMENT}/web.yaml
