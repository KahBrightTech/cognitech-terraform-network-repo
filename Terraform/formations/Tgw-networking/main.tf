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
# Transit Gateway attacments - Creates Transit Gateway attachments
#--------------------------------------------------------------------
module "transit_gateway_attachment" {
  count  = var.tgw_attachments != null ? 1 : 0
  source = "git::https://github.com/njibrigthain100/Cognitech-terraform-iac-modules.git//terraform/modules/Transit-gateway-attachments?ref=v1.3.81"
  common = var.common
  vpc_id = var.vpcs != null ? module.shared_vpc[var.tgw_attachments.name].vpc_id : null
  depends_on = [
    module.shared_vpc,
    module.transit_gateway
  ]
  tgw_attachments = merge(
    var.tgw_attachments,
    {
      transit_gateway_id = var.tgw_attachments.transit_gateway_id != null ? var.tgw_attachments.transit_gateway_id : module.transit_gateway[0].transit_gateway_id
      subnet_ids = compact([
        module.shared_vpc[var.tgw_attachments.name].private_subnet.sbnt1.primary_subnet_id, # FYI you can only have one subnet per az for transit gateway attachments. So only using primary subnets here
        module.shared_vpc[var.tgw_attachments.name].private_subnet.sbnt1.secondary_subnet_id
      ])
      name = var.tgw_attachments.name
    }
  )
}
#--------------------------------------------------------------------
# Transit Gateway route table - Creates Transit Gateway route tables
#--------------------------------------------------------------------
module "transit_gateway_route_table" {
  source   = "git::https://github.com/njibrigthain100/Cognitech-terraform-iac-modules.git//terraform/modules/Transit-gateway-route-table?ref=v1.1.17"
  for_each = var.tgw_route_table != null ? { for rt in var.tgw_route_table : rt.key => rt } : {}
  common   = var.common
  depends_on = [
    module.shared_vpc,
    module.transit_gateway
  ]
  tgw_route_table = {
    name   = each.value.name
    tgw_id = each.value.tgw_id != null ? each.value.tgw_id : module.transit_gateway[0].transit_gateway_id
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
    module.shared_vpc,
    module.transit_gateway,
    module.transit_gateway_route_table
  ]
  tgw_association = {
    name = each.value.name
    attachment_id = each.value.attachment_id != null ? each.value.attachment_id : (
      each.value.attachment_name != null ?
      module.transit_gateway_attachment[0].tgw_attachment_id :
      module.transit_gateway_attachment[0].tgw_attachment_id
    )
    route_table_id = each.value.route_table_id != null ? each.value.route_table_id : (
      each.value.route_table_key != null ?
      module.transit_gateway_route_table[each.value.route_table_key].tgw_rtb_id :
      each.value.route_table_name != null ?
      module.transit_gateway_route_table[each.value.route_table_name].tgw_rtb_id :
      values(module.transit_gateway_route_table)[0].tgw_rtb_id
    )
  }
}

#--------------------------------------------------------------------
# Transit Gateway routes - Creates Transit Gateway routes for shared services
#--------------------------------------------------------------------
module "transit_gateway_route" {
  source   = "git::https://github.com/njibrigthain100/Cognitech-terraform-iac-modules.git//terraform/modules/Transit-gateway-routes?ref=v1.1.17"
  for_each = var.tgw_routes != null ? { for route in var.tgw_routes : route.key => route } : {}
  common   = var.common
  depends_on = [
    module.shared_vpc,
  ]
  tgw_routes = {
    name                   = each.value.name
    blackhole              = each.value.blackhole
    destination_cidr_block = each.value.destination_cidr_block
    attachment_id          = each.value.blackhole == false ? (each.value.attachment_id != null ? each.value.attachment_id : module.transit_gateway_attachment[0].tgw_attachment_id) : null
    route_table_id = each.value.route_table_id != null ? each.value.route_table_id : (
      each.value.route_table_key != null ?
      module.transit_gateway_route_table[each.value.route_table_key].tgw_rtb_id :
      each.value.route_table_name != null ?
      module.transit_gateway_route_table[each.value.route_table_name].tgw_rtb_id :
      values(module.transit_gateway_route_table)[0].tgw_rtb_id
    )
  }
}

# #--------------------------------------------------------------------
# # Transit Gateway subnet routes - Creates Transit Gateway subnet routes for subnets
# #--------------------------------------------------------------------
module "transit_gateway_subnet_route" {
  source   = "git::https://github.com/njibrigthain100/Cognitech-terraform-iac-modules.git//terraform/modules/Transit-gateway-subnet-route?ref=v1.1.18"
  for_each = var.tgw_subnet_route != null ? { for route in var.tgw_subnet_route : route.name => route } : {}
  common   = var.common
  depends_on = [
    module.shared_vpc,
    module.transit_gateway
  ]
  tgw_subnet_route = {
    route_table_id     = each.value.create_public_route ? module.shared_vpc[each.value.vpc_name].public_routes[each.value.subnet_name].public_route_table_id : module.shared_vpc[each.value.vpc_name].private_routes[each.value.subnet_name].private_route_table_id
    transit_gateway_id = each.value.transit_gateway_id != null ? each.value.transit_gateway_id : module.transit_gateway[0].transit_gateway_id
    cidr_block         = each.value.cidr_block
    subnet_name        = each.value.subnet_name
  }
}

