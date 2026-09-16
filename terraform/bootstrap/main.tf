terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# Generate a random suffix so your S3 bucket name is globally unique
resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
}

# 1. S3 Bucket for Storing Terraform State
resource "aws_s3_bucket" "terraform_state" {
  bucket        = "${var.project_name}-tf-state-${random_string.suffix.result}"
  force_destroy = true # Allows clean deletion during testing

  tags = {
    Name        = "Terraform Remote State Bucket"
    Environment = "Management"
    Project     = var.project_name
  }
}

# Enable versioning so you can restore past state if corrupted
resource "aws_s3_bucket_versioning" "state_versioning" {
  bucket = aws_s3_bucket.terraform_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Enable server-side encryption (SSE-S3) for security
resource "aws_s3_bucket_server_side_encryption_configuration" "state_encryption" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Block all public access to the state bucket (Crucial Security Best Practice)
resource "aws_s3_bucket_public_access_block" "state_public_block" {
  bucket = aws_s3_bucket.terraform_state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# 2. DynamoDB Table for State Locking
resource "aws_dynamodb_table" "terraform_locks" {
  name         = "${var.project_name}-tf-locks"
  billing_mode = "PAY_PER_REQUEST" # Free-tier friendly; no idle hourly cost
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Name        = "Terraform State Lock Table"
    Environment = "Management"
    Project     = var.project_name
  }
}