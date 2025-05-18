
#--------------------------------------------------------------------
# Data block to fetch values from the console 
#--------------------------------------------------------------------
data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

#--------------------------------------------------------------------
# Creates lambda function to be used in the service catalog to start instances
#--------------------------------------------------------------------
module "Lambdas" {
  source   = "git::https://github.com/njibrigthain100/Cognitech-terraform-iac-modules.git//terraform/modules/Lambdas/Template?ref=v1.1.1"
  for_each = (var.Lambdas != null) ? { for item in var.Lambdas : item.function_name => item } : {}
  common   = var.common
  Lambda   = each.value
}


#------------------------------------------------------------------------------
# Creates lambda function to be used in the service catalog to start instances
#------------------------------------------------------------------------------
module "service_catalog" {
  source          = "git::https://github.com/njibrigthain100/Cognitech-terraform-iac-modules.git//terraform/modules/Service-catalog?ref=v1.1.1"
  for_each        = (var.service_catalogs != null) ? { for item in var.service_catalogs : item.name => item } : {}
  common          = var.common
  service_catalog = each.value
}
