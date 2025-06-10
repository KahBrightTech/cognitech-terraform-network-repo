output "Account_products" {
  description = "List of resources to be created"
  value       = module.shared_vpc
}

output "transit_gateway" {
  description = "Transit Gateway details"
  value       = module.transit_gateway
}
output "transit_gateway_attachment" {
  description = "Transit Gateway attachment details"
  value       = module.transit_gateway_attachment
}

output "transit_gateway_route_table" {
  description = "Transit Gateway route table details"
  value       = module.transit_gateway_route_table
}
output "s3_app_bucket" {
  description = "S3 bucket details"
  value       = module.s3_app_bucket
  depends_on  = [module.shared_vpc]
}

output "IAM_roles" {
  description = "IAM roles and policies details"
  value       = module.IAM_roles
}
