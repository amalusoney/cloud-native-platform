#!/usr/bin/env bash
# ==============================================================================
# Cloud-Native Platform - Automated Cluster Bootstrap Script
# ==============================================================================
# Usage: ./scripts/bootstrap.sh [AWS_REGION] [CLUSTER_NAME]
# Default Region: us-east-1
# Default Cluster: cloud-native-eks
# ==============================================================================

set -euo pipefail

AWS_REGION="${1:-us-east-1}"
CLUSTER_NAME="${2:-cloud-native-eks}"

echo "================================================================="
echo " Starting Cloud-Native Platform Bootstrap"
echo " Region:  ${AWS_REGION}"
echo " Cluster: ${CLUSTER_NAME}"
echo "================================================================="

# 1. Prerequisite Checks
echo "[+] Checking required CLI tools..."
for tool in aws kubectl helm terraform; do
  if ! command -v "${tool}" &>/dev/null; then
    echo "[!] Error: Required tool '${tool}' is not installed or not in PATH."
    exit 1
  fi
  echo "    - ${tool}: $(command -v "${tool}")"
done

# 2. Update Kubeconfig
echo "[+] Updating local kubeconfig from AWS EKS..."
aws eks update-kubeconfig --name "${CLUSTER_NAME}" --region "${AWS_REGION}"

# 3. Verify Cluster Connectivity
echo "[+] Verifying cluster connectivity..."
kubectl get nodes -o wide

# 4. Deploy Monitoring Stack (Prometheus, Grafana, Alertmanager)
echo "[+] Setting up Monitoring & Observability Stack..."
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts 2>/dev/null || true
helm repo update prometheus-community

kubectl create namespace monitoring --dry-run=client -o yaml | kubectl apply -f -
helm upgrade --install prometheus-stack prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  -f monitoring/values-prometheus.yaml

kubectl apply -f monitoring/app-alerts.yaml
echo "[+] Monitoring stack deployed successfully."

# 5. Deploy Argo CD (GitOps Controller)
echo "[+] Deploying Argo CD GitOps Controller..."
kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
kubectl apply --server-side --force-conflicts -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Scale down non-essential controllers to save memory on small nodes
kubectl scale deployment argocd-dex-server --replicas=0 -n argocd || true
kubectl scale deployment argocd-notifications-controller --replicas=0 -n argocd || true

# 6. Apply GitOps Application Manifest
echo "[+] Applying Argo CD Application manifest..."
kubectl apply -f argocd/application.yaml

echo "================================================================="
echo " Bootstrap Complete! Platform Services are Online"
echo "================================================================="
echo "To access Grafana Dashboard (Port 3000):"
echo "  kubectl port-forward svc/prometheus-stack-grafana 3000:80 -n monitoring"
echo "  Credentials: admin / admin"
echo ""
echo "To access Alertmanager UI (Port 9093):"
echo "  kubectl port-forward svc/prometheus-stack-kube-prom-alertmanager 9093:9093 -n monitoring"
echo ""
echo "To access Argo CD Web UI (Port 8080):"
echo "  kubectl port-forward svc/argocd-server 8080:443 -n argocd"
echo "  Credentials: admin / (run: kubectl get secret argocd-initial-admin-secret -n argocd -o jsonpath='{.data.password}' | base64 -d)"
echo "================================================================="
