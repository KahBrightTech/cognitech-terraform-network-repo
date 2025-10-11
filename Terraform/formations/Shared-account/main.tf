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
  source          = "git::https://github.com/njibrigthain100/Cognitech-terraform-iac-modules.git//terraform/modules/Transit-gateway?ref=v1.3.64"
  transit_gateway = var.transit_gateway
  common          = var.common
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
    subnet_ids = compact(flatten([
      for subnet_key, subnet_value in module.shared_vpc[var.tgw_attachments.name].private_subnet : [
        try(subnet_value.primary_subnet_id, null),
        try(subnet_value.secondary_subnet_id, null),
        try(subnet_value.tertiary_subnet_id, null),
        try(subnet_value.quaternary_subnet_id, null)
      ]
    ]))
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
# Transit Gateway routes - Creates Transit Gateway routes for shared services
#--------------------------------------------------------------------
module "transit_gateway_route" {
  source   = "git::https://github.com/njibrigthain100/Cognitech-terraform-iac-modules.git//terraform/modules/Transit-gateway-routes?ref=v1.1.17"
  for_each = var.tgw_routes != null ? { for route in var.tgw_routes : route.name => route } : {}
  common   = var.common
  depends_on = [
    module.shared_vpc,
  ]
  tgw_routes = {
    name                   = each.value.name
    blackhole              = each.value.blackhole
    destination_cidr_block = each.value.destination_cidr_block
    attachment_id          = each.value.blackhole == false ? module.transit_gateway_attachment.tgw_attachment_id : null
    route_table_id         = module.transit_gateway_route_table.tgw_rtb_id
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
    transit_gateway_id = module.transit_gateway.transit_gateway_id
    cidr_block         = each.value.cidr_block
    subnet_name        = each.value.subnet_name
  }
}


#--------------------------------------------------------------------
# Creates ram resources
#--------------------------------------------------------------------
module "ram" {
  source   = "git::https://github.com/njibrigthain100/Cognitech-terraform-iac-modules.git//terraform/modules/RAM?ref=v1.3.66"
  for_each = var.transit_gateway != null && var.transit_gateway.ram != null && var.transit_gateway.ram.enabled == true ? { (var.transit_gateway.ram.key) = var.transit_gateway.ram } : {}
  common   = var.common
  depends_on = [
    module.transit_gateway
  ]
  ram = {
    key                       = each.value.key
    enabled                   = each.value.enabled
    share_name                = each.value.share_name
    allow_external_principals = each.value.allow_external_principals
    resource_arns             = [module.transit_gateway.tgw_arn]
    principals                = each.value.principals
  }
}

#--------------------------------------------------------------------
# S3 Private app bucket
#--------------------------------------------------------------------
module "s3_app_bucket" {
  source   = "git::https://github.com/njibrigthain100/Cognitech-terraform-iac-modules.git//terraform/modules/S3-Private-bucket?ref=v1.3.7"
  for_each = (var.s3_private_buckets != null) ? { for item in var.s3_private_buckets : item.name => item } : {}
  common   = var.common
  s3 = merge(
    {
      name              = each.value.name
      description       = each.value.description
      enable_versioning = each.value.enable_versioning
      replication       = each.value.replication != null ? each.value.replication : null
      encryption        = each.value.encryption != null ? each.value.encryption : null
      objects           = each.value.objects != null ? each.value.objects : null
    },
    (each.value.enable_bucket_policy != false && each.value.policy != null) ? { policy = each.value.policy } : {}
  )
}



#--------------------------------------------------------------------
# IAM Roles and Policies
#--------------------------------------------------------------------
module "iam_roles" {
  source   = "git::https://github.com/njibrigthain100/Cognitech-terraform-iac-modules.git//terraform/modules/IAM-Roles?ref=v1.1.76"
  for_each = (var.iam_roles != null) ? { for item in var.iam_roles : item.name => item } : {}
  common   = var.common
  iam_role = each.value
}

#--------------------------------------------------------------------
# EC2 instance profiles
#--------------------------------------------------------------------
module "ec2_profiles" {
  source       = "git::https://github.com/njibrigthain100/Cognitech-terraform-iac-modules.git//terraform/modules/EC2-profiles?ref=v1.1.77"
  for_each     = (var.ec2_profiles != null) ? { for item in var.ec2_profiles : item.name => item } : {}
  common       = var.common
  ec2_profiles = each.value
}

#--------------------------------------------------------------------
# IAM policies
#--------------------------------------------------------------------
module "iam_policies" {
  source     = "git::https://github.com/njibrigthain100/Cognitech-terraform-iac-modules.git//terraform/modules/IAM-Policies?ref=v1.1.77"
  for_each   = (var.iam_policies != null) ? { for item in var.iam_policies : item.name => item } : {}
  common     = var.common
  iam_policy = each.value
}

#--------------------------------------------------------------------
# Creates key pairs for EC2 instances
#--------------------------------------------------------------------
module "ec2_key_pairs" {
  source   = "git::https://github.com/njibrigthain100/Cognitech-terraform-iac-modules.git//terraform/modules/EC2-key-pair?ref=v1.1.72"
  for_each = (var.key_pairs != null) ? { for item in var.key_pairs : item.name => item } : {}
  common   = var.common
  key_pair = each.value
}

#--------------------------------------------------------------------
# Createss load balancers
#--------------------------------------------------------------------
module "load_balancers" {
  source        = "git::https://github.com/njibrigthain100/Cognitech-terraform-iac-modules.git//terraform/modules/Load-Balancers?ref=v1.1.92"
  for_each      = (var.load_balancers != null) ? { for item in var.load_balancers : item.key => item } : {}
  common        = var.common
  load_balancer = each.value
}




