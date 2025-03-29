#--------------------------------------------------------------------
# Security Group - Creates a security group for the vpc
#--------------------------------------------------------------------
module "security_group_rules" {
  source               = "git::https://github.com/njibrigthain100/Cognitech-terraform-iac-modules.git//terraform/modules/Security-group-rules?ref=v1.67"
  common               = var.common
  security_group_rules = var.security_group_rules
  bypass               = var.bypass

}
