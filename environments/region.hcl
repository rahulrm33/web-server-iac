# Region Configuration
# Defines region settings for each environment

locals {
  # Environment-specific regions
  regions = {
    dev = {
      aws_region          = "us-west-2"
      availability_zones  = ["us-west-2a", "us-west-2b"]
    }
    staging = {
      aws_region          = "us-west-2"
      availability_zones  = ["us-west-2a", "us-west-2b"]
    }
    prod = {
      aws_region          = "us-east-1"  # Primary prod (US)
      availability_zones  = ["us-east-1a", "us-east-1b"]
    }
    prod-eu = {
      aws_region          = "eu-west-2"  # Secondary prod (EU - London)
      availability_zones  = ["eu-west-2a", "eu-west-2b"]
    }
  }
}

