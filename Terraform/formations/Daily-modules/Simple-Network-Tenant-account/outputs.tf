output "customer_products" {
  description = "List of resources to be created for the customer"
  value       = module.customer_vpc
}
output "s3_app_bucket" {
  description = "S3 bucket details"
  value       = module.s3_app_bucket
  depends_on  = [module.customer_vpc]
}

output "iam_roles" {
  description = "IAM roles and policies details"
  value       = module.iam_roles
}

output "ec2_profiles" {
  description = "EC2 instance profiles details"
  value       = module.ec2-profiles
}

output "iam_policies" {
  description = "IAM policies details"
  value       = module.iam_policies
}
