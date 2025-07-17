
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

#--------------------------------------------------------------------
# VPC - Creates a VPC  to the target account
#--------------------------------------------------------------------
module "vpc" {
  source = "git::https://github.com/njibrigthain100/Cognitech-terraform-iac-modules.git//terraform/modules/vpc?ref=v1.1.1"
  vpc    = var.vpc
  common = var.common
}

#--------------------------------------------------------------------
# Subnets - Creates public subnets
#--------------------------------------------------------------------

module "public_subnets" {
  source         = "git::https://github.com/njibrigthain100/Cognitech-terraform-iac-modules.git//terraform/modules/subnets/public_subnets?ref=v1.1.28"
  for_each       = var.vpc != null && var.vpc.public_subnets != null ? { for public_subnet in var.vpc.public_subnets : public_subnet.name => public_subnet } : {}
  vpc_id         = module.vpc.vpc_id
  public_subnets = each.value
  common         = var.common
}


#--------------------------------------------------------------------
# Public Route - Creates public routes
#--------------------------------------------------------------------
module "public_route" {
  source   = "git::https://github.com/njibrigthain100/Cognitech-terraform-iac-modules.git//terraform/modules/Routes/public_routes?ref=v1.1.31"
  for_each = module.public_subnets
  vpc_id   = module.vpc.vpc_id
  common   = var.common
  public_routes = {
    public_gateway_id      = module.vpc.igw_id
    destination_cidr_block = var.vpc.public_routes.destination_cidr_block
    primary_subnet_id      = each.value.primary_subnet_id
    secondary_subnet_id    = each.value.secondary_subnet_id
    tertiary_subnet_id     = each.value.tertiary_subnet_id
    vpc_name               = var.vpc.name
    subnet_name            = each.key
  }
}

module "security_groups" {
  source   = "git::https://github.com/njibrigthain100/Cognitech-terraform-iac-modules.git//terraform/modules/Security-group?ref=v1.1.28"
  for_each = var.vpc != null ? var.vpc.security_groups != null ? { for item in var.vpc.security_groups : item.key => item } : {} : {}
  common   = var.common
  security_group = {
    name                         = each.value.name
    vpc_id                       = module.vpc.vpc_id
    name_prefix                  = each.value.name_prefix
    description                  = each.value.description
    security_group_egress_rules  = each.value.egress
    security_group_ingress_rules = each.value.ingress
    vpc_name                     = var.vpc.name
  }

}

module "security_group_rules" {
  source   = "git::https://github.com/njibrigthain100/Cognitech-terraform-iac-modules.git//terraform/modules/Security-group-rules?ref=v1.1.1"
  for_each = var.vpc != null ? var.vpc.security_group_rules != null ? { for item in var.vpc.security_group_rules : item.sg_key => item } : {} : {}
  common   = var.common
  security_group = {
    security_group_id = module.security_groups[each.value.sg_key].security_group_id
    egress_rules = [
      for item in coalesce(each.value.egress, []) : (
        item.target_sg_key != null ? merge(
          item,
          {
            target_sg_id = module.security_groups[item.target_sg_key].security_group_id,
            cidr_ipv4    = null,
            cidr_ipv6    = null
          }
        ) : item
      )
    ]
    ingress_rules = [
      for item in coalesce(each.value.ingress, []) : (
        item.source_sg_key != null ? merge(
          item,
          {
            source_sg_id   = module.security_groups[item.source_sg_key].security_group_id,
            cidr_ipv4      = null,
            cidr_ipv6      = null,
            prefix_list_id = null
          }
        ) : item
      )
    ]
  }
}

#--------------------------------------------------------------------
# Route53 Private Hosted Zones
#--------------------------------------------------------------------
module "zones" {
  source   = "git::https://github.com/njibrigthain100/Cognitech-terraform-iac-modules.git//terraform/modules/Route-53-hosted-zones?ref=v1.1.57"
  for_each = var.vpc != null ? var.vpc.route53_zones != null ? { for item in var.vpc.route53_zones : item.key => item } : {} : {}
  common   = var.common
  route53_zones = {
    name    = each.value.name
    comment = each.value.comment
    vpc_id  = each.value.private_zone ? module.vpc.vpc_id : null
  }
}

module "s3_data_bucket" {
  source = "git::https://github.com/njibrigthain100/Cognitech-terraform-iac-modules.git//terraform/modules/S3-Private-bucket?ref=v1.2.25"
  common = var.common
  s3 = {
    name        = "${var.vpc.s3.name}"
    description = var.vpc.s3.description
    policy      = var.vpc.s3.policy
  }
}









