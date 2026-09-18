variable "repository_name" {
  description = "The name of the ECR repository"
  type        = string
  default     = "cloud-native-app"
}

variable "image_tag_mutability" {
  description = "The tag mutability setting for the repository (MUTABLE or IMMUTABLE)"
  type        = string
  default     = "MUTABLE"
}

variable "environment" {
  description = "Deployment environment name"
  type        = string
  default     = "dev"
}
