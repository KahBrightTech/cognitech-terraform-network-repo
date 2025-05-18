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

output "public_subnet" {
  description = "Values for all public subnets by name index"
  value       = var.vpc != null ? { for key, item in var.vpc.public_subnets : item.name => module.public_subnets[item.name] } : null

}

#-------------------------------------------------------
# Public subnet oRoutes
# #-------------------------------------------------------
# output "public_routes" {
#   description = "Output of all public routes"
#   value       = module.public_route
# }





