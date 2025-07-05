output "customer_products" {
  description = "List of resources to be created for the customer"
  value       = module.customer_vpc
}

output "transit_gateway_attachment" {
  description = "Transit Gateway attachment details"
  value       = module.transit_gateway_attachment
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

output "ec2_key_pairs" {
  description = "ec2 key pairs details"
  value       = module.ec2_key_pairs
}

output "load_balancers" {
  description = "Load balancers details"
  value       = module.load_balancers

}
