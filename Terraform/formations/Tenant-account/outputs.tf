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
