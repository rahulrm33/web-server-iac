output "instance_ids" {
  description = "IDs of EC2 instances"
  value       = aws_instance.web_servers[*].id
}

output "instance_private_ips" {
  description = "Private IP addresses of EC2 instances"
  value       = aws_instance.web_servers[*].private_ip
}

output "instance_public_ips" {
  description = "Public IP addresses of EC2 instances"
  value       = aws_instance.web_servers[*].public_ip
}

