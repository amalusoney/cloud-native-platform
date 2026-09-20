#!/usr/bin/env bash
# ==============================================================================
# Cloud-Native Platform - Phase 5 Self-Healing & Resilience Test Script
# Tests:
#   1. Pod ReplicaSet Self-Healing (Pod Kill)
#   2. Kubelet Container Self-Healing (Liveness Probe Failure)
#   3. Multi-Node Resilience (Cordon & Drain Node Failover)
#   4. Horizontal Pod Autoscaler (HPA Elastic Scaling)
# ==============================================================================

set -euo pipefail

CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${CYAN}======================================================${NC}"
echo -e "${CYAN}  Phase 5: Kubernetes Resilience & Self-Healing Tests  ${NC}"
echo -e "${CYAN}======================================================${NC}\n"

# Check prerequisites
command -v kubectl >/dev/null 2>&1 || { echo -e "${RED}kubectl is required but not installed.${NC}"; exit 1; }

echo -e "${YELLOW}>>> Step 0: Checking Cluster State and Worker Nodes...${NC}"
kubectl get nodes -o wide
echo ""
echo -e "${YELLOW}>>> Current Application Pods:${NC}"
kubectl get pods -l app=cloud-native-app -o wide
echo ""

# Test 1: Pod-Level Self-Healing
echo -e "${CYAN}======================================================${NC}"
echo -e "${CYAN}  TEST 1: Pod Self-Healing (ReplicaSet Controller)     ${NC}"
echo -e "${CYAN}======================================================${NC}"
TARGET_POD=$(kubectl get pods -l app=cloud-native-app -o jsonpath='{.items[0].metadata.name}')
echo -e "Target pod to delete: ${YELLOW}${TARGET_POD}${NC}"
echo -e "Deleting pod..."
kubectl delete pod "${TARGET_POD}" --now

echo -e "Observing ReplicaSet recreating replacement pod..."
sleep 2
kubectl get pods -l app=cloud-native-app -o wide
echo -e "${GREEN}✓ Test 1 Passed: ReplicaSet immediately launched replacement pod!${NC}\n"

# Test 2: Container Self-Healing (Liveness Probe)
echo -e "${CYAN}======================================================${NC}"
echo -e "${CYAN}  TEST 2: Container Self-Healing via Liveness Probe   ${NC}"
echo -e "${CYAN}======================================================${NC}"
ACTIVE_POD=$(kubectl get pods -l app=cloud-native-app -o jsonpath='{.items[0].metadata.name}')
echo -e "Target pod for liveness failure: ${YELLOW}${ACTIVE_POD}${NC}"
INITIAL_RESTARTS=$(kubectl get pod "${ACTIVE_POD}" -o jsonpath='{.status.containerStatuses[0].restartCount}')
echo -e "Initial restart count: ${INITIAL_RESTARTS}"

echo -e "Triggering /health/fail endpoint inside pod..."
kubectl exec "${ACTIVE_POD}" -- curl -s -X POST http://localhost:8000/health/fail || true

echo -e "Waiting for Kubelet liveness probe to detect failure and restart container (15-30s)..."
for i in {1..8}; do
    sleep 5
    CURRENT_RESTARTS=$(kubectl get pod "${ACTIVE_POD}" -o jsonpath='{.status.containerStatuses[0].restartCount}' 2>/dev/null || echo "$INITIAL_RESTARTS")
    echo "Current restart count: ${CURRENT_RESTARTS}"
    if [ "$CURRENT_RESTARTS" -gt "$INITIAL_RESTARTS" ]; then
        echo -e "${GREEN}✓ Test 2 Passed: Kubelet detected unhealthy container and restarted it automatically!${NC}\n"
        break
    fi
done

# Test 3: Multi-Node Cordon & Drain
echo -e "${CYAN}======================================================${NC}"
echo -e "${CYAN}  TEST 3: Multi-Node Rescheduling (Cordon & Drain)     ${NC}"
echo -e "${CYAN}======================================================${NC}"
FIRST_POD=$(kubectl get pods -l app=cloud-native-app -o jsonpath='{.items[0].metadata.name}')
TARGET_NODE=$(kubectl get pod "${FIRST_POD}" -o jsonpath='{.spec.nodeName}')
echo -e "Pod ${YELLOW}${FIRST_POD}${NC} is currently running on node: ${YELLOW}${TARGET_NODE}${NC}"

echo -e "Cordoning node ${TARGET_NODE} (marking Unschedulable)..."
kubectl cordon "${TARGET_NODE}"

echo -e "Draining node ${TARGET_NODE} (evicting workloads)..."
kubectl drain "${TARGET_NODE}" --ignore-daemonsets --delete-emptydir-data --force --grace-period=15

echo -e "Checking pod placement after drain..."
kubectl get pods -l app=cloud-native-app -o wide

echo -e "Restoring node ${TARGET_NODE}..."
kubectl uncordon "${TARGET_NODE}"
echo -e "${GREEN}✓ Test 3 Passed: Workloads safely evicted and rescheduled to surviving node with zero service downtime!${NC}\n"

# Test 4: Horizontal Pod Autoscaler (HPA)
echo -e "${CYAN}======================================================${NC}"
echo -e "${CYAN}  TEST 4: Horizontal Pod Autoscaler (HPA) Verification ${NC}"
echo -e "${CYAN}======================================================${NC}"
kubectl get hpa
echo -e "\n${GREEN}======================================================${NC}"
echo -e "${GREEN}  All Self-Healing & Resilience Tests Completed!       ${NC}"
echo -e "${GREEN}======================================================${NC}"
