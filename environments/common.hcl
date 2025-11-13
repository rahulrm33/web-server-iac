# Common Configuration
# Shared configuration across all environments

locals {
  # Environment-specific backend configuration
  backends = {
    dev = {
      state_bucket   = "web-loadbalancer-terraform-state-dev"
      locks_table    = "web-loadbalancer-terraform-locks-dev"
      state_region   = "us-west-2"
    }
    staging = {
      state_bucket   = "web-loadbalancer-terraform-state-staging"
      locks_table    = "web-loadbalancer-terraform-locks-staging"
      state_region   = "us-west-2"
    }
    # Prod environments share the SAME bucket and DynamoDB table
    # but use different directories (us-east-1/, eu-west-2/, etc.)
    prod = {
      state_bucket   = "web-loadbalancer-terraform-state-prod"
      locks_table    = "web-loadbalancer-terraform-locks-prod"
      state_region   = "us-east-1"
      state_key_dir  = "us-east-1"  # Directory in S3 for this region
    }
    prod-eu = {
      state_bucket   = "web-loadbalancer-terraform-state-prod"  # SAME bucket!
      locks_table    = "web-loadbalancer-terraform-locks-prod"   # SAME table!
      state_region   = "us-east-1"  # Bucket region (NOT infrastructure region!)
      state_key_dir  = "eu-west-2"  # Different directory within bucket
    }
  }

  # Common tags applied to all resources
  common_tags = {
    Project     = "web-loadbalancer"
    ManagedBy   = "Terragrunt"
    Terraform   = "true"
  }

  # Terraform and provider requirements
  terraform_version = ">= 1.5.0"
  aws_provider_version = "~> 5.0"
}

