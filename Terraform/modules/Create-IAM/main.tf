
#--------------------------------------------------------------------
# Data block to fetch values from the console 
#--------------------------------------------------------------------
data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

#--------------------------------------------------------------------
# Creates lambda function to be used in the service catalog to start instances
#--------------------------------------------------------------------
module "iam_user" {
  source   = "git::https://github.com/njibrigthain100/Cognitech-terraform-iac-modules.git//terraform/modules/IAM-User?ref=v1.114"
  for_each = (var.iam_users != null) ? { for item in var.iam_users : item.name => item } : {}
  common   = var.common
  iam_user = each.value
}



