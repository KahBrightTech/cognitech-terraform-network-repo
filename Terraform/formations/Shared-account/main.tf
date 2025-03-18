
module "shared_vpc" {
  source   = "../Create-Network"
  for_each = { for vpc in var.vpcs : vpc.name => vpc }
  vpc      = each.value
  common   = var.common
}

#--------------------------------------------------------------------
# Transit Gateway - Creates Transit Gateway
#--------------------------------------------------------------------
module "shared_transit_gateway" {
  source          = "../../modules/Transit-gateway"
  transit_gateway = var.transit_gateway
  common          = var.common
}
