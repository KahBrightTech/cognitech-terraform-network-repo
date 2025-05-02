
#--------------------------------------------------------------------
# Creates secrets
#--------------------------------------------------------------------
module "secrets" {
  source          = "git::https://github.com/njibrigthain100/Cognitech-terraform-iac-modules.git//terraform/modules/Secrets-manager?ref=v1.121"
  for_each        = (var.secrets != null) ? { for item in var.secrets : item.name => item } : {}
  common          = var.common
  secrets_manager = each.value
}



