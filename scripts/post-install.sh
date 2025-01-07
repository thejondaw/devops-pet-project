#!/bin/bash

# Connecting to EKS Cluster
CLUSTER_NAME=$(aws eks list-clusters --region us-east-2 --query "clusters[?contains(@, 'develop')]|[0]" --output text)
if [ -z "$CLUSTER_NAME" ]; then
  echo "Error: Cluster not found!"
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
kubectl apply -f k8s/argocd/applications/master/metrics-server.yaml
kubectl apply -f k8s/argocd/applications/master/aws-ebs-csi-driver.yaml
kubectl apply -f k8s/argocd/applications/master/ingress-nginx.yaml
kubectl apply -f k8s/argocd/applications/master/monitoring.yaml
kubectl apply -f k8s/argocd/applications/master/vault.yaml

# kubectl apply -f k8s/argocd/applications/master/api.yaml
# kubectl apply -f k8s/argocd/applications/master/web.yaml
