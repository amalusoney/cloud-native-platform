variable "project_name" {
  description = "Project name prefix"
  type        = string
}

variable "environment" {
  description = "Environment name (e.g. dev)"
  type        = string
  default     = "dev"
}

variable "vpc_id" {
  description = "VPC ID where security groups will be created"
  type        = string
}

variable "my_ip" {
  description = "Your IP address for SSH and Jenkins access (CIDR notation)"
  type        = string
  default     = "0.0.0.0/0" # In production, restrict to your specific IP: "X.X.X.X/32"
}