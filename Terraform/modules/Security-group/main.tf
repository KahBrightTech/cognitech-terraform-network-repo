#--------------------------------------------------------------------
# Security Group - Creates a security group for the vpc
#--------------------------------------------------------------------
module "security_group" {
  source         = "git::https://github.com/njibrigthain100/Cognitech-terraform-iac-modules.git//terraform/modules/Security-group?ref=v1.67"
  common         = var.common
  security_group = var.security_group
  bypass         = var.bypass

}
