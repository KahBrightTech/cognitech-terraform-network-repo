
module "shared_vpc" {
  source   = "../Create-Network"
  for_each = { for vpc in var.vpcs : vpc.name => vpc }
  vpc      = each.value
  common   = var.common
}

#--------------------------------------------------------------------
# Transit Gateway - Creates Transit Gateway
#--------------------------------------------------------------------
module "transit_gateway" {
  source = "git::https://github.com/njibrigthain100/Cognitech-terraform-iac-modules.git//terraform/modules/Transit-gateway?ref=v1.42"
  name   = var.vpc.transit_gateway.name
  common = var.common
}
