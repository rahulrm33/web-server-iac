# Bootstrap Module - Terraform Backend Setup

This module creates the S3 bucket and DynamoDB table needed for Terraform remote state management.

## The Chicken-Egg Problem

Terraform needs a backend (S3 + DynamoDB) to store its state remotely, but how do you create that backend using Terraform?

**Solution**: This bootstrap module uses **local state** initially to create the backend resources. Once created, all other infrastructure uses the remote backend.

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│                Bootstrap Module (Local State)           │
│  Creates:                                               │
│  ├─ S3 Bucket (versioned, encrypted)                   │
│  └─ DynamoDB Table (for state locking)                 │
└─────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────┐
│           All Other Infrastructure (Remote State)       │
│  Uses:                                                  │
│  ├─ S3 Backend (created above)                         │
│  └─ DynamoDB Locking (created above)                   │
└─────────────────────────────────────────────────────────┘
```

## Quick Start

### Option 1: Using Terraform Directly (Recommended)

```bash
# Navigate to bootstrap directory
cd bootstrap

# Copy example tfvars
cp terraform.tfvars.example terraform.tfvars

# Edit variables
vim terraform.tfvars

# Initialize Terraform (uses local backend)
terraform init

# Review plan
terraform plan

# Create backend resources
terraform apply

# Note the outputs for later use
terraform output
```

### Option 2: Using the Helper Script

```bash
# The existing setup script can still be used
./scripts/setup-aws.sh
```

## What Gets Created

### S3 Bucket
- **Name**: `{project-name}-terraform-state-{environment}`
- **Versioning**: Enabled (keeps history of state files)
- **Encryption**: AES-256 server-side encryption
- **Public Access**: Blocked (security best practice)
- **Purpose**: Stores Terraform state files

### DynamoDB Table
- **Name**: `{project-name}-terraform-locks-{environment}`
- **Billing Mode**: Pay-per-request (cost-effective)
- **Encryption**: Enabled
- **Purpose**: Prevents concurrent Terraform operations

## Usage for Different Environments

### Development
```bash
cd bootstrap
terraform apply -var="environment=dev"
```

### Staging
```bash
cd bootstrap
terraform apply -var="environment=staging"
```

### Production
```bash
cd bootstrap
terraform apply -var="environment=prod" \
  -var="enable_point_in_time_recovery=true" \
  -var="enable_monitoring=true"
```

## Advanced: Migrating Bootstrap State to Remote

Once the backend is created, you can optionally migrate the bootstrap module's state to the remote backend it just created:

### Step 1: Update backend configuration

Edit `bootstrap/main.tf` and change:

```hcl
backend "local" {
  path = "terraform.tfstate"
}
```

To:

```hcl
backend "s3" {
  bucket         = "web-loadbalancer-terraform-state-dev"  # Your bucket name
  key            = "bootstrap/terraform.tfstate"
  region         = "us-east-1"
  dynamodb_table = "web-loadbalancer-terraform-locks-dev"  # Your table name
  encrypt        = true
}
```

### Step 2: Migrate state

```bash
cd bootstrap
terraform init -migrate-state
```

Terraform will ask to migrate. Type `yes`.

## Configuration Variables

| Variable | Description | Default | Required |
|----------|-------------|---------|----------|
| `project_name` | Project name for resource naming | `web-loadbalancer` | No |
| `environment` | Environment (dev/staging/prod) | - | Yes |
| `aws_region` | AWS region | `us-east-1` | No |
| `enable_point_in_time_recovery` | Enable DynamoDB PITR | `false` | No |
| `enable_monitoring` | Enable CloudWatch alarms | `false` | No |

## Outputs

After running `terraform apply`, you'll get:

- `s3_bucket_name` - S3 bucket name
- `dynamodb_table_name` - DynamoDB table name
- `backend_config` - Configuration for backend
- `next_steps` - Instructions for next steps

## Cost

### Development/Staging
- **S3**: ~$0.023/GB/month + requests
- **DynamoDB**: Pay-per-request (very low for state locking)
- **Total**: Usually < $1/month

### Production (with PITR and monitoring)
- **S3**: ~$0.023/GB/month + requests
- **DynamoDB**: ~$0.25/month (PITR)
- **CloudWatch**: ~$0.10/month (alarms)
- **Total**: Usually < $2/month

## Security Features

✅ S3 bucket versioning (recover from accidents)  
✅ S3 encryption at rest  
✅ S3 public access blocked  
✅ DynamoDB encryption at rest  
✅ DynamoDB point-in-time recovery (optional)  
✅ CloudWatch monitoring (optional)  

## Cleanup

To destroy the bootstrap resources (⚠️ will delete state storage):

```bash
cd bootstrap
terraform destroy
```

**Warning**: Only destroy when:
1. All infrastructure using this backend has been destroyed
2. You've backed up any important state files
3. You're certain you won't need the state history

## Troubleshooting

### Issue: Bucket name already exists

S3 bucket names are globally unique. If you get this error:

```bash
# Change project name or add a suffix
terraform apply -var="project_name=web-loadbalancer-yourname"
```

### Issue: Insufficient permissions

Ensure your AWS credentials have:
- `s3:CreateBucket`, `s3:PutBucketVersioning`, etc.
- `dynamodb:CreateTable`, `dynamodb:DescribeTable`, etc.

### Issue: State file lost

If you lose the local state file:

1. Import existing resources:
```bash
terraform import aws_s3_bucket.terraform_state your-bucket-name
terraform import aws_dynamodb_table.terraform_locks your-table-name
```

2. Or recreate from scratch (if backend is empty)

## Best Practices

### For Development
- Use default settings
- Single developer: locking is less critical
- Can recreate easily if needed

### For Production
- Enable point-in-time recovery
- Enable monitoring and alarms
- Set `prevent_destroy = true` in lifecycle blocks
- Restrict IAM access to backend resources
- Enable S3 bucket logging
- Use a separate AWS account for state storage (advanced)

## Integration with Main Infrastructure

The bootstrap module is separate from your main infrastructure. Here's the workflow:

```bash
# 1. Create backend (bootstrap - one time)
cd bootstrap
terraform apply

# 2. Deploy infrastructure (uses remote backend)
cd ../environments/dev
terragrunt init   # Connects to backend created above
terragrunt apply  # State stored in S3

# 3. Deploy to other environments
cd ../staging
terragrunt init
terragrunt apply

cd ../prod
terragrunt init
terragrunt apply
```

## Why This Approach?

### Advantages ✅
- **Infrastructure as Code**: Backend is version controlled
- **Reproducible**: Can recreate in disaster recovery
- **Auditable**: Changes are tracked in Git
- **Automated**: Can be part of CI/CD pipeline
- **Secure**: Follows AWS security best practices

### Alternative Approaches

1. **Manual AWS Console**: Not IaC ❌
2. **AWS CLI Script**: What we had before (works but not IaC) ⚠️
3. **CloudFormation**: Could work but mixing tools ⚠️
4. **Terraform Cloud**: SaaS backend (no need for S3) 💰

## Summary

This bootstrap module solves the chicken-egg problem by:
1. Using local state initially
2. Creating S3 and DynamoDB resources
3. Allowing all other infrastructure to use remote state

It's a one-time setup per environment that provides a solid foundation for your infrastructure.

---

**Next Steps**: After running bootstrap, go to `environments/dev` and run `terragrunt init`.

