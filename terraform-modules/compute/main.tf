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

locals {
  user_data_template = <<-EOF
#!/bin/bash
set -x
exec > >(tee /var/log/user-data.log)
exec 2>&1

yum update -y
yum install -y nginx
systemctl start nginx
systemctl enable nginx
systemctl status nginx

TOKEN=$(curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600" 2>/dev/null)
INSTANCE_ID=$(curl -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/instance-id 2>/dev/null)
AVAILABILITY_ZONE=$(curl -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/placement/availability-zone 2>/dev/null)
PRIVATE_IP=$(curl -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/local-ipv4 2>/dev/null)
INSTANCE_TYPE=$(curl -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/instance-type 2>/dev/null)
HOSTNAME=$(hostname)

cat > /usr/share/nginx/html/index.html <<HTML
<!DOCTYPE html>
<html>
<head>
    <title>Hello World - Load Balanced Web Server</title>
    <style>
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            max-width: 900px;
            margin: 50px auto;
            padding: 20px;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
        }
        .container {
            background: rgba(255, 255, 255, 0.1);
            padding: 40px;
            border-radius: 15px;
            backdrop-filter: blur(10px);
            box-shadow: 0 8px 32px 0 rgba(31, 38, 135, 0.37);
        }
        h1 {
            font-size: 3em;
            margin-bottom: 10px;
            text-align: center;
        }
        .subtitle {
            text-align: center;
            font-size: 1.2em;
            margin-bottom: 30px;
            opacity: 0.9;
        }
        .info-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
            gap: 15px;
            margin: 20px 0;
        }
        .info {
            background: rgba(0, 0, 0, 0.3);
            padding: 15px;
            border-radius: 8px;
            border-left: 4px solid #ffd700;
        }
        .info-label {
            font-size: 0.9em;
            opacity: 0.8;
            margin-bottom: 5px;
        }
        .info-value {
            font-size: 1.3em;
            font-weight: bold;
            word-break: break-all;
        }
        .highlight {
            background: rgba(255, 215, 0, 0.2);
            padding: 20px;
            border-radius: 8px;
            margin: 20px 0;
            text-align: center;
            border: 2px solid #ffd700;
        }
        .status {
            display: inline-block;
            padding: 8px 16px;
            background: #10b981;
            border-radius: 20px;
            font-weight: bold;
            margin-top: 10px;
        }
        .footer {
            text-align: center;
            margin-top: 30px;
            opacity: 0.7;
            font-size: 0.9em;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>Hello World!</h1>
        <p class="subtitle">Load-Balanced Nginx Web Server</p>
        
        <div class="highlight">
            <h2 style="margin: 0;">Server: $HOSTNAME</h2>
            <div class="status">HEALTHY &amp; RESPONDING</div>
        </div>

        <div class="info-grid">
            <div class="info">
                <div class="info-label">Instance ID</div>
                <div class="info-value">$INSTANCE_ID</div>
            </div>
            
            <div class="info">
                <div class="info-label">Availability Zone</div>
                <div class="info-value">$AVAILABILITY_ZONE</div>
            </div>
            
            <div class="info">
                <div class="info-label">Private IP</div>
                <div class="info-value">$PRIVATE_IP</div>
            </div>
            
            <div class="info">
                <div class="info-label">Instance Type</div>
                <div class="info-value">$INSTANCE_TYPE</div>
            </div>
            
            <div class="info">
                <div class="info-label">Environment</div>
                <div class="info-value">${var.environment}</div>
            </div>
            
            <div class="info">
                <div class="info-label">Project</div>
                <div class="info-value">${var.project_name}</div>
            </div>
        </div>

        <div class="footer">
            <p>Refresh this page to see load balancing in action!</p>
            <p>Request served at: <strong>$(date)</strong></p>
        </div>
    </div>
</body>
</html>
HTML
  EOF
}

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
    volume_size           = 30
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

