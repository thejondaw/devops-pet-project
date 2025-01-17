#!/bin/bash

# Set default environment if not provided
ENVIRONMENT=${1:-develop}
AWS_REGION=${2:-us-east-2}

echo "=== Starting cleanup for $ENVIRONMENT environment ==="

# Get EKS cluster name
CLUSTER_NAME=$(aws eks list-clusters --region $AWS_REGION --query "clusters[?contains(@, '${ENVIRONMENT}')]|[0]" --output text)

if [ -z "$CLUSTER_NAME" ]; then
  echo "No EKS cluster found for environment $ENVIRONMENT"
  exit 1
fi

echo "Found cluster: $CLUSTER_NAME"

# Update kubeconfig
aws eks update-kubeconfig --name $CLUSTER_NAME --region $AWS_REGION

# Function to delete namespace and wait for completion
delete_namespace() {
  local ns=$1
  if kubectl get namespace $ns &>/dev/null; then
    echo "Removing namespace: $ns"
    kubectl delete namespace $ns --wait=true
    while kubectl get namespace $ns &>/dev/null; do
      echo "Waiting for $ns namespace to be fully removed..."
      sleep 5
    done
  else
    echo "Namespace $ns not found, skipping..."
  fi
}

# Delete namespaces and their resources
NAMESPACES=("argocd" "monitoring" "vault" "ingress-nginx")
for ns in "${NAMESPACES[@]}"; do
  delete_namespace $ns
done

# Find and delete all NLB load balancers created by Kubernetes
echo "=== Cleaning up leftover NLB load balancers ==="
LBS=$(aws elbv2 describe-load-balancers --region $AWS_REGION --query "LoadBalancers[?Type=='network'].[LoadBalancerArn,LoadBalancerName]" --output text)
while IFS=$'\t' read -r lb_arn lb_name; do
  if [[ "$lb_name" == *"$ENVIRONMENT"* ]] || [[ "$lb_name" == *"k8s"* ]]; then
    echo "Deleting load balancer: $lb_name"
    aws elbv2 delete-load-balancer --load-balancer-arn "$lb_arn" --region $AWS_REGION
  fi
done <<<"$LBS"

# Delete IAM role for Vault
VAULT_ROLE="${ENVIRONMENT}-vault-role"
echo "=== Cleaning up IAM role: $VAULT_ROLE ==="

# First detach all policies
for policy_arn in $(aws iam list-attached-role-policies --role-name $VAULT_ROLE --query 'AttachedPolicies[*].PolicyArn' --output text 2>/dev/null); do
  echo "Detaching policy: $policy_arn from role: $VAULT_ROLE"
  aws iam detach-role-policy --role-name $VAULT_ROLE --policy-arn $policy_arn
done

# Delete inline policies
for policy_name in $(aws iam list-role-policies --role-name $VAULT_ROLE --query 'PolicyNames[*]' --output text 2>/dev/null); do
  echo "Deleting inline policy: $policy_name from role: $VAULT_ROLE"
  aws iam delete-role-policy --role-name $VAULT_ROLE --policy-name $policy_name
done

# Finally delete the role
if aws iam get-role --role-name $VAULT_ROLE &>/dev/null; then
  echo "Deleting role: $VAULT_ROLE"
  aws iam delete-role --role-name $VAULT_ROLE
fi

echo "=== Cleanup completed ==="
echo "Now you can safely run 'terraform destroy'"
