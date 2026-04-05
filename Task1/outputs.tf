output "vpc_id" {
  value       = aws_vpc.payroll_vpc.id
  description = "VPC ID"
}

output "public_subnet_ids" {
  value       = aws_subnet.public[*].id
  description = "List of public subnet IDs"
}

output "private_subnet_ids" {
  value       = aws_subnet.private[*].id
  description = "List of private subnet IDs"
}

output "ec2_instance_ids" {
  value = {
    for k, v in aws_instance.tenant_ec2 : k => v.id
  }
  description = "EC2 Instance IDs by tenant"
}

output "ec2_private_ips" {
  value = {
    for k, v in aws_instance.tenant_ec2 : k => v.private_ip
  }
  description = "Private IPs of EC2 instances by tenant"
}

output "rds_endpoint" {
  value       = aws_db_instance.payroll_rds.endpoint
  description = "RDS PostgreSQL endpoint"
}

output "rds_db_name" {
  value       = aws_db_instance.payroll_rds.db_name
  description = "RDS database name"
}

output "secret_arn" {
  value       = aws_secretsmanager_secret.rds_secret.arn
  description = "ARN of Secrets Manager secret containing RDS credentials"
}
output "s3_bucket_name" {
  value       = aws_s3_bucket.payroll_documents.id
  description = "S3 bucket name for documents and reports"
}

output "rds_password" {
  value       = random_password.rds_password.result
  sensitive   = true
  description = "RDS admin password (sensitive - do not share)"
}