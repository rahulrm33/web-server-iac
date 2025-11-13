# Infrastructure Outputs

# Networking Outputs
output "vpc_id" {
  description = "VPC ID"
  value       = module.networking.vpc_id
}

output "public_subnet_ids" {
  description = "Public subnet IDs (ALB and NAT Gateways)"
  value       = module.networking.public_subnet_ids
}

output "private_subnet_ids" {
  description = "Private subnet IDs (Web Servers)"
  value       = module.networking.private_subnet_ids
}

output "nat_gateway_ips" {
  description = "NAT Gateway Elastic IP addresses"
  value       = module.networking.nat_eip_addresses
}

# Compute Outputs
output "web_server_instance_ids" {
  description = "Web server instance IDs"
  value       = module.compute.instance_ids
}

output "web_server_private_ips" {
  description = "Web server private IPs"
  value       = module.compute.instance_private_ips
}

output "web_server_public_ips" {
  description = "Web server public IPs"
  value       = module.compute.instance_public_ips
}

# Load Balancer Outputs
output "load_balancer_dns" {
  description = "Load Balancer DNS name - Use this URL to access your application"
  value       = "http://${module.load_balancer.alb_dns_name}"
}

output "load_balancer_arn" {
  description = "Load Balancer ARN"
  value       = module.load_balancer.alb_arn
}

output "target_group_arn" {
  description = "Target Group ARN"
  value       = module.load_balancer.target_group_arn
}

# Summary Output
output "deployment_summary" {
  description = "Deployment summary"
  value = {
    environment    = var.environment
    project_name   = var.project_name
    region         = var.aws_region
    instance_count = var.instance_count
    access_url     = "http://${module.load_balancer.alb_dns_name}"
  }
}

