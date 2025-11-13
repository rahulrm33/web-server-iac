# Key Pair Module Outputs

output "key_pair_name" {
  description = "Name of the created EC2 key pair"
  value       = aws_key_pair.main.key_name
}

output "secret_arn" {
  description = "ARN of the Secrets Manager secret containing the private key"
  value       = aws_secretsmanager_secret.private_key.arn
}

output "secret_name" {
  description = "Name of the Secrets Manager secret"
  value       = aws_secretsmanager_secret.private_key.name
}

