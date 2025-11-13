# Development Environment Configuration

locals {
  environment  = "dev"
  project_name = "web-loadbalancer"
  aws_region   = "us-west-2"
  
  # Network Configuration
  vpc_cidr             = "10.0.0.0/16"
  public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
  availability_zones   = ["us-west-2a", "us-west-2b"]
  
  # Compute Configuration
  instance_count = 2
  instance_type  = "t3.micro"
  
  # Load Balancer Configuration
  enable_deletion_protection = false
  
  # Security
  ssh_allowed_cidrs = ["0.0.0.0/0"] # Change to your IP for better security
}

