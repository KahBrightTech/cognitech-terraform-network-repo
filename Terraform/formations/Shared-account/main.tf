module "shared_vpc" {
  source   = "../Create-Network"
  for_each = { for vpc in var.vpcs : vpc.name => vpc }
  vpc      = each.value
  common   = var.common
}

# module "transit_gateway_attachment" {
#   source     = "../../modules/Transit-gateway-attachments"
#   common     = var.common
#   vpc_id     = module.shared_vpc.vpc_id
#   depends_on = [module.shared_vpc]
#   tgw_attachments = {
#     transit_gateway_id  = module.shared_transit_gateway.transit_gateway_id
#     primary_subnet_id   = module.shared_vpc.primary_public_subnet_id
#     secondary_subnet_id = module.shared_vpc.secondary_public_subnet_id
#     attachment_name     = var.tgw_attachments.attachment_name
#   }
# }

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
