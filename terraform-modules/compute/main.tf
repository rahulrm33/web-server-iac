# Compute Module - EC2 Instances with Nginx

# Data source to get latest Amazon Linux 2023 AMI
data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# User data script to install and configure nginx
locals {
  user_data_template = <<-EOF
#!/bin/bash
set -x
exec > >(tee /var/log/user-data.log)
exec 2>&1

echo "=== Starting user data script at $(date) ==="

# Update system
echo "Updating system..."
yum update -y

# Install nginx
echo "Installing nginx..."
yum install -y nginx

# Start and enable nginx
echo "Starting nginx..."
systemctl start nginx
systemctl enable nginx

echo "Checking nginx status..."
systemctl status nginx

# Create simple test page
cat > /usr/share/nginx/html/index.html <<'HTML'
<!DOCTYPE html>
<html>
<head>
    <title>Hello World - Load Balanced Web Server</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            max-width: 800px;
            margin: 50px auto;
            padding: 20px;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
        }
        .container {
            background: rgba(255, 255, 255, 0.1);
            padding: 30px;
            border-radius: 10px;
            backdrop-filter: blur(10px);
        }
        h1 {
            font-size: 3em;
            margin-bottom: 20px;
        }
        .info {
            background: rgba(0, 0, 0, 0.2);
            padding: 15px;
            border-radius: 5px;
            margin: 10px 0;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>🎉 Hello World! 🎉</h1>
        <p><strong>Load-balanced Nginx Web Server</strong></p>
        <div class="info">
            <p><strong>Environment:</strong> ${var.environment}</p>
            <p><strong>Project:</strong> ${var.project_name}</p>
        </div>
        <p>✅ This server is healthy and responding to requests!</p>
    </div>
</body>
</html>
HTML

echo "=== User data script completed successfully at $(date) ==="
  EOF
}

# EC2 Instances
resource "aws_instance" "web_servers" {
  count                  = var.instance_count
  ami                    = data.aws_ami.amazon_linux_2023.id
  instance_type          = var.instance_type
  subnet_id              = var.subnet_ids[count.index % length(var.subnet_ids)]
  vpc_security_group_ids = [var.security_group_id]
  key_name               = var.key_name

  user_data = local.user_data_template

  root_block_device {
    volume_type           = "gp3"
    volume_size           = 30  # Increased from 8GB to 30GB (AMI snapshot requires minimum 30GB)
    delete_on_termination = true
    encrypted             = true
  }

  metadata_options {
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
    http_endpoint               = "enabled"
  }

  tags = {
    Name        = "${var.project_name}-web-server-${count.index + 1}-${var.environment}"
    Environment = var.environment
    Project     = var.project_name
    Role        = "web-server"
  }

  lifecycle {
    create_before_destroy = true
  }
}

