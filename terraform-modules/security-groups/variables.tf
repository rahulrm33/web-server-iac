variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where security groups will be created"
  type        = string
}

variable "ssh_allowed_cidrs" {
  description = "CIDR blocks allowed to SSH into web servers"
  type        = list(string)
  default     = ["0.0.0.0/0"] # Change this to your IP for better security
}

