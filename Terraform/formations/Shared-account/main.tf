module "public_route" {
  source = "git::https://github.com/njibrigthain100/Cognitech-terraform-iac-modules.git//terraform/modules/Routes/public_routes?ref=v1.35"
  vpc_id = module.vpc.vpc_id
  public_routes = {
    public_gateway_id      = module.vpc.igw_id
    destination_cidr_block = var.vpcs.public_routes.destination_cidr_block
    primary_subnet_id      = module.public_subnets.primary_subnet_id
    secondary_subnet_id    = module.public_subnets.secondary_subnet_id
    tertiary_subnet_id     = module.public_subnets.tertiary_subnet_id
  }
  common = var.common
}
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
  }
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
