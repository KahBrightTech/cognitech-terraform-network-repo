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
  source   = "../Simple-network"
  for_each = { for vpc in var.vpcs : vpc.name => vpc }
  vpc      = each.value
  common   = var.common
}
#--------------------------------------------------------------------
# S3 Private app bucket
#--------------------------------------------------------------------
module "s3_app_bucket" {
  source   = "git::https://github.com/njibrigthain100/Cognitech-terraform-iac-modules.git//terraform/modules/S3-Private-bucket?ref=v1.1.83"
  for_each = (var.s3_private_buckets != null) ? { for item in var.s3_private_buckets : item.name => item } : {}
  common   = var.common
  s3 = merge(
    {
      name              = each.value.name
      description       = each.value.description
      enable_versioning = each.value.enable_versioning
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
  source   = "git::https://github.com/njibrigthain100/Cognitech-terraform-iac-modules.git//terraform/modules/Load-Balancers?ref=v1.2.6"
  for_each = (var.load_balancers != null) ? { for item in var.load_balancers : item.key => item } : {}
  common   = var.common
  load_balancer = merge(
    each.value,
    {
      security_groups = [
        for sg_key in each.value.security_groups :
        module.shared_vpc[each.value.vpc_name].security_group[sg_key].id
      ]
      subnets = flatten([
        for subnet_key in each.value.subnets :
        (each.value.use_private_subnets == true) ?
        module.shared_vpc[each.value.vpc_name].private_subnet[subnet_key].subnet_ids :
        module.shared_vpc[each.value.vpc_name].public_subnet[subnet_key].subnet_ids
      ])
      subnet_mappings = (each.value.subnet_mappings != null) ? [
        for mapping in each.value.subnet_mappings : {
          subnet_id = lookup(
            module.shared_vpc[each.value.vpc_name].private_subnet[mapping.subnet_key],
            "${mapping.az_subnet_selector}_subnet_id",
            null
          )
          private_ipv4_address = mapping.private_ipv4_address
        }
      ] : []
    }
  )
}
