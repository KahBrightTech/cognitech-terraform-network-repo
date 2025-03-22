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

module "transit_gateway_attachment" {
  source = "../../modules/Transit-gateway-attachments"
  common = var.common
  tgw_attachments = {
    transit_gateway_id  = module.shared_transit_gateway.transit_gateway_id
    primary_subnet_id   = module.shared_vpc.public_primary_subnet_id
    secondary_subnet_id = module.shared_vpc.public_secondary_subnet_id
    vpc_id              = module.shared_vpc.vpc_id
    attachment_name     = var.tgw_attachments.attachment_name
  }
}

module "transit_gateway_route" {
  source = "../../modules/Transit-gateway-routes"
  common = var.common
  tgw_routes = {
    transit_gateway_id = module.shared_transit_gateway.transit_gateway_id
    route_table_id     = module.shared_vpc.public_route_table_id
    vpc_cidr_block     = var.tgw_routes.vpc_cidr_block
  }
}
