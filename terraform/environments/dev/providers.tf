terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Configures Terraform to use your remote S3 bucket and DynamoDB locking table!
  backend "s3" {
    bucket         = "cloud-native-platform-tf-state-786xnd"
    key            = "dev/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "cloud-native-platform-tf-locks"
    encrypt        = true
  }
}

provider "aws" {
  region = var.aws_region
}