# Main Infrastructure Configuration
# This file ties together all the modules

# Key Pair Module
module "key_pair" {
  source = "../terraform-modules/key-pair"

  project_name = var.project_name
  environment  = var.environment
}

# Networking Module
module "networking" {
  source = "../terraform-modules/networking"

  project_name         = var.project_name
  environment          = var.environment
  vpc_cidr             = var.vpc_cidr
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  availability_zones   = var.availability_zones
}

# Security Groups Module
module "security_groups" {
  source = "../terraform-modules/security-groups"

  project_name      = var.project_name
  environment       = var.environment
  vpc_id            = module.networking.vpc_id
  ssh_allowed_cidrs = var.ssh_allowed_cidrs

  depends_on = [module.networking]
}

# Compute Module
module "compute" {
  source = "../terraform-modules/compute"

  project_name      = var.project_name
  environment       = var.environment
  instance_count    = var.instance_count
  instance_type     = var.instance_type
  subnet_ids        = module.networking.private_subnet_ids  # Web servers in PRIVATE subnets
  security_group_id = module.security_groups.web_servers_security_group_id
  key_name          = module.key_pair.key_pair_name

  depends_on = [module.security_groups, module.key_pair]
}

# Load Balancer Module
module "load_balancer" {
  source = "../terraform-modules/load-balancer"

  project_name               = var.project_name
  environment                = var.environment
  vpc_id                     = module.networking.vpc_id
  subnet_ids                 = module.networking.public_subnet_ids
  alb_security_group_id      = module.security_groups.alb_security_group_id
  instance_ids               = module.compute.instance_ids
  enable_deletion_protection = var.enable_deletion_protection

  depends_on = [module.compute]
}

