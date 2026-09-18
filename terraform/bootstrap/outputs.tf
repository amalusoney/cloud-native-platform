output "s3_bucket_name" {
  description = "Name of the S3 bucket used for remote state"
  value       = aws_s3_bucket.terraform_state.id
}

output "dynamodb_table_name" {
  description = "Name of the DynamoDB table used for state locking"
  value       = aws_dynamodb_table.terraform_locks.name
}

output "aws_region" {
  description = "AWS Region configured"
  value       = var.aws_region
}