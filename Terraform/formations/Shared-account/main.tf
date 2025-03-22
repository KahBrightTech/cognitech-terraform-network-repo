module "public_route" {
  source = "../Create-Network"
}

module "shared_vpc" {
  source   = ""
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

module "transit_gateway_attachment" {
  source                            = "../../modules/Transit-gateway-attachment"
  common                            = var.common
  transit_gateway_id                = module.shared_transit_gateway.transit_gateway_id
  shared_public_primary_subnet_id   = module.shared_vpc.public_primary_subnet_id
  shared_public_secondary_subnet_id = module.shared_vpc.public_secondary_subnet_id
  shared_vpc_id                     = module.shared_vpc.vpc_id
}

module "transit_gateway_route" {
  source = "../../modules/Transit-gateway-routes"
  common = var.common
  tgw_routes = [
    {
      transit_gateway_id = module.shared_transit_gateway.transit_gateway_id
      route_table_id     = module.public_route.public_route_table_id
    }
  ]
}
