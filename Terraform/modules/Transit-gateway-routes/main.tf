#--------------------------------------------------------------------
# Transit Gateway - Creates Transit Gateway
#--------------------------------------------------------------------
module "transit_gateway_routes" {
  source         = "git::https://github.com/njibrigthain100/Cognitech-terraform-iac-modules.git//terraform/modules/Transit-gateway-routes?ref=v1.50"
  common         = var.common
  tgw_routes     = var.tgw_routes
  route_table_id = var.route_table_id
}
