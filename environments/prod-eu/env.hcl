locals {
  environment  = "prod-eu"
  project_name = "web-loadbalancer"
  aws_region   = "eu-west-2"
  
  vpc_cidr             = "10.3.0.0/16"
  public_subnet_cidrs  = ["10.3.1.0/24", "10.3.2.0/24"]
  private_subnet_cidrs = ["10.3.10.0/24", "10.3.11.0/24"]
  availability_zones   = ["eu-west-2a", "eu-west-2b"]
  
  instance_count = 2
  instance_type  = "t3.medium"
  
  enable_deletion_protection = true
  
  ssh_allowed_cidrs = ["0.0.0.0/0"]
}

