# Production EU Environment Configuration

locals {
  environment  = "prod-eu"
  project_name = "web-loadbalancer"
  aws_region   = "eu-west-2"
  
  # Network Configuration
  vpc_cidr             = "10.3.0.0/16"
  public_subnet_cidrs  = ["10.3.1.0/24", "10.3.2.0/24"]
  availability_zones   = ["eu-west-2a", "eu-west-2b"]
  
  # Compute Configuration
  instance_count = 2  # Fewer instances for EU
  instance_type  = "t3.medium"
  
  # Load Balancer Configuration
  enable_deletion_protection = true
  
  # Security
  ssh_allowed_cidrs = ["0.0.0.0/0"] # Change to your IP for better security
}

