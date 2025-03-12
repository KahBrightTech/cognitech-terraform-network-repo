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
# Private subnet outputs
#-------------------------------------------------------
output "private_subnets" {
  description = "Output of all private subnets"
  value       = values(module.private_subnets)
}
# output "private_subnet" {
#   description = "The private subnet resources"
#   value = var.vpc != null ? {
#     for key, item in var.vpc.private_subnets :
#     item.name => module.private_subnets[item.name]
#   } : null
# }

output "primary_private_subnet_ids" {
  description = "The public subnet ids"
  value       = module.private_subnets.primary_subnet_id
}
output "secondary_private_subnet_ids" {
  description = "The public subnet ids"
  value       = module.private_subnets.secondary_subnet_id

}

output "tertiary_private_subnet_ids" {
  description = "The public subnet ids"
  value       = module.private_subnets.tertiary_subnet_id

}

#-------------------------------------------------------
# Public subnet outputs
#-------------------------------------------------------
output "public_subnets" {
  description = "Output of all public subnets"
  value       = values(module.public_subnets)
}
# output "public_subnet" {
#   description = "The public subnet resources"
#   value = var.vpc != null ? {
#     for key, item in var.vpc.public_subnets :
#     item.name => module.public_subnets[item.name]
#   } : null
# }

output "primary_public_subnet_ids" {
  description = "The public subnet ids"
  value       = module.public_subnets.primary_subnet_id

}
output "secondary_public_subnet_ids" {
  description = "The public subnet ids"
  value       = module.public_subnets.secondary_subnet_id

}

output "tertiary_public_subnet_ids" {
  description = "The public subnet ids"
  value       = module.public_subnets.tertiary_subnet_id

}



