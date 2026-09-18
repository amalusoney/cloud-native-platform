variable "project_name" {
  description = "Project name prefix"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "subnet_id" {
  description = "Public Subnet ID where Jenkins will be launched"
  type        = string
}

variable "security_group_id" {
  description = "Security group ID for Jenkins"
  type        = string
}

variable "key_name" {
  description = "Name of the existing AWS Key Pair for SSH"
  type        = string
  default     = "devops-key"
}

variable "instance_type" {
  description = "EC2 instance size for Jenkins (t3.micro for free-tier testing; t3.medium recommended for production builds)"
  type        = string
  default     = "t3.micro"
}