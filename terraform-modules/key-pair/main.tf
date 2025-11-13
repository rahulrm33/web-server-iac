# Key Pair Module - Creates EC2 Key Pair and stores in Secrets Manager

# Generate SSH Key Pair
resource "tls_private_key" "ssh" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Create EC2 Key Pair with generated public key
resource "aws_key_pair" "main" {
  key_name   = "${var.project_name}-${var.environment}-key"
  public_key = tls_private_key.ssh.public_key_openssh

  tags = {
    Name        = "${var.project_name}-${var.environment}-key"
    Environment = var.environment
    Project     = var.project_name
  }
}

# Store private key in Secrets Manager
resource "aws_secretsmanager_secret" "private_key" {
  name                    = "${var.project_name}/${var.environment}/ssh-private-key"
  description             = "Private SSH key for ${var.project_name} ${var.environment} environment"
  recovery_window_in_days = 7  # Allow 7 days to recover before permanent deletion

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

