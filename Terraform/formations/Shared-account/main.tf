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
  source          = "../../modules/Transit-gateway"
  transit_gateway = var.transit_gateway
  common          = var.common
}

#--------------------------------------------------------------------
# Transit Gateway attacments - Creates Transit Gateway attachments
#--------------------------------------------------------------------
module "transit_gateway_attachment" {
  source = "../../modules/Transit-gateway-attachments"
  common = var.common
  vpc_id = module.shared_vpc[var.tgw_attachments.name].vpc_id
  depends_on = [
    module.shared_vpc,
    module.transit_gateway
  ]
  tgw_attachments = {
    transit_gateway_id = module.transit_gateway.transit_gateway_id
    subnet_ids = [
      module.shared_vpc[var.tgw_attachments.name].primary_public_subnet_id, # The output for the shared vpc comes from the create vpc formation hence has an object with all the variables
      module.shared_vpc[var.tgw_attachments.name].secondary_public_subnet_id,
    ]
    name = var.tgw_attachments.name
  }
}

#--------------------------------------------------------------------
# Transit Gateway routes - Creates Transit Gateway routes
#--------------------------------------------------------------------

module "transit_gateway_route" {
  source         = "../../modules/Transit-gateway-routes"
  common         = var.common
  route_table_id = module.shared_vpc[var.tgw_attachments.name].public_route_table_id
  depends_on     = [module.shared_vpc]
  tgw_routes = [
    {
      transit_gateway_id = module.transit_gateway.transit_gateway_id
    }
  ]
}
