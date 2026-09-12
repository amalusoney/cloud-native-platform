# End-to-End Self-Healing Cloud-Native Platform with GitOps CI/CD

A production-style Kubernetes platform on AWS, provisioned entirely via IaC, featuring an automated CI/CD pipeline, configuration management, observability, and self-healing workload recovery.

## Repository Structure
- `terraform/`: Modular AWS IaC (VPC, EKS, EC2, RDS/MySQL, IAM)
- `ansible/`: Host configuration and hardening playbooks
- `app/`: Multi-service application source code & Dockerfiles
- `k8s/`: Kubernetes manifests, Helm charts, and GitOps configurations
- `jenkins/`: Pipeline-as-code (Jenkinsfiles) and agent automation
- `monitoring/`: Prometheus rules, Alertmanager configs, and Grafana dashboards
- `scripts/`: Operational glue, bootstrap, and teardown scripts
- `docs/`: Architecture diagrams, runbooks, and interview prep notes
