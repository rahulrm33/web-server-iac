# Production Environment Configuration

locals {
  environment  = "prod"
  project_name = "web-loadbalancer"
  aws_region   = "us-west-2"
  
  # Network Configuration
  vpc_cidr             = "10.2.0.0/16"
  public_subnet_cidrs  = ["10.2.1.0/24", "10.2.2.0/24", "10.2.3.0/24"]
  availability_zones   = ["us-west-2a", "us-west-2b", "us-west-2c"]
  key_name = "web-loadbalancer-prod-key"
  # Compute Configuration
  instance_count = 3
  instance_type  = "t3.medium"
  
  # Load Balancer Configuration
  enable_deletion_protection = true
  
  # Security
  ssh_allowed_cidrs = ["0.0.0.0/0"] # Change to your IP for better security
}

