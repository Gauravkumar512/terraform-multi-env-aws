locals {
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    Workspace   = terraform.workspace
    ManagedBy   = "terraform"
  }
}

# ---------------------------------------------------------------------------
# Data blocks — everything below is looked up at plan time, nothing is
# hardcoded (no vpc-xxxx / subnet-xxxx / ami-xxxx literals anywhere).
# ---------------------------------------------------------------------------

data "aws_caller_identity" "current" {}

data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

data "aws_ami" "amazon_linux" {
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

# ---------------------------------------------------------------------------
# Resources
# ---------------------------------------------------------------------------

resource "aws_security_group" "web" {
  name        = "${var.project_name}-${var.environment}-web-sg"
  description = "Allow HTTP and SSH for ${var.environment}"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.allowed_ssh_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-web-sg"
  })
}

resource "aws_instance" "app" {
  count = var.instance_count

  ami           = data.aws_ami.amazon_linux.id
  instance_type = var.instance_type

  # Spread instances across whichever default subnets/AZs actually exist
  subnet_id = element(
    data.aws_subnets.default.ids,
    count.index % length(data.aws_subnets.default.ids)
  )

  vpc_security_group_ids = [aws_security_group.web.id]
  monitoring             = var.enable_detailed_monitoring

  user_data = <<-EOF
    #!/bin/bash
    yum install -y httpd
    systemctl enable --now httpd
    echo "<h1>${var.project_name} - ${var.environment} - instance ${count.index}</h1>" > /var/www/html/index.html
  EOF

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-app-${count.index}"
  })
}

resource "aws_s3_bucket" "app_data" {
  bucket = "${var.project_name}-${var.environment}-${data.aws_caller_identity.current.account_id}"

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-app-data"
  })
}

resource "aws_s3_bucket_versioning" "app_data" {
  bucket = aws_s3_bucket.app_data.id

  versioning_configuration {
    status = var.environment == "prod" ? "Enabled" : "Disabled"
  }
}
