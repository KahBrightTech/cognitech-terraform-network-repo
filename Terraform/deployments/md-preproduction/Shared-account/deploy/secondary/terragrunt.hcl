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
  region_context   = "secondary"
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
      Environment = "Shared-services"
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
      private_subnets = {
        name                       = "${local.vpc_name}-pvt"
        primary_availabilty_zone   = local.region_blk.availability_zones.primary
        primary_cidr_block         = local.cidr_blocks[include.env.locals.name_abr].segments[local.vpc_name].private_subnets.primary
        secondary_availabilty_zone = local.region_blk.availability_zones.secondary
        secondary_cidr_block       = local.cidr_blocks[include.env.locals.name_abr].segments[local.vpc_name].private_subnets.secondary
      }
      public_subnets = {
        name                       = "${local.vpc_name}-pub"
        primary_availabilty_zone   = local.region_blk.availability_zones.primary
        primary_cidr_block         = local.cidr_blocks[include.env.locals.name_abr].segments[local.vpc_name].public_subnets.primary
        secondary_availabilty_zone = local.region_blk.availability_zones.secondary
        secondary_cidr_block       = local.cidr_blocks[include.env.locals.name_abr].segments[local.vpc_name].public_subnets.secondary
      }
      nat_gateway = {
        name = "nat1"
        type = local.external
      }
      private_routes = {
        destination_cidr_block = "0.0.0.0/0"
      }
      public_routes = {
        destination_cidr_block = "0.0.0.0/0"
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
            include.cloud.locals.security_group_rules.locals.windows_bastion_base,
            include.cloud.locals.security_group_rules.locals.linux_bastion_base,
            []
          )
          egress = concat(
            include.cloud.locals.security_group_rules.locals.windows_bastion_base,
            include.cloud.locals.security_group_rules.locals.linux_bastion_base,
            []
          )
        },
        {
          sg_key = "alb"
          ingress = concat(
            include.cloud.locals.security_group_rules.locals.alb_base,
            []
          )
          egress = concat(
            include.cloud.locals.security_group_rules.locals.alb_base,
            []
          )
        },
        {
          sg_key = "nlb"
          ingress = concat(
            include.cloud.locals.security_group_rules.locals.nlb_base,
            []
          )
          egress = concat(
            include.cloud.locals.security_group_rules.locals.nlb_base,
            []
          )
        },
        {
          sg_key = "app"
          ingress = concat(
            include.cloud.locals.security_group_rules.locals.app_base,
            []
          )
          egress = concat(
            include.cloud.locals.security_group_rules.locals.app_base,
            []
          )
        }
      ]
    }
  ]
  transit_gateway = {
    name                            = local.vpc_name
    default_route_table_association = "enable"
    default_route_table_propagation = "enable"
    auto_accept_shared_attachments  = "disable"
    dns_support                     = "enable"
    amazon_side_asn                 = "64512"
  }
  tgw_attachments = {
    name = local.vpc_name
  }
  tgw_routes = [
    {
      name           = "dev"
      vpc_cidr_block = local.cidr_blocks[include.env.locals.name_abr].segments.dev.vpc
    },
    {
      name           = "trn"
      vpc_cidr_block = local.cidr_blocks[include.env.locals.name_abr].segments.trn.vpc
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












