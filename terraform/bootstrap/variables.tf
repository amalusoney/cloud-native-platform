variable "aws_region" {
  description = "AWS region to provision resources in"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project name prefix for resources"
  type        = string
  default     = "cloud-native-platform"
}