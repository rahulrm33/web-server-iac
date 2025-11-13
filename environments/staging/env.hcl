# Staging Environment Configuration

locals {
  environment  = "staging"
  project_name = "web-loadbalancer"
  aws_region   = "us-west-2"
  
  # Network Configuration
  vpc_cidr             = "10.1.0.0/16"
  public_subnet_cidrs  = ["10.1.1.0/24", "10.1.2.0/24"]       # For ALB and NAT Gateways
  private_subnet_cidrs = ["10.1.10.0/24", "10.1.11.0/24"]     # For web servers
  availability_zones   = ["us-west-2a", "us-west-2b"]
  
  # Compute Configuration
  instance_count = 2
  instance_type  = "t3.small"
  
  # Load Balancer Configuration
  enable_deletion_protection = false
  
  # Security
  ssh_allowed_cidrs = ["0.0.0.0/0"] # Change to your IP for better security
}

