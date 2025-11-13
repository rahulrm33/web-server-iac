# Root Terragrunt Configuration
# This file contains common configuration shared across all environments
# All shared config is defined ONCE here and inherited by children

# Include region and common configuration
# Environment-specific values come from child env.hcl files
locals {
  region_vars  = read_terragrunt_config(find_in_parent_folders("region.hcl"))
  common_vars  = read_terragrunt_config(find_in_parent_folders("common.hcl"))

  # Determine environment from the current directory path
  # This works because we have dev/, staging/, prod/ folders
  # get_terragrunt_dir() returns the directory of terragrunt.hcl (dev, staging, or prod)
  current_env  = basename(get_terragrunt_dir())
  
  # Extract values for easier reference
  # Each environment has its own region config
  regions      = local.region_vars.locals.regions
  region_config = local.regions[local.current_env]
  aws_region   = local.region_config.aws_region
  
  backends     = local.common_vars.locals.backends
  backend_config = local.backends[local.current_env]
  common_tags  = local.common_vars.locals.common_tags
}

# Generate AWS provider configuration
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

# Configure remote state for all environments
# Defined ONCE here, inherited by all children (TRUE DRY!)
# Prod environments share bucket but use different directories per region
remote_state {
  backend = "s3"
  
  config = {
    encrypt        = true
    bucket         = local.backend_config.state_bucket
    # Use state_key_dir if defined (for prod regions), otherwise use environment name
    key            = "${try(local.backend_config.state_key_dir, local.current_env)}/terraform.tfstate"
    region         = local.backend_config.state_region
    dynamodb_table = local.backend_config.locks_table
  }
  
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
}

# Configure retry settings
retryable_errors = [
  "(?s).*Error creating.*",
  "(?s).*Error modifying.*",
  "(?s).*Error deleting.*",
  "(?s).*Please try again.*",
]

retry_max_attempts = 3
retry_sleep_interval_sec = 5

