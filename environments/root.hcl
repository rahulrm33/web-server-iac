locals {
  region_vars  = read_terragrunt_config(find_in_parent_folders("region.hcl"))
  common_vars  = read_terragrunt_config(find_in_parent_folders("common.hcl"))
  current_env  = basename(get_terragrunt_dir())
  
  regions      = local.region_vars.locals.regions
  region_config = local.regions[local.current_env]
  aws_region   = local.region_config.aws_region
  
  backends     = local.common_vars.locals.backends
  backend_config = local.backends[local.current_env]
  common_tags  = local.common_vars.locals.common_tags
}

generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
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
  
  default_tags {
    tags = {
      Environment = var.environment
      Project     = var.project_name
      ManagedBy   = "Terragrunt"
      Terraform   = "true"
    }
  }
}
EOF
}

remote_state {
  backend = "s3"
  
  config = {
    encrypt        = true
    bucket         = local.backend_config.state_bucket
    key            = "${try(local.backend_config.state_key_dir, local.current_env)}/terraform.tfstate"
    region         = local.backend_config.state_region
    dynamodb_table = local.backend_config.locks_table
  }
  
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
}

retryable_errors = [
  "(?s).*Error creating.*",
  "(?s).*Error modifying.*",
  "(?s).*Error deleting.*",
  "(?s).*Please try again.*",
]

retry_max_attempts = 3
retry_sleep_interval_sec = 5

