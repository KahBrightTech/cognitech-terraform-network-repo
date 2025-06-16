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
#Public subnet Routes
#-------------------------------------------------------
output "public_routes" {
  description = "Output of all public routes"
  value       = module.public_route
}
