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


module "transit_gateway_attachment" {
  source = "../../modules/Transit-gateway-attachments"
  common = var.common
  vpc_id = module.shared_vpc[var.vpcs.name].vpc_id
  depends_on = [
    module.shared_vpc,
    module.transit_gateway
  ]
  tgw_attachments = {
    transit_gateway_id = module.transit_gateway.transit_gateway_id
    subnet_ids = [
      module.shared_vpc[var.vpcs.name].primary_public_subnet_id,
      module.shared_vpc[var.vpcs.name].secondary_public_subnet_id,
    ]
    attachment_name = var.tgw_attachments.attachment_name
  }
}

# The output for the shared vpc comes from the create vpc formation hence has an object with all the variables

# module "transit_gateway_route" {
#   source         = "../../modules/Transit-gateway-routes"
#   common         = var.common
#   route_table_id = module.shared_vpc.public_route_table_id
#   depends_on     = [module.shared_vpc]
#   tgw_routes = [
#     {
#       transit_gateway_id = module.shared_transit_gateway.transit_gateway_id
#     }
#   ]
# }
