#--------------------------------------------------------------------
# Data
#--------------------------------------------------------------------
data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

data "aws_iam_roles" "admin_role" {
  name_regex  = "AWSReservedSSO_AdministratorAccess_.*"
  path_prefix = "/aws-reserved/sso.amazonaws.com/"
}

data "aws_iam_roles" "network_role" {
  name_regex  = "AWSReservedSSO_NetworkAdministrator_.*"
  path_prefix = "/aws-reserved/sso.amazonaws.com/"
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
module "transit_gateway" {
  source = "git::https://github.com/njibrigthain100/Cognitech-terraform-iac-modules.git//terraform/modules/Transit-gateway?ref=v1.1.28"
  transit_gateway = {
    vpc_name = var.vpcs.name
    common   = var.common
  }
}

#--------------------------------------------------------------------
# Transit Gateway attacments - Creates Transit Gateway attachments
#--------------------------------------------------------------------
module "transit_gateway_attachment" {
  source = "git::https://github.com/njibrigthain100/Cognitech-terraform-iac-modules.git//terraform/modules/Transit-gateway-attachments?ref=v1.1.17"
  common = var.common
  vpc_id = module.shared_vpc[var.tgw_attachments.name].vpc_id
  depends_on = [
    module.shared_vpc,
    module.transit_gateway
  ]
  tgw_attachments = {
    transit_gateway_id = module.transit_gateway.transit_gateway_id
    subnet_ids = compact([
      module.shared_vpc[var.tgw_attachments.name].private_subnet.sbnt1.primary_subnet_id,
      module.shared_vpc[var.tgw_attachments.name].private_subnet.sbnt1.secondary_subnet_id
    ])
    name = var.tgw_attachments.name
  }
}
#--------------------------------------------------------------------
# Transit Gateway route table - Creates Transit Gateway route tables
#--------------------------------------------------------------------
module "transit_gateway_route_table" {
  source = "git::https://github.com/njibrigthain100/Cognitech-terraform-iac-modules.git//terraform/modules/Transit-gateway-route-table?ref=v1.1.17"
  common = var.common
  depends_on = [
    module.shared_vpc,
    module.transit_gateway
  ]
  tgw_route_table = {
    name   = var.tgw_route_table.name
    tgw_id = module.transit_gateway.transit_gateway_id
  }
}

#--------------------------------------------------------------------
# Transit Gateway Association - Creates Transit Gateway associations
#--------------------------------------------------------------------
module "transit_gateway_association" {
  source = "git::https://github.com/njibrigthain100/Cognitech-terraform-iac-modules.git//terraform/modules/Transit-gateway-association?ref=v1.1.18"
  common = var.common
  depends_on = [
    module.shared_vpc,
    module.transit_gateway,
    module.transit_gateway_route_table
  ]
  tgw_association = {
    attachment_id  = module.transit_gateway_attachment.tgw_attachment_id
    route_table_id = module.transit_gateway_route_table.tgw_rtb_id
  }
}
#--------------------------------------------------------------------
# Transit Gateway routes - Creates Transit Gateway routes
#--------------------------------------------------------------------
# module "transit_gateway_route" {
#   source   = "git::https://github.com/njibrigthain100/Cognitech-terraform-iac-modules.git//terraform/modules/Transit-gateway-routes?ref=v1.1.17"
#   for_each = var.tgw_routes != null ? { for route in var.tgw_routes : route.name => route } : {}
#   common   = var.common
#   depends_on = [
#     module.shared_vpc,
#     module.transit_gateway
#   ]
#   tgw_routes = {
#     name                   = each.value.name
#     blackhole              = false
#     destination_cidr_block = each.value.destination_cidr_block
#     attachment_id          = module.transit_gateway_attachment.tgw_attachment_id
#     route_table_id         = module.transit_gateway_route_table.tgw_rtb_id
#   }
# }
# #--------------------------------------------------------------------
# # Transit Gateway subnet routes - Creates Transit Gateway subnet routes
# #--------------------------------------------------------------------
# module "transit_gateway_subnet_route" {
#   source   = "git::https://github.com/njibrigthain100/Cognitech-terraform-iac-modules.git//terraform/modules/Transit-gateway-subnet-route?ref=v1.1.18"
#   for_each = var.tgw_subnet_route != null ? { for route in var.tgw_subnet_route : route.name => route } : {}
#   common   = var.common
#   depends_on = [
#     module.shared_vpc,
#     module.transit_gateway
#   ]
#   tgw_subnet_route = {
#     route_table_id     = module.transit_gateway_route_table.tgw_rtb_id
#     transit_gateway_id = module.transit_gateway.transit_gateway_id
#     cidr_block         = each.value.destination_cidr_block
#   }
# }

#--------------------------------------------------------------------
# S3 Private app bucket
#--------------------------------------------------------------------

module "s3_app_bucket" {
  source   = "git::https://github.com/njibrigthain100/Cognitech-terraform-iac-modules.git//terraform/modules/S3-Private-bucket?ref=v1.1.1"
  for_each = (var.s3_private_buckets != null) ? { for item in var.s3_private_buckets : item.name => item } : {}
  common   = var.common
  s3 = {
    name              = each.value.name
    description       = each.value.description
    enable_versioning = each.value.enable_versioning
    policy            = each.value.policy
  }
}
