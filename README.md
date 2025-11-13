# Load-Balanced Web Server Infrastructure

A production-ready, highly available load-balanced web server infrastructure on AWS with automatic failover, built using Terraform and Terragrunt.

## 🎯 What This Project Does

Deploys a complete production-grade infrastructure:
- ✅ **Application Load Balancer** distributing traffic across multiple web servers
- ✅ **Web Servers in Private Subnets** (no public IPs for security)
- ✅ **NAT Gateways** for secure outbound internet access
- ✅ **Multi-AZ High Availability** across availability zones
- ✅ **Automatic Failover** with health checks
- ✅ **Multiple Environments** (dev, staging, prod, prod-eu)

## 🏗️ Architecture

```
Internet
    ↓
Application Load Balancer (Public Subnets)
    ↓
Web Servers (Private Subnets) - No Public IPs
    ├─→ Web Server 1 (Nginx) - us-west-2a
    └─→ Web Server 2 (Nginx) - us-west-2b
    ↓
NAT Gateways (for outbound traffic)
    ↓
Internet (OS updates, etc.)
```

**Key Features:**
- Web servers display unique instance information (ID, AZ, IP)
- Private subnets for enhanced security
- Multi-AZ NAT Gateways for high availability
- Infrastructure as Code with Terraform modules
- Multi-environment management with Terragrunt

---

## 📋 Prerequisites

### Required Tools

| Tool | Minimum Version | Installation |
|------|----------------|--------------|
| **Terraform** | ≥ 1.5.0 | `brew install terraform` (macOS) |
| **Terragrunt** | ≥ 0.45.0 | `brew install terragrunt` (macOS) |
| **AWS CLI** | ≥ 2.0 | `brew install awscli` (macOS) |
| **jq** | ≥ 1.6 | `brew install jq` (macOS) |

### AWS Account Setup

1. **Create AWS Account**: https://aws.amazon.com/
2. **Configure AWS Credentials**:
   ```bash
   aws configure
   ```
   You'll need:
   - AWS Access Key ID
   - AWS Secret Access Key
   - Default region (e.g., `us-west-2`)
   - Output format: `json`

3. **Verify Configuration**:
   ```bash
   aws sts get-caller-identity
   ```

---

## 🚀 How to Recreate This Environment

### Step 1: Verify Requirements

Check that all required tools are installed:

```bash
# Verify Terraform
terraform --version  # Should be ≥ 1.5.0

# Verify Terragrunt
terragrunt --version  # Should be ≥ 0.45.0

# Verify AWS CLI
aws --version  # Should be ≥ 2.0

# Verify jq
jq --version  # Should be ≥ 1.6

# Verify AWS credentials
aws sts get-caller-identity
```

If any tools are missing, install them using the commands from the Prerequisites section above.

---

### Step 2: Create AWS Backend (S3 + DynamoDB)

**This is REQUIRED before running Terragrunt!**

The backend stores Terraform state and enables team collaboration. We'll use the Terraform bootstrap module to create it.

#### Navigate to Bootstrap Directory:

```bash
cd bootstrap
```

#### Create Configuration File:

Create a `terraform.tfvars` file with your settings:

```bash
cat > terraform.tfvars <<EOF
project_name = "web-loadbalancer"
environment  = "dev"
aws_region   = "us-west-2"
enable_point_in_time_recovery = false
enable_monitoring = false
EOF
```

**Adjust these values:**
- `environment`: `dev`, `staging`, or `prod`
- `aws_region`: Your preferred AWS region
- `project_name`: Keep as `web-loadbalancer` or customize

#### Initialize and Apply:

```bash
# Initialize Terraform
terraform init

# Preview what will be created
terraform plan

# Create the resources
terraform apply
```

Type `yes` when prompted.

**What this creates:**
- S3 bucket: `web-loadbalancer-terraform-state-dev` (with versioning & encryption)
- DynamoDB table: `web-loadbalancer-terraform-locks-dev` (for state locking)

#### Return to Project Root:

```bash
cd ..
```

**Run once per environment!** If deploying to multiple environments (dev, staging, prod), repeat this process 3 times with different `environment` values in `terraform.tfvars`.

---

### Step 3: Deploy Infrastructure

Navigate to your environment directory and use Terragrunt:

```bash
# Navigate to environment directory
cd environments/dev

# Initialize Terragrunt
terragrunt init

# Preview changes (optional but recommended)
terragrunt plan

# Apply changes
terragrunt apply
```

Type `yes` when prompted.

**Deployment time:** ~5-6 minutes

**Return to project root when done:**
```bash
cd ../..
```

**What gets created:**
- 1 VPC with public and private subnets
- 2 NAT Gateways (one per AZ)
- 1 Application Load Balancer
- 2 EC2 instances with Nginx (in private subnets)
- Security groups, route tables, etc.

---

### Step 4: Get Your Load Balancer URL

```bash
cd environments/dev
terragrunt output load_balancer_dns
```

**Example output:**
```
"http://web-loadbalancer-alb-dev-1234567890.us-west-2.elb.amazonaws.com"
```

---

### Step 5: Test Your Deployment

#### Browser Test:
```bash
# Get the URL
cd environments/dev
LB_URL=$(terragrunt output -raw load_balancer_dns)
echo "Open: $LB_URL"

# Open in browser
open $LB_URL  # macOS
```

#### Command Line Test:
```bash
# Single request
curl http://$LB_URL

# Multiple requests to see load balancing
for i in {1..5}; do
  echo "=== Request $i ==="
  curl -s http://$LB_URL | grep -E "(Server:|Instance ID)" | head -2
  sleep 1
done
```

**Expected Result:**
- Beautiful "Hello World" page
- Shows unique instance information (ID, AZ, Private IP)
- Different instances serve different requests (load balancing!)

---

### Step 6: Test Automatic Failover (Optional)

#### Manual Failover Test:

```bash
# 1. Get instance IDs
cd environments/dev
INSTANCE_IDS=($(terragrunt output -json web_server_instance_ids | jq -r '.[]'))

# 2. Make initial requests
LB_URL=$(terragrunt output -raw load_balancer_dns)
for i in {1..5}; do
  echo "Request $i:"
  curl -s $LB_URL | grep "Instance ID" -A1 | grep "info-value"
  sleep 1
done

---

### Step 6: Clean Up (When Done)

**Important:** To avoid AWS charges, destroy resources when not in use!

```bash
# Navigate to environment
cd environments/dev

# Destroy infrastructure
terragrunt destroy
```

**Confirm with:** `yes`

**What gets deleted:**
- All EC2 instances
- Load balancer
- NAT Gateways
- VPC and networking resources

**Does NOT delete:**
- S3 bucket (state files preserved)
- DynamoDB table (locks preserved)

---

## 🌍 Multi-Environment Deployment

Deploy to multiple environments (dev, staging, prod):

### Deploy to Dev:
```bash
# 1. Create backend
cd bootstrap
cat > terraform.tfvars <<EOF
project_name = "web-loadbalancer"
environment  = "dev"
aws_region   = "us-west-2"
EOF
terraform init && terraform apply
cd ..

# 2. Deploy infrastructure
cd environments/dev
terragrunt init && terragrunt apply
cd ../..
```

### Deploy to Staging:
```bash
# 1. Create backend
cd bootstrap
cat > terraform.tfvars <<EOF
project_name = "web-loadbalancer"
environment  = "staging"
aws_region   = "us-west-2"
EOF
terraform apply  # Already initialized
cd ..

# 2. Deploy infrastructure
cd environments/staging
terragrunt init && terragrunt apply
cd ../..
```

### Deploy to Production:
```bash
# 1. Create backend
cd bootstrap
cat > terraform.tfvars <<EOF
project_name = "web-loadbalancer"
environment  = "prod"
aws_region   = "us-west-2"
EOF
terraform apply  # Already initialized
cd ..

# 2. Deploy infrastructure
cd environments/prod
terragrunt init && terragrunt apply
cd ../..
```

### Environment Configurations:

| Environment | Instances | Instance Type | VPC CIDR | AZs | Cost/Month* |
|-------------|-----------|---------------|----------|-----|-------------|
| **dev** | 2 | t3.micro | 10.0.0.0/16 | 2 | ~$70 |
| **staging** | 2 | t3.small | 10.1.0.0/16 | 2 | ~$76 |
| **prod** | 3 | t3.medium | 10.2.0.0/16 | 3 | ~$114 |
| **prod-eu** | 2 | t3.medium | 10.3.0.0/16 | 2 | ~$90 |

*Estimated costs if running 24/7 (includes EC2, ALB, NAT Gateways)

---

## 📁 Project Structure

```
load-balancer-project/
├── terraform-modules/          # Reusable Terraform modules
│   ├── networking/            # VPC, subnets, NAT gateways
│   ├── security-groups/       # Security group rules
│   ├── compute/               # EC2 instances with Nginx
│   ├── load-balancer/         # ALB configuration
│   └── key-pair/              # SSH key generation
│
├── infrastructure/            # Main infrastructure composition
│   ├── main.tf               # Ties modules together
│   ├── variables.tf          # Input variables
│   └── outputs.tf            # Output values
│
├── environments/              # Environment-specific configs
│   ├── root.hcl              # Root Terragrunt config
│   ├── common.hcl            # Common variables (backends)
│   ├── region.hcl            # Region configurations
│   ├── dev/
│   │   ├── env.hcl          # Dev variables
│   │   └── terragrunt.hcl   # Dev Terragrunt config
│   ├── staging/
│   ├── prod/
│   └── prod-eu/
│
└── bootstrap/                 # Backend bootstrap (Terraform)
    ├── main.tf               # Creates S3 + DynamoDB
    ├── variables.tf          # Bootstrap variables
    └── outputs.tf            # Bootstrap outputs
```

---

## 🔧 Customization

### Change Instance Count:

Edit `environments/dev/env.hcl`:
```hcl
instance_count = 3  # Change from 2 to 3
```

### Change Instance Type:

```hcl
instance_type = "t3.small"  # Change from t3.micro
```
  
### Change VPC CIDR:
  
```hcl
vpc_cidr = "10.5.0.0/16"
```
  
### Restrict SSH Access:

```hcl
  ssh_allowed_cidrs = ["1.2.3.4/32"]  # Your IP only
```

After changes, run:
```bash
cd environments/dev
terragrunt apply
```

---

## 🔐 Security Features

### What's Implemented:

- ✅ Web servers in **private subnets** (no public IPs)
- ✅ Security groups with **least privilege**
- ✅ **IMDSv2 enforced** on all EC2 instances
- ✅ **Encrypted EBS volumes**
- ✅ **Encrypted S3 state** with versioning
- ✅ **State locking** via DynamoDB
- ✅ SSH keys stored in **AWS Secrets Manager**
- ✅ Multi-AZ deployment for high availability
---

## 📚 Key Concepts

### What is Terragrunt?

Terragrunt is a thin wrapper around Terraform that:
- Keeps your Terraform code DRY (Don't Repeat Yourself)
- Manages multiple environments easily
- Handles backend configuration automatically
- Provides dependency management

### What is IMDSv2?

Instance Metadata Service version 2 - a secure way for EC2 instances to access their metadata. Requires a session token, preventing SSRF attacks.

### Why Private Subnets?

- Web servers don't need public IPs
- Reduces attack surface
- Prevents direct internet access
- Industry best practice for production
- Outbound traffic routes through NAT Gateway

### Why Multiple NAT Gateways?

- High availability (one per AZ)
- If one AZ fails, others continue working
- Follows AWS best practices
- Costs more but provides resilience

---