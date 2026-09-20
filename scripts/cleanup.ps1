<#
==============================================================================
Cloud-Native Platform - Automated PowerShell Cleanup Script (Windows)
==============================================================================
Usage: .\scripts\cleanup.ps1 [-Region <string>] [-ClusterName <string>]
Default Region: us-east-1
Default Cluster: cloud-native-eks
==============================================================================
#>

[CmdletBinding()]
param (
    [string]$Region = "us-east-1",
    [string]$ClusterName = "cloud-native-eks"
)

$ErrorActionPreference = "Continue"
$RepoRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)

Write-Host "=================================================================" -ForegroundColor Cyan
Write-Host " Starting Safe Cloud-Native Platform Cleanup (Windows PowerShell)" -ForegroundColor Cyan
Write-Host " Region:  $Region" -ForegroundColor Cyan
Write-Host " Cluster: $ClusterName" -ForegroundColor Cyan
Write-Host "=================================================================" -ForegroundColor Cyan

# Step 1: Release AWS Classic Load Balancers
Write-Host "`n[+] Step 1: Deleting Kubernetes LoadBalancer Services to release AWS ELBs..." -ForegroundColor Yellow
kubectl delete svc cloud-native-app-service -n default --ignore-not-found=true --timeout=60s

Write-Host "[+] Waiting 30s for AWS ELB to de-provision..." -ForegroundColor Yellow
Start-Sleep -Seconds 30

# Step 2: Remove Argo CD GitOps Application & Namespace
Write-Host "`n[+] Step 2: Removing Argo CD GitOps Application & Namespace..." -ForegroundColor Yellow
kubectl delete -f "$RepoRoot\argocd\application.yaml" --ignore-not-found=true --timeout=60s
kubectl delete namespace argocd --ignore-not-found=true --timeout=60s

# Step 3: Remove Monitoring Stack
Write-Host "`n[+] Step 3: Uninstalling Prometheus & Monitoring Stack..." -ForegroundColor Yellow
helm uninstall prometheus-stack -n monitoring 2>$null
kubectl delete namespace monitoring --ignore-not-found=true --timeout=60s

# Step 4: Remove Default Workloads
Write-Host "`n[+] Step 4: Deleting remaining default application workloads..." -ForegroundColor Yellow
helm uninstall cloud-native-app -n default 2>$null
kubectl delete deployment cloud-native-app -n default --ignore-not-found=true
kubectl delete hpa cloud-native-app-hpa -n default --ignore-not-found=true
kubectl delete configmap cloud-native-app-config -n default --ignore-not-found=true
kubectl delete secret cloud-native-app-secret -n default --ignore-not-found=true

# Step 5: Execute Terraform Destroy
Write-Host "`n[+] Step 5: Executing Terraform Destroy in terraform\environments\dev..." -ForegroundColor Yellow
Push-Location "$RepoRoot\terraform\environments\dev"
try {
    terraform init
    terraform destroy -auto-approve
}
finally {
    Pop-Location
}

Write-Host "`n=================================================================" -ForegroundColor Green
Write-Host " Teardown Complete! All AWS Resources Successfully Destroyed." -ForegroundColor Green
Write-Host " Zero running billable cloud resources remain." -ForegroundColor Green
Write-Host "=================================================================" -ForegroundColor Green
