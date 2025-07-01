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
# Creates replication Rules for S3 buckets
#--------------------------------------------------------------------
module "s3_replication_rules" {
  source           = "git::https://github.com/njibrigthain100/Cognitech-terraform-iac-modules.git//terraform/modules/S3-Replication-Rules?ref=v1.1.85"
  for_each         = (var.s3_replication_rules != null) ? { for item in var.s3_replication_rules : item.name => item } : {}
  common           = var.common
  replication_rule = each.value
}


