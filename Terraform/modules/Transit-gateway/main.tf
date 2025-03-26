#--------------------------------------------------------------------
# Transit Gateway - Creates Transit Gateway
#--------------------------------------------------------------------
module "transit_gateway" {
  source          = "git::https://github.com/njibrigthain100/Cognitech-terraform-iac-modules.git//terraform/modules/Transit-gateway?ref=v1.66"
  common          = var.common
  transit_gateway = var.transit_gateway
}
