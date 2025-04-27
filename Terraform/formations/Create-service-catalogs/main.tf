
#--------------------------------------------------------------------
# Data block to fetch values from the console 
#--------------------------------------------------------------------
data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

#--------------------------------------------------------------------
# Creates lambda function to be used in the service catalog to start instances
#--------------------------------------------------------------------
module "Start_Instance" {
  source   = "git::https://github.com/njibrigthain100/Cognitech-terraform-iac-modules.git//terraform/modules/Lambdas/Start-Instance?ref=v1.96"
  for_each = (var.Lambdas != null) ? { for item in var.Lambdas : item.function_name => item } : {}
  common   = var.common
  Lambda   = each.value
}

# #--------------------------------------------------------------------
# # Creates lambda function to be used in the service catalog to stop instances
# #--------------------------------------------------------------------
# module "Stop_Instance" {
#   source   = "git::https://github.com/njibrigthain100/Cognitech-terraform-iac-modules.git//terraform/modules/Lambdas/Stop-Instance?ref=v1.96"
#   for_each = (var.Lambdas != null) ? { for item in var.Lambdas : item.function_name => item } : {}
#   common   = var.common
#   Lambda   = each.value
# }

