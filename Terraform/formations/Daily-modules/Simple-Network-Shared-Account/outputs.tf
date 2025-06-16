output "Account_products" {
  description = "List of resources to be created"
  value       = module.shared_vpc
}
output "IAM_roles" {
  description = "IAM roles and policies details"
  value       = module.iam_roles
}

output "ec2_profiles" {
  description = "EC2 instance profiles details"
  value       = module.ec2_profiles
}

output "iam_policies" {
  description = "IAM policies details"
  value       = module.iam_policies
}
