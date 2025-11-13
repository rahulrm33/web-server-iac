locals {
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
    prod = {
      state_bucket   = "web-loadbalancer-terraform-state-prod"
      locks_table    = "web-loadbalancer-terraform-locks-prod"
      state_region   = "us-east-1"
      state_key_dir  = "us-east-1"
    }
    prod-eu = {
      state_bucket   = "web-loadbalancer-terraform-state-prod"
      locks_table    = "web-loadbalancer-terraform-locks-prod"
      state_region   = "us-east-1"
      state_key_dir  = "eu-west-2"
    }
  }

  common_tags = {
    Project     = "web-loadbalancer"
    ManagedBy   = "Terragrunt"
    Terraform   = "true"
  }

  terraform_version = ">= 1.5.0"
  aws_provider_version = "~> 5.0"
}

