# Dev Environment Root Terragrunt Configuration

# Include all shared configurations
include "root" {
  path = find_in_parent_folders("terragrunt.hcl")
}

include "region" {
  path = find_in_parent_folders("region.hcl")
}

# Load environment-specific variables from env.hcl (minimal - only local vars!)
locals {
  env_vars = read_terragrunt_config("${get_terragrunt_dir()}/env.hcl")
}

terraform {
  source = "../..//infrastructure"
}

inputs = {
  # Pass all environment variables as inputs
  environment                = local.env_vars.locals.environment
  project_name               = local.env_vars.locals.project_name
  aws_region                 = local.env_vars.locals.aws_region
  vpc_cidr                   = local.env_vars.locals.vpc_cidr
  public_subnet_cidrs        = local.env_vars.locals.public_subnet_cidrs
  availability_zones         = local.env_vars.locals.availability_zones
  instance_count             = local.env_vars.locals.instance_count
  instance_type              = local.env_vars.locals.instance_type
  enable_deletion_protection = local.env_vars.locals.enable_deletion_protection
  ssh_allowed_cidrs          = local.env_vars.locals.ssh_allowed_cidrs
}

