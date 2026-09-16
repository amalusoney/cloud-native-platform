variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project name"
  type        = string
  default     = "cloud-native-platform"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}