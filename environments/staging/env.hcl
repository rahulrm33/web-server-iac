locals {
  environment  = "staging"
  project_name = "web-loadbalancer"
  aws_region   = "us-west-2"
  
  vpc_cidr             = "10.1.0.0/16"
  public_subnet_cidrs  = ["10.1.1.0/24", "10.1.2.0/24"]
  private_subnet_cidrs = ["10.1.10.0/24", "10.1.11.0/24"]
  availability_zones   = ["us-west-2a", "us-west-2b"]
  
  instance_count = 2
  instance_type  = "t3.small"
  
  enable_deletion_protection = false
  
  ssh_allowed_cidrs = ["0.0.0.0/0"]
}

