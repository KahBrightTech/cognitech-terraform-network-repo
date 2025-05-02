
#--------------------------------------------------------------------
# Creates lIAM users
#--------------------------------------------------------------------
module "iam_user" {
  source   = "git::https://github.com/njibrigthain100/Cognitech-terraform-iac-modules.git//terraform/modules/IAM-User?ref=v1.114"
  for_each = (var.iam_users != null) ? { for item in var.iam_users : item.name => item } : {}
  common   = var.common
  iam_user = each.value
}



