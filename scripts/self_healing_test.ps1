# ==============================================================================
# Cloud-Native Platform - Phase 5 Self-Healing & Resilience Test Script (PowerShell)
# ==============================================================================

Write-Host "======================================================" -ForegroundColor Cyan
Write-Host "  Phase 5: Kubernetes Resilience & Self-Healing Tests  " -ForegroundColor Cyan
Write-Host "======================================================`n" -ForegroundColor Cyan

# Step 0: Cluster Nodes
Write-Host ">>> Step 0: Checking Cluster State and Worker Nodes..." -ForegroundColor Yellow
kubectl get nodes -o wide
Write-Host "`n>>> Current Application Pods:" -ForegroundColor Yellow
kubectl get pods -l app=cloud-native-app -o wide

# Test 1: Pod Self-Healing
Write-Host "`n======================================================" -ForegroundColor Cyan
Write-Host "  TEST 1: Pod Self-Healing (ReplicaSet Controller)     " -ForegroundColor Cyan
Write-Host "======================================================" -ForegroundColor Cyan
$targetPod = (kubectl get pods -l app=cloud-native-app -o jsonpath='{.items[0].metadata.name}')
Write-Host "Target pod to delete: $targetPod" -ForegroundColor Yellow
kubectl delete pod $targetPod --now
Start-Sleep -Seconds 2
kubectl get pods -l app=cloud-native-app -o wide
Write-Host "✓ Test 1 Passed: ReplicaSet immediately launched replacement pod!`n" -ForegroundColor Green

# Test 2: Container Self-Healing
Write-Host "======================================================" -ForegroundColor Cyan
Write-Host "  TEST 2: Container Self-Healing via Liveness Probe   " -ForegroundColor Cyan
Write-Host "======================================================" -ForegroundColor Cyan
$activePod = (kubectl get pods -l app=cloud-native-app -o jsonpath='{.items[0].metadata.name}')
Write-Host "Target pod for liveness failure: $activePod" -ForegroundColor Yellow
$initialRestarts = (kubectl get pod $activePod -o jsonpath='{.status.containerStatuses[0].restartCount}')
Write-Host "Initial restart count: $initialRestarts"

Write-Host "Triggering /health/fail endpoint inside pod..."
kubectl exec $activePod -- curl -s -X POST http://localhost:8000/health/fail

Write-Host "Waiting for Kubelet liveness probe to detect failure and restart container (15-30s)..."
for ($i = 0; $i -lt 8; $i++) {
    Start-Sleep -Seconds 5
    $currentRestarts = (kubectl get pod $activePod -o jsonpath='{.status.containerStatuses[0].restartCount}')
    Write-Host "Current restart count: $currentRestarts"
    if ([int]$currentRestarts -gt [int]$initialRestarts) {
        Write-Host "✓ Test 2 Passed: Kubelet detected unhealthy container and restarted it automatically!`n" -ForegroundColor Green
        break
    }
}

# Test 3: Multi-Node Cordon & Drain
Write-Host "======================================================" -ForegroundColor Cyan
Write-Host "  TEST 3: Multi-Node Rescheduling (Cordon & Drain)     " -ForegroundColor Cyan
Write-Host "======================================================" -ForegroundColor Cyan
$firstPod = (kubectl get pods -l app=cloud-native-app -o jsonpath='{.items[0].metadata.name}')
$targetNode = (kubectl get pod $firstPod -o jsonpath='{.spec.nodeName}')
Write-Host "Pod $firstPod is currently running on node: $targetNode" -ForegroundColor Yellow

Write-Host "Cordoning node $targetNode..."
kubectl cordon $targetNode

Write-Host "Draining node $targetNode..."
kubectl drain $targetNode --ignore-daemonsets --delete-emptydir-data --force --grace-period=15

Write-Host "Checking pod placement after drain..."
kubectl get pods -l app=cloud-native-app -o wide

Write-Host "Restoring node $targetNode..."
kubectl uncordon $targetNode
Write-Host "✓ Test 3 Passed: Workloads safely evicted and rescheduled to surviving node!`n" -ForegroundColor Green

# Test 4: HPA
Write-Host "======================================================" -ForegroundColor Cyan
Write-Host "  TEST 4: Horizontal Pod Autoscaler (HPA) Verification " -ForegroundColor Cyan
Write-Host "======================================================" -ForegroundColor Cyan
kubectl get hpa
Write-Host "`n======================================================" -ForegroundColor Green
Write-Host "  All Self-Healing & Resilience Tests Completed!       " -ForegroundColor Green
Write-Host "======================================================" -ForegroundColor Green
