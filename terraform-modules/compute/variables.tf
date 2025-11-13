variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "instance_count" {
  description = "Number of web server instances"
  type        = number
  default     = 2
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "subnet_ids" {
  description = "List of subnet IDs for instances"
  type        = list(string)
}

variable "security_group_id" {
  description = "Security group ID for web servers"
  type        = string
}

variable "key_name" {
  description = "SSH key pair name"
  type        = string
  default     = null
}

