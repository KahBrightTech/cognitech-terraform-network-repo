#-------------------------------------------------------
# VPC outputs
#-------------------------------------------------------
output "vpc_id" {
  description = "The id of the vpc created"
  value       = tostring(module.vpc.vpc_id)
}
output "igw_id" {
  description = "The internet gateway id"
  value       = module.vpc.igw_id
}


# #-------------------------------------------------------
# # Private subnet outputs
# #-------------------------------------------------------
# output "private_subnets" {
#   description = "Output of all private subnets"
#   value       = values(module.private_subnets)
# }
# output "pvt" {
#   description = "The subnet details based on private_subnets module"
#   value = {
#     "primary_subnet" = {
#       availability_zone = module.private_subnets.primary_az
#       subnet_arn        = module.private_subnets.primary_subnet_arn
#       subnet_id         = module.private_subnets.primary_subnet_id
#       subnet_cidr       = module.private_subnets.primary_subnet_cidr
#     }
#     "secondary_subnet" = {
#       availability_zone = module.private_subnets.secondary_az
#       subnet_arn        = module.private_subnets.secondary_subnet_arn
#       subnet_id         = module.private_subnets.secondary_subnet_id
#       subnet_cidr       = module.private_subnets.secondary_subnet_cidr
#     }
#     "tertiary_subnet" = {
#       availability_zone = module.private_subnets.tertiary_az
#       subnet_arn        = module.private_subnets.tertiary_subnet_arn
#       subnet_id         = module.private_subnets.tertiary_subnet_id
#       subnet_cidr       = module.private_subnets.tertiary_subnet_cidr
#     }
#     "quaternary_subnet" = {
#       availability_zone = module.private_subnets.quaternary_az
#       subnet_arn        = module.private_subnets.quaternary_subnet_arn
#       subnet_id         = module.private_subnets.quaternary_subnet_id
#       subnet_cidr       = module.private_subnets.quaternary_subnet_cidr
#     }
#   }
# }

# output "primary_private_subnet_id" {
#   description = "The primary private subnet id"
#   value       = module.private_subnets.primary_subnet_id
# }
# output "secondary_private_subnet_id" {
#   description = "The secondary private subnet id"
#   value       = module.private_subnets.secondary_subnet_id

# }

# output "tertiary_private_subnet_ids" {
#   description = "The tertiary private subnet id"
#   value       = module.private_subnets.tertiary_subnet_id

# }

# output "private_route_table_id" {
#   description = "The public route table id"
#   value       = module.private_route.private_route_table_id

# }

# #-------------------------------------------------------
# # Public subnet outputs
# #-------------------------------------------------------
# output "public_subnets" {
#   description = "Output of all public subnets"
#   value       = values(module.public_subnets)
# }
# output "pub" {
#   description = "The subnet details based on public_subnets module"
#   value = {
#     "primary_subnet" = {
#       availability_zone = module.public_subnets.primary_az
#       subnet_arn        = module.public_subnets.primary_subnet_arn
#       subnet_id         = module.public_subnets.primary_subnet_id
#       subnet_cidr       = module.public_subnets.primary_subnet_cidr
#     }
#     "secondary_subnet" = {
#       availability_zone = module.public_subnets.secondary_az
#       subnet_arn        = module.public_subnets.secondary_subnet_arn
#       subnet_id         = module.public_subnets.secondary_subnet_id
#       subnet_cidr       = module.public_subnets.secondary_subnet_cidr
#     }
#     "tertiary_subnet" = {
#       availability_zone = module.public_subnets.tertiary_az
#       subnet_arn        = module.public_subnets.tertiary_subnet_arn
#       subnet_id         = module.public_subnets.tertiary_subnet_id
#       subnet_cidr       = module.public_subnets.tertiary_subnet_cidr
#     }
#     "quaternary_subnet" = {
#       availability_zone = module.public_subnets.quaternary_az
#       subnet_arn        = module.public_subnets.quaternary_subnet_arn
#       subnet_id         = module.public_subnets.quaternary_subnet_id
#       subnet_cidr       = module.public_subnets.quaternary_subnet_cidr
#     }
#   }
# }


# output "primary_public_subnet_id" {
#   description = "The primary public subnet id"
#   value       = module.public_subnets.primary_subnet_id

# }
# output "secondary_public_subnet_id" {
#   description = "The secondary public subnet id"
#   value       = module.public_subnets.secondary_subnet_id

# }

# output "tertiary_public_subnet_ids" {
#   description = "The tertiary public subnet id"
#   value       = module.public_subnets.tertiary_subnet_id

# }

# output "public_route_table_id" {
#   description = "The public route table id"
#   value       = module.public_route.public_route_table_id

# }

#-------------------------------------------------------
# Security group outputs
#-------------------------------------------------------
output "security_group" {
  description = "Security group details"
  value = var.vpc != null ? var.vpc.security_groups != null ? {
    for key, item in module.security_groups :
    key => {
      arn = item.security_group_arn
      id  = item.security_group_id
    }
  } : null : null
}

#-------------------------------------------------------
# S3 bucket outputs
#-------------------------------------------------------
output "s3_data_bucket_arn" {
  description = "The ARN of the S3 bucket"
  value       = module.s3_data_bucket != null ? module.s3_data_bucket.arn : null
}

output "s3_data_bucket_id" {
  description = "The ID of the S3 bucket"
  value       = module.s3_data_bucket != null ? module.s3_data_bucket.id : null

}

#-------------------------------------------------------
# Public subnet outputs
#-------------------------------------------------------
output "public_subnets" {
  description = "Output of all public subnets"
  value       = values(module.public_subnets)
}

output "public_subnet" {
  description = "Values for all public subnets by name index"
  value       = var.vpc != null ? { for key, item in var.vpc.public_subnets : item.name => module.public_subnets[item.name] } : null

}

#-------------------------------------------------------
# Private subnet outputs
#-------------------------------------------------------
output "private_subnets" {
  description = "Output of all private subnets"
  value       = values(module.private_subnets)
}

output "private_subnet" {
  description = "Values for all private subnets by name index"
  value       = var.vpc != null ? { for key, item in var.vpc.private_subnets : item.name => module.private_subnets[item.name] } : null

}

#-------------------------------------------------------
#Public subnet oRoutes
#-------------------------------------------------------
output "public_routes" {
  description = "Output of all public routes"
  value       = module.public_route
}
