output "alb_security_group_id" {
  description = "ID of the ALB security group"
  value       = aws_security_group.alb.id
}

output "web_servers_security_group_id" {
  description = "ID of the web servers security group"
  value       = aws_security_group.web_servers.id
}

