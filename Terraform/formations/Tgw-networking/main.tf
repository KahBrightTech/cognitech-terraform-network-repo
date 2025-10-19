#--------------------------------------------------------------------
# Data
#--------------------------------------------------------------------
data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

#--------------------------------------------------------------------
# Transit Gateway - Creates Transit Gateway
#--------------------------------------------------------------------
module "transit_gateway" {
  count           = var.transit_gateway != null ? 1 : 0
  source          = "git::https://github.com/njibrigthain100/Cognitech-terraform-iac-modules.git//terraform/modules/Transit-gateway?ref=v1.3.78"
  transit_gateway = var.transit_gateway
  common          = var.common
}

#--------------------------------------------------------------------
# Transit Gateway route table - Creates Transit Gateway route tables
#--------------------------------------------------------------------
module "transit_gateway_route_table" {
  source   = "git::https://github.com/njibrigthain100/Cognitech-terraform-iac-modules.git//terraform/modules/Transit-gateway-route-table?ref=v1.1.17"
  for_each = var.tgw_route_table != null ? { for rt in var.tgw_route_table : rt.key => rt } : {}
  common   = var.common
  tgw_route_table = {
    name   = each.value.name
    tgw_id = each.value.tgw_id
  }
}

#--------------------------------------------------------------------
# Transit Gateway Association - Creates Transit Gateway associations
#--------------------------------------------------------------------
module "transit_gateway_association" {
  source   = "git::https://github.com/njibrigthain100/Cognitech-terraform-iac-modules.git//terraform/modules/Transit-gateway-association?ref=v1.1.18"
  for_each = var.tgw_associations != null ? { for assoc in var.tgw_associations : assoc.key => assoc } : {}
  common   = var.common
  depends_on = [
    module.transit_gateway_route_table
  ]
  tgw_association = merge(
    each.value,
    {
      route_table_id = each.value.route_table_id != null ? each.value.route_table_id : (
        each.value.route_table_key != null ?
        module.transit_gateway_route_table[each.value.route_table_key].tgw_rtb_id :
        each.value.route_table_name != null ?
        module.transit_gateway_route_table[each.value.route_table_name].tgw_rtb_id :
        values(module.transit_gateway_route_table)[0].tgw_rtb_id
      )
    }
  )
}

#--------------------------------------------------------------------
# Transit Gateway routes - Creates Transit Gateway routes for shared services
#--------------------------------------------------------------------
module "transit_gateway_route" {
  source   = "git::https://github.com/njibrigthain100/Cognitech-terraform-iac-modules.git//terraform/modules/Transit-gateway-routes?ref=v1.1.17"
  for_each = var.tgw_routes != null ? { for route in var.tgw_routes : route.key => route } : {}
  common   = var.common
  depends_on = [
    module.transit_gateway_route_table
  ]
  tgw_routes = {
    name                   = each.value.name
    blackhole              = each.value.blackhole
    destination_cidr_block = each.value.destination_cidr_block
    attachment_id          = each.value.blackhole == false && each.value.attachment_id != null ? each.value.attachment_id : null
    route_table_id = each.value.route_table_id != null ? each.value.route_table_id : (
      each.value.route_table_key != null ?
      module.transit_gateway_route_table[each.value.route_table_key].tgw_rtb_id :
      each.value.route_table_name != null ?
      module.transit_gateway_route_table[each.value.route_table_name].tgw_rtb_id :
      values(module.transit_gateway_route_table)[0].tgw_rtb_id
    )
  }
}

