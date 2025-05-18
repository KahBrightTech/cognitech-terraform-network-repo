#-------------------------------------------------------
# VPC outputs
#-------------------------------------------------------
output "vpc_id" {
  description = "The id of the vpc created"
  value       = module.vpc.vpc_id
}
output "igw_id" {
  description = "The internet gateway id"
  value       = module.vpc.igw_id
}

#-------------------------------------------------------
# Public subnet outputs
#-------------------------------------------------------
output "public_subnets" {
  description = "Output of all public subnets"
  value       = values(module.public_subnets)
}

# output "primary_public_subnet_ids" {
#   description = "The public subnet ids"
#   value       = module.public_subnets.primary_subnet_id

# }
# output "secondary_public_subnet_ids" {
#   description = "The public subnet ids"
#   value       = module.public_subnets.secondary_subnet_id

# }

# output "tertiary_public_subnet_ids" {
#   description = "The public subnet ids"
#   value       = module.public_subnets.tertiary_subnet_id

# }



