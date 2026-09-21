output "workspace" {
  description = "Active Terraform workspace"
  value       = terraform.workspace
}

output "vpc_id" {
  description = "Default VPC used for this environment"
  value       = data.aws_vpc.default.id
}

output "availability_zones" {
  description = "AZs available in the region"
  value       = data.aws_availability_zones.available.names
}

output "ami_id" {
  description = "AMI used for the app instances"
  value       = data.aws_ami.amazon_linux.id
}

output "instance_ids" {
  description = "IDs of the launched EC2 instances"
  value       = aws_instance.app[*].id
}

output "instance_public_ips" {
  description = "Public IPs of the launched EC2 instances"
  value       = aws_instance.app[*].public_ip
}

output "bucket_name" {
  description = "Name of the per-environment S3 bucket"
  value       = aws_s3_bucket.app_data.bucket
}
