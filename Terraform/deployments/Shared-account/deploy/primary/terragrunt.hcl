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
  deployment_name  = "terraform-${include.env.locals.name_abr}-deploy-app-base-${local.region_context}"
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
  source = "../../../..//formations/Shared-account"
}

#-------------------------------------------------------
# Inputs 
#-------------------------------------------------------
inputs = {
  common = {
    global        = local.deploy_globally
    account_name  = include.cloud.locals.account_name.Kah.name
    region_prefix = local.region_prefix
    tags          = local.tags
    region        = local.region
  }

  vpcs = [
    {
      name       = local.vpc_name
      cidr_block = local.cidr_blocks[include.env.locals.name_abr].segments.shared_services.vpc
      private_subnets = {
        name                       = "${local.vpc_name}-pvt"
        primary_availabilty_zone   = local.region_blk.availability_zones.primary
        primary_cidr_block         = local.cidr_blocks[include.env.locals.name_abr].segments.shared_services.private_subnets.primary
        secondary_availabilty_zone = local.region_blk.availability_zones.secondary
        secondary_cidr_block       = local.cidr_blocks[include.env.locals.name_abr].segments.shared_services.private_subnets.secondary
      }
      public_subnets = {
        name                       = "${local.vpc_name}-pub"
        primary_availabilty_zone   = local.region_blk.availability_zones.primary
        primary_cidr_block         = local.cidr_blocks[include.env.locals.name_abr].segments.shared_services.public_subnets.primary
        secondary_availabilty_zone = local.region_blk.availability_zones.secondary
        secondary_cidr_block       = local.cidr_blocks[include.env.locals.name_abr].segments.shared_services.public_subnets.secondary
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
    }
  ]
  transit_gateway = {
    name                            = "shared-tgw"
    default_route_table_association = "enable"
    default_route_table_propagation = "enable"
    auto_accept_shared_attachments  = "disable"
    dns_support                     = "enable"
    amazon_side_asn                 = "64512"
  }
  tgw_attachments = {
    attachment_name = local.vpc_name
  }


  # tgw_routes = [
  #   {
  #     vpc_cidr_block = local.cidr_blocks[include.env.locals.name_abr].segments.dev.vpc
  #   }
  # ]
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
