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
output "pvt" {
  description = "The subnet details based on private_subnets module"
  value = {
    "primary_subnet" = {
      availability_zone = module.private_subnets.primary_az
      subnet_arn        = module.private_subnets.primary_subnet_arn
      subnet_id         = module.private_subnets.primary_subnet_id
      subnet_cidr       = module.private_subnets.primary_subnet_cidr
    }
    "secondary_subnet" = {
      availability_zone = module.private_subnets.secondary_az
      subnet_arn        = module.private_subnets.secondary_subnet_arn
      subnet_id         = module.private_subnets.secondary_subnet_id
      subnet_cidr       = module.private_subnets.secondary_subnet_cidr
    }
    "tertiary_subnet" = {
      availability_zone = module.private_subnets.tertiary_az
      subnet_arn        = module.private_subnets.tertiary_subnet_arn
      subnet_id         = module.private_subnets.tertiary_subnet_id
      subnet_cidr       = module.private_subnets.tertiary_subnet_cidr
    }
    "quaternary_subnet" = {
      availability_zone = module.private_subnets.quaternary_az
      subnet_arn        = module.private_subnets.quaternary_subnet_arn
      subnet_id         = module.private_subnets.quaternary_subnet_id
      subnet_cidr       = module.private_subnets.quaternary_subnet_cidr
    }
  }
}

output "primary_private_subnet_id" {
  description = "The primary private subnet id"
  value       = module.private_subnets.primary_subnet_id
}
output "secondary_private_subnet_id" {
  description = "The secondary private subnet id"
  value       = module.private_subnets.secondary_subnet_id

}

output "tertiary_private_subnet_ids" {
  description = "The tertiary private subnet id"
  value       = module.private_subnets.tertiary_subnet_id

}

#-------------------------------------------------------
# Public subnet outputs
#-------------------------------------------------------
output "public_subnets" {
  description = "Output of all public subnets"
  value       = values(module.public_subnets)
}
output "pub" {
  description = "The subnet details based on public_subnets module"
  value = {
    "primary_subnet" = {
      availability_zone = module.public_subnets.primary_az
      subnet_arn        = module.public_subnets.primary_subnet_arn
      subnet_id         = module.public_subnets.primary_subnet_id
      subnet_cidr       = module.public_subnets.primary_subnet_cidr
    }
    "secondary_subnet" = {
      availability_zone = module.public_subnets.secondary_az
      subnet_arn        = module.public_subnets.secondary_subnet_arn
      subnet_id         = module.public_subnets.secondary_subnet_id
      subnet_cidr       = module.public_subnets.secondary_subnet_cidr
    }
    "tertiary_subnet" = {
      availability_zone = module.public_subnets.tertiary_az
      subnet_arn        = module.public_subnets.tertiary_subnet_arn
      subnet_id         = module.public_subnets.tertiary_subnet_id
      subnet_cidr       = module.public_subnets.tertiary_subnet_cidr
    }
    "quaternary_subnet" = {
      availability_zone = module.public_subnets.quaternary_az
      subnet_arn        = module.public_subnets.quaternary_subnet_arn
      subnet_id         = module.public_subnets.quaternary_subnet_id
      subnet_cidr       = module.public_subnets.quaternary_subnet_cidr
    }
  }
}


output "primary_public_subnet_id" {
  description = "The primary public subnet id"
  value       = module.public_subnets.primary_subnet_id

}
output "secondary_public_subnet_ids" {
  description = "The secondary public subnet id"
  value       = module.public_subnets.secondary_subnet_id

}

output "tertiary_public_subnet_ids" {
  description = "The tertiary public subnet id"
  value       = module.public_subnets.tertiary_subnet_id

}



