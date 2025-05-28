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

locals {
  route_table_ids = compact([
    module.shared_vpc[var.tgw_attachments.name].public_routes.sbnt1.public_route_table_id,
    module.shared_vpc[var.tgw_attachments.name].public_routes.sbnt2.public_route_table_id,
    try(module.shared_vpc[var.tgw_attachments.name].public_routes.sbnt3.public_route_table_id, null),
    try(module.shared_vpc[var.tgw_attachments.name].public_routes.sbnt4.public_route_table_id, null)
  ])
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
      module.shared_vpc[var.tgw_attachments.name].public_subnet.sbnt1.primary_subnet_id, # The output for the shared vpc comes from the create vpc formation hence has an object with all the variables
      module.shared_vpc[var.tgw_attachments.name].public_subnet.sbnt1.secondary_subnet_id,
      module.shared_vpc[var.tgw_attachments.name].public_subnet.sbnt2.primary_subnet_id,
      module.shared_vpc[var.tgw_attachments.name].public_subnet.sbnt2.secondary_subnet_id,
      try(module.shared_vpc[var.tgw_attachments.name].public_subnet.sbnt3.primary_subnet_id, null),
      try(module.shared_vpc[var.tgw_attachments.name].public_subnet.sbnt3.secondary_subnet_id, null),
      try(module.shared_vpc[var.tgw_attachments.name].public_subnet.sbnt4.primary_subnet_id, null),
      try(module.shared_vpc[var.tgw_attachments.name].public_subnet.sbnt4.secondary_subnet_id, null) # This will associate subnet 3 and 4 to the transit gateway if they exist
    ]
    name = var.tgw_attachments.name
  }
}

#--------------------------------------------------------------------
# Transit Gateway routes - Creates Transit Gateway routes
#--------------------------------------------------------------------

module "transit_gateway_route" {
  source = "../../modules/Transit-gateway-routes"
  common = var.common
  depends_on = [
    module.shared_vpc,
    module.transit_gateway,
    module.transit_gateway_attachment
  ]
  for_each = { for idx, route in var.tgw_routes : idx => route }
  tgw_routes = {
    name               = each.value.name
    transit_gateway_id = module.transit_gateway.transit_gateway_id
    route_table_id = compact([ # compact removes all null values from the list
      module.shared_vpc[each.value.tgw_attachment_name].public_routes.sbnt1.public_route_table_id,
      module.shared_vpc[each.value.tgw_attachment_name].public_routes.sbnt2.public_route_table_id,
      try(module.shared_vpc[each.value.tgw_attachment_name].public_routes.sbnt3.public_route_table_id, null),
      try(module.shared_vpc[each.value.tgw_attachment_name].public_routes.sbnt4.public_route_table_id, null)
    ])
    vpc_cidr_block = each.value.vpc_cidr_block
  }

}

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
