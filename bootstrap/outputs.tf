output "s3_bucket_name" {
  description = "Name of the S3 bucket for Terraform state"
  value       = aws_s3_bucket.terraform_state.id
}

output "s3_bucket_arn" {
  description = "ARN of the S3 bucket"
  value       = aws_s3_bucket.terraform_state.arn
}

output "s3_bucket_region" {
  description = "Region of the S3 bucket"
  value       = aws_s3_bucket.terraform_state.region
}

output "dynamodb_table_name" {
  description = "Name of the DynamoDB table for state locking"
  value       = aws_dynamodb_table.terraform_locks.id
}

output "dynamodb_table_arn" {
  description = "ARN of the DynamoDB table"
  value       = aws_dynamodb_table.terraform_locks.arn
}

output "backend_config" {
  description = "Backend configuration for use in other Terraform projects"
  value = {
    bucket         = aws_s3_bucket.terraform_state.id
    key            = "terraform.tfstate"
    region         = var.aws_region
    dynamodb_table = aws_dynamodb_table.terraform_locks.id
    encrypt        = true
  }
}

output "terragrunt_config" {
  description = "Configuration snippet for Terragrunt"
  value = <<-EOT
    remote_state {
      backend = "s3"
      config = {
        encrypt        = true
        bucket         = "${aws_s3_bucket.terraform_state.id}"
        key            = "$${path_relative_to_include()}/terraform.tfstate"
        region         = "${var.aws_region}"
        dynamodb_table = "${aws_dynamodb_table.terraform_locks.id}"
      }
    }
  EOT
}

output "next_steps" {
  description = "Instructions for next steps"
  value = <<-EOT
    ✅ Bootstrap resources created successfully!
    
    Next steps:
    1. Your Terraform backend is ready
    2. S3 Bucket: ${aws_s3_bucket.terraform_state.id}
    3. DynamoDB Table: ${aws_dynamodb_table.terraform_locks.id}
    
    To use this backend in your infrastructure:
    - The backend is already configured in environments/terragrunt.hcl
    - Run: cd ../environments/dev && terragrunt init
    - Run: terragrunt apply
    
    To migrate this bootstrap state to remote backend (optional):
    - Update bootstrap/main.tf to use S3 backend
    - Run: terraform init -migrate-state
  EOT
}

