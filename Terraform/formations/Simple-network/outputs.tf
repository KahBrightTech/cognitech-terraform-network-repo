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

output "public_subnet" { # This is the output for all public subnets by name index
  description = "Values for all public subnets by name index"
  value       = var.vpc != null ? { for public_subnet in var.vpc.public_subnets : public_subnet.name => public_subnet } : null
}




