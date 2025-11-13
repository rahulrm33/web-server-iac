# Key Pair Module - Creates EC2 Key Pair and stores in Secrets Manager

resource "tls_private_key" "ssh" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "main" {
  key_name   = "${var.project_name}-${var.environment}-key"
  public_key = tls_private_key.ssh.public_key_openssh

  tags = {
    Name        = "${var.project_name}-${var.environment}-key"
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_secretsmanager_secret" "private_key" {
  name                    = "${var.project_name}/${var.environment}/ssh-private-key"
  description             = "Private SSH key for ${var.project_name} ${var.environment} environment"
  recovery_window_in_days = 7

  tags = {
    Name        = "${var.project_name}-${var.environment}-private-key"
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_secretsmanager_secret_version" "private_key" {
  secret_id     = aws_secretsmanager_secret.private_key.id
  secret_string = tls_private_key.ssh.private_key_pem
}

