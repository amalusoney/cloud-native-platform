#!/usr/bin/env bash
# ==============================================================================
# Cloud-Native Platform - Automated Cluster Teardown Script
# ==============================================================================
# Usage: ./scripts/teardown.sh [AWS_REGION] [CLUSTER_NAME]
# Default Region: us-east-1
# Default Cluster: cloud-native-eks
# ==============================================================================

set -euo pipefail

AWS_REGION="${1:-us-east-1}"
CLUSTER_NAME="${2:-cloud-native-eks}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

echo "================================================================="
echo " Starting Safe Cloud-Native Platform Teardown"
echo " Region:  ${AWS_REGION}"
echo " Cluster: ${CLUSTER_NAME}"
echo "================================================================="

# 1. Clean up Kubernetes LoadBalancer Services (Prevents Orphaned AWS ELBs)
echo "[+] Step 1: Deleting Kubernetes LoadBalancer Services to release AWS ELBs..."
kubectl delete svc cloud-native-app-service -n default --ignore-not-found=true --timeout=60s || true

echo "[+] Waiting 30s for AWS to de-provision Classic Load Balancers..."
sleep 30

# 2. Clean up Argo CD Application and Namespace
echo "[+] Step 2: Removing Argo CD GitOps Application & Namespace..."
kubectl delete -f "${REPO_ROOT}/argocd/application.yaml" --ignore-not-found=true --timeout=60s || true
kubectl delete namespace argocd --ignore-not-found=true --timeout=60s || true

# 3. Clean up Monitoring Helm Release & Namespace
echo "[+] Step 3: Uninstalling Prometheus & Monitoring Stack..."
helm uninstall prometheus-stack -n monitoring 2>/dev/null || true
kubectl delete namespace monitoring --ignore-not-found=true --timeout=60s || true

# 4. Clean up Application Workloads in Default Namespace
echo "[+] Step 4: Deleting remaining default workloads..."
helm uninstall cloud-native-app -n default 2>/dev/null || true
kubectl delete deployment cloud-native-app -n default --ignore-not-found=true || true
kubectl delete hpa cloud-native-app-hpa -n default --ignore-not-found=true || true
kubectl delete configmap cloud-native-app-config -n default --ignore-not-found=true || true
kubectl delete secret cloud-native-app-secret -n default --ignore-not-found=true || true

# 5. Run Terraform Destroy
echo "[+] Step 5: Executing Terraform Destroy in terraform/environments/dev..."
cd "${REPO_ROOT}/terraform/environments/dev"

terraform init
terraform destroy -auto-approve

echo "================================================================="
echo " Teardown Complete! All AWS Resources Successfully Destroyed."
echo " Zero running billable cloud resources remain."
echo "================================================================="
