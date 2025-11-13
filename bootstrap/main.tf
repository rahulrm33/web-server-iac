# Bootstrap Module - Creates S3 Bucket and DynamoDB Table for Terraform State
# This module uses LOCAL state initially, then you migrate to remote state

terraform {
  required_version = ">= 1.5.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  
  # IMPORTANT: Uses local backend initially
  # After creation, migrate to remote backend
  backend "local" {
    path = "terraform.tfstate"
  }
}

provider "aws" {
  region = var.aws_region
  
  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "Terraform"
      Purpose     = "Terraform State Management"
    }
  }
}

# S3 Bucket for Terraform State
resource "aws_s3_bucket" "terraform_state" {
  bucket = "${var.project_name}-terraform-state-${var.environment}"

  # Prevent accidental deletion
  lifecycle {
    prevent_destroy = false # Set to true in production
  }

  tags = {
    Name        = "${var.project_name}-terraform-state-${var.environment}"
    Description = "Terraform state storage"
  }
}

# Enable versioning for state file history
resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Enable encryption at rest
resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Block all public access
resource "aws_s3_bucket_public_access_block" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Optional: Enable bucket logging (recommended for production)
# Uncomment if you have a separate logging bucket
# resource "aws_s3_bucket_logging" "terraform_state" {
#   bucket = aws_s3_bucket.terraform_state.id
#   target_bucket = var.logging_bucket
#   target_prefix = "terraform-state-logs/"
# }

# DynamoDB Table for State Locking
resource "aws_dynamodb_table" "terraform_locks" {
  name         = "${var.project_name}-terraform-locks-${var.environment}"
  billing_mode = "PAY_PER_REQUEST" # On-demand pricing, cost-effective for low usage
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  # Enable point-in-time recovery (recommended for production)
  point_in_time_recovery {
    enabled = var.enable_point_in_time_recovery
  }

  # Enable encryption at rest
  server_side_encryption {
    enabled = true
  }

  tags = {
    Name        = "${var.project_name}-terraform-locks-${var.environment}"
    Description = "Terraform state locking"
  }

  lifecycle {
    prevent_destroy = false # Set to true in production
  }
}

# Optional: CloudWatch alarms for monitoring (recommended)
resource "aws_cloudwatch_metric_alarm" "dynamodb_throttle" {
  count = var.enable_monitoring ? 1 : 0

  alarm_name          = "${var.project_name}-terraform-locks-throttle-${var.environment}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "UserErrors"
  namespace           = "AWS/DynamoDB"
  period              = "300"
  statistic           = "Sum"
  threshold           = "5"
  alarm_description   = "Alert when DynamoDB is being throttled"

  dimensions = {
    TableName = aws_dynamodb_table.terraform_locks.name
  }
}

