#-------------------------------------------------------
# Includes Block 
#-------------------------------------------------------

include "cloud" {
  path   = find_in_parent_folders("locals-cloud.hcl")
  expose = true
}

include "env" {
  path   = find_in_parent_folders("locals-env.hcl")
  expose = true
}
#-------------------------------------------------------
# Locals 
#-------------------------------------------------------
locals {
  region_context   = "primary"
  deploy_globally  = "true"
  internal         = "private"
  external         = "public"
  region           = local.region_context == "primary" ? include.cloud.locals.regions.use1.name : include.cloud.locals.regions.usw2.name
  region_prefix    = local.region_context == "primary" ? include.cloud.locals.region_prefix.primary : include.cloud.locals.region_prefix.secondary
  region_blk       = local.region_context == "primary" ? include.cloud.locals.regions.use1 : include.cloud.locals.regions.usw2
  deployment_name  = "${include.env.locals.name_abr}-${local.vpc_name}-${local.region_context}"
  cidr_blocks      = local.region_context == "primary" ? include.cloud.locals.cidr_block_use1 : include.cloud.locals.cidr_block_usw2
  state_bucket     = local.region_context == "primary" ? include.env.locals.remote_state_bucket.primary : include.env.locals.remote_state_bucket.secondary
  state_lock_table = include.env.locals.remote_dynamodb_table
  vpc_name         = "shared-services"

  # Composite variables 
  tags = merge(
    include.env.locals.tags,
    {
      Environment = "shared-services"
      ManagedBy   = "terraform:${local.deployment_name}"
    }
  )
}
#-------------------------------------------------------
# Source  
#-------------------------------------------------------
terraform {
  source = "../../../../..//formations/Shared-account"
}
#-------------------------------------------------------
# Inputs 
#-------------------------------------------------------
inputs = {
  common = {
    global        = local.deploy_globally
    account_name  = include.cloud.locals.account_name.MD.Preprod.name
    region_prefix = local.region_prefix
    tags          = local.tags
    region        = local.region
  }
  vpcs = [
    {
      name       = local.vpc_name
      cidr_block = local.cidr_blocks[include.env.locals.name_abr].segments[local.vpc_name].vpc
      public_subnets = [
        {
          name                       = "sbnt1"
          primary_availabilty_zone   = local.region_blk.availability_zones.primary
          primary_cidr_block         = local.cidr_blocks[include.env.locals.name_abr].segments[local.vpc_name].public_subnets.sbnt1.primary
          secondary_availabilty_zone = local.region_blk.availability_zones.secondary
          secondary_cidr_block       = local.cidr_blocks[include.env.locals.name_abr].segments[local.vpc_name].public_subnets.sbnt1.secondary
          subnet_type                = local.external
        },
        {
          name                       = "sbnt2"
          primary_availabilty_zone   = local.region_blk.availability_zones.primary
          primary_cidr_block         = local.cidr_blocks[include.env.locals.name_abr].segments[local.vpc_name].public_subnets.sbnt2.primary
          secondary_availabilty_zone = local.region_blk.availability_zones.secondary
          secondary_cidr_block       = local.cidr_blocks[include.env.locals.name_abr].segments[local.vpc_name].public_subnets.sbnt2.secondary
          subnet_type                = local.external
        }
      ]
      private_subnets = [
        {
          name                       = "sbnt1"
          primary_availabilty_zone   = local.region_blk.availability_zones.primary
          primary_cidr_block         = local.cidr_blocks[include.env.locals.name_abr].segments[local.vpc_name].private_subnets.sbnt1.primary
          secondary_availabilty_zone = local.region_blk.availability_zones.secondary
          secondary_cidr_block       = local.cidr_blocks[include.env.locals.name_abr].segments[local.vpc_name].private_subnets.sbnt1.secondary
          subnet_type                = local.internal
        },
        {
          name                       = "sbnt2"
          primary_availabilty_zone   = local.region_blk.availability_zones.primary
          primary_cidr_block         = local.cidr_blocks[include.env.locals.name_abr].segments[local.vpc_name].private_subnets.sbnt2.primary
          secondary_availabilty_zone = local.region_blk.availability_zones.secondary
          secondary_cidr_block       = local.cidr_blocks[include.env.locals.name_abr].segments[local.vpc_name].private_subnets.sbnt2.secondary
          subnet_type                = local.internal
        }
      ]
      public_routes = {
        destination_cidr_block = "0.0.0.0/0"
      }
      private_routes = {
        destination_cidr_block = "0.0.0.0/0"
      }
      nat_gateway = {
        name = "nat"
        type = local.external
      }
      security_groups = [
        {
          key         = "bastion"
          name        = "shared-bastion"
          description = "standrad sharewd bastion security group"
        },
        {
          key         = "alb"
          name        = "shared-alb"
          description = "standard shared alb security group"
        },
        {
          key         = "app"
          name        = "shared-app"
          description = "standard shared app security group"
        },
        {
          key         = "db"
          name        = "shared-db"
          description = "standard shared db security group"
        },
        {
          key         = "nlb"
          name        = "shared-nlb"
          description = "standard shared nlb security group"
        }
      ]
      security_group_rules = [
        {
          sg_key = "bastion"
          ingress = concat(
            include.cloud.locals.security_group_rules.locals.ingress.windows_bastion_base,
            include.cloud.locals.security_group_rules.locals.ingress.linux_bastion_base,
            []
          )
          egress = concat(
            include.cloud.locals.security_group_rules.locals.egress.windows_bastion_base,
            include.cloud.locals.security_group_rules.locals.egress.linux_bastion_base,
            []
          )
        },
        {
          sg_key = "alb"
          ingress = concat(
            include.cloud.locals.security_group_rules.locals.ingress.alb_base,
            []
          )
          egress = concat(
            include.cloud.locals.security_group_rules.locals.egress.alb_base,
            []
          )
        },
        {
          sg_key = "nlb"
          ingress = concat(
            include.cloud.locals.security_group_rules.locals.ingress.nlb_base,
            []
          )
          egress = concat(
            include.cloud.locals.security_group_rules.locals.egress.nlb_base,
            []
          )
        },
        {
          sg_key = "app"
          ingress = concat(
            include.cloud.locals.security_group_rules.locals.ingress.app_base,
            []
          )
          egress = concat(
            include.cloud.locals.security_group_rules.locals.egress.app_base,
            []
          )
        }
      ]
      s3 = {
        name        = "${local.vpc_name}-data-xfer"
        description = "The bucket used for data transfers"
        policy      = "${include.cloud.locals.repo.root}/iam_policies/s3_data_policy.json"

      }
    }
  ]
  transit_gateway = {
    name                            = local.vpc_name
    default_route_table_association = "disable"
    default_route_table_propagation = "disable"
    auto_accept_shared_attachments  = "disable"
    dns_support                     = "enable"
    amazon_side_asn                 = "64512"
  }
  tgw_route_table = {
    name = local.vpc_name
  }
  tgw_attachments = {
    name = local.vpc_name
  }

  # tgw_routes = [
  #   {
  #     name                   = "dev"
  #     destination_cidr_block = local.cidr_blocks[include.env.locals.name_abr].segments.dev.vpc
  #   },
  #   {
  #     name                   = "trn"
  #     destination_cidr_block = local.cidr_blocks[include.env.locals.name_abr].segments.trn.vpc
  #   }
  # ]
  s3_private_buckets = [
    {
      name              = "${local.vpc_name}-app-bucket"
      description       = "The application bucket for different apps"
      enable_versioning = true
      policy            = "${include.cloud.locals.repo.root}/iam_policies/s3_app_policy.json"
    }
  ]
}
#-------------------------------------------------------
# State Configuration
#-------------------------------------------------------
remote_state {
  backend = "s3"
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite"
  }
  config = {
    bucket               = local.state_bucket
    bucket_sse_algorithm = "AES256"
    dynamodb_table       = local.state_lock_table
    encrypt              = true
    key                  = "${local.deployment_name}/terraform.tfstate"
    region               = local.region
  }
}
#-------------------------------------------------------
# Providers 
#-------------------------------------------------------
generate "aws-providers" {
  path      = "aws-provider.tf"
  if_exists = "overwrite"
  contents  = <<-EOF
  provider "aws" {
    region = "${local.region}"
  }
  EOF
}


