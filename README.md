# Terraform Multi-Environment AWS Infrastructure

A single Terraform configuration that provisions two isolated environments
— `dev` and `prod` — in one AWS account, using **workspaces** for state
isolation, **variables** for per-environment configuration, and **data
sources** to avoid any hardcoded resource IDs.

## Architecture

Each environment provisions:
- A security group (HTTP + SSH access)
- N EC2 instances running Amazon Linux, bootstrapped via `user_data` to
  serve a simple web page
- An S3 bucket for application data

All resource identifiers (VPC, subnets, AMI, account ID) are resolved at
plan time through `data` blocks — nothing is hardcoded.

## Project structure

| File | Purpose |
|---|---|
| `terraform.tf` | Terraform and provider version constraints, `provider "aws"` block |
| `variables.tf` | Input variables: region, environment, project_name, instance_type, instance_count, enable_detailed_monitoring, allowed_ssh_cidr |
| `main.tf` | Data sources (caller identity, availability zones, default VPC, default subnets, latest Amazon Linux AMI) and resources (security group, EC2 instances, S3 bucket + versioning) |
| `outputs.tf` | Instance IDs/public IPs, bucket name, VPC ID, AMI ID, availability zones |
| `terraform.tfvars.dev` | Dev-environment values |
| `terraform.tfvars.prod` | Prod-environment values |

## Environment configuration

| | dev | prod |
|---|---|---|
| Instance type | t3.micro | t3.small |
| Instance count | 1 | 3 |
| Detailed monitoring | off | on |
| S3 bucket versioning | disabled | enabled |
| Tags | `Environment = dev` | `Environment = prod` |

## Prerequisites

- Terraform >= 1.9
- AWS CLI configured with valid credentials (`aws sts get-caller-identity`
  should return your account/user ARN)

## Usage

```bash
terraform init

# create the two workspaces (one-time)
terraform workspace new dev
terraform workspace new prod

# --- dev ---
terraform workspace select dev
terraform plan  -var-file="terraform.tfvars.dev"
terraform apply -var-file="terraform.tfvars.dev"

# --- prod ---
terraform workspace select prod
terraform plan  -var-file="terraform.tfvars.prod"
terraform apply -var-file="terraform.tfvars.prod"
```

State is isolated per workspace automatically, stored locally under
`terraform.tfstate.d/<workspace>/terraform.tfstate`.

## Verification

```bash
terraform workspace list
terraform validate
grep -c "^data " main.tf     # 5 data blocks
```

## Cleanup

```bash
terraform workspace select dev
terraform destroy -var-file="terraform.tfvars.dev"

terraform workspace select prod
terraform destroy -var-file="terraform.tfvars.prod"
```
