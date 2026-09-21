variable "aws_region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "ap-south-1"
}

variable "environment" {
  description = "Deployment environment (dev or prod) — must match the active workspace"
  type        = string

  validation {
    condition     = contains(["dev", "prod"], var.environment)
    error_message = "environment must be either \"dev\" or \"prod\"."
  }
}

variable "project_name" {
  description = "Project name used as a prefix for resource naming/tagging"
  type        = string
  default     = "mse-terraform-lab"
}

variable "instance_type" {
  description = "EC2 instance type — smaller for dev, larger for prod"
  type        = string
}

variable "instance_count" {
  description = "Number of EC2 instances to launch — fewer for dev, more for prod"
  type        = number
}

variable "enable_detailed_monitoring" {
  description = "Enable detailed (1-minute) CloudWatch monitoring — typically only worth the cost in prod"
  type        = bool
  default     = false
}

variable "allowed_ssh_cidr" {
  description = "CIDR block allowed to SSH into instances"
  type        = string
  default     = "0.0.0.0/0" # NOTE: lock this down to your IP/32 in a real deployment
}
