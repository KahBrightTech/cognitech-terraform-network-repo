#-------------------------------------------------------
# IAM outputs
#-------------------------------------------------------
output "IAM_roles" {
  description = "IAM roles and policies details"
  value       = module.iam_roles
}

#-------------------------------------------------------
# S3 outputs
#-------------------------------------------------------
output "S3_buckets" {
  description = "S3 buckets details"
  value       = module.s3_app_bucket
}

#-------------------------------------------------------
# EC2 module output
#-------------------------------------------------------
output "ec2" {
  description = "The EC2 instance details"
  value       = module.ec2_instance
}

#-------------------------------------------------------
# Route 53 module output  
#-------------------------------------------------------
output "hosted_zones" {
  description = "The Route 53 hosted zones details"
  value       = module.hosted_zones
}

#-------------------------------------------------------
# Target Group outputs  
#-------------------------------------------------------
output "target_groups" {
  description = "Output for Target Groups"
  value       = module.target_groups
}

#-------------------------------------------------------
# DataSync Locations outputs
#-------------------------------------------------------
output "datasync_locations" {
  description = "Output for DataSync Locations"
  value       = module.datasync_locations
}

#-------------------------------------------------------
# DataSync Tasks outputs
#-------------------------------------------------------
output "datasync_tasks" {
  description = "Output for DataSync Tasks"
  value       = module.datasync_tasks
}

#-------------------------------------------------------
# VPC Endpoints outputs
#-------------------------------------------------------
output "vpc_endpoints" {
  description = "Output for VPC Endpoints"
  value       = module.vpc_endpoints
}

#-------------------------------------------------------
# Security Group outputs
#-------------------------------------------------------
output "security_groups" {
  description = "Output for Security Groups"
  value       = module.security_groups
}

#-------------------------------------------------------
# Security Group Rules outputs
#-------------------------------------------------------
output "security_group_rules" {
  description = "Output for Security Groups Rules"
  value       = module.security_group_rules
}