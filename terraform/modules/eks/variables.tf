variable "project_name" {
  description = "Project name prefix"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
  default     = "cloud-native-eks"
}

variable "cluster_version" {
  description = "Kubernetes version to deploy"
  type        = string
  default     = "1.31"
}

variable "vpc_id" {
  description = "VPC ID where the cluster will be deployed"
  type        = string
}

variable "subnet_ids" {
  description = "All subnet IDs (public & private) for the control plane ENIs"
  type        = list(string)
}

variable "private_subnet_ids" {
  description = "Private Subnet IDs where worker nodes will run"
  type        = list(string)
}

variable "node_instance_types" {
  description = "EC2 instance types for worker nodes"
  type        = list(string)
  default     = ["t3.micro"]
}