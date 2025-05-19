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
  vpc_name         = "uat"

  # Composite variables 
  tags = merge(
    include.env.locals.tags,
    {
      Environment = "uat"
      ManagedBy   = "terraform:${local.deployment_name}"
    }
  )
}

#-------------------------------------------------------
# Source  
#-------------------------------------------------------
terraform {
  source = "../../../../..//formations/Simple-network"
}
#-------------------------------------------------------
# Inputs 
#-------------------------------------------------------
inputs = {
  common = {
    global        = local.deploy_globally
    account_name  = include.cloud.locals.account_name.TRN.Preprod.name
    region_prefix = local.region_prefix
    tags          = local.tags
    region        = local.region
  }
  vpc = {
    name       = local.vpc_name
    cidr_block = local.cidr_blocks[include.env.locals.name_abr].segments[local.vpc_name].vpc
    public_subnets = [
      {
        name                       = "pvt1"
        primary_availabilty_zone   = local.region_blk.availability_zones.primary
        primary_cidr_block         = local.cidr_blocks[include.env.locals.name_abr].segments[local.vpc_name].public_subnets.pvt1.primary
        secondary_availabilty_zone = local.region_blk.availability_zones.secondary
        secondary_cidr_block       = local.cidr_blocks[include.env.locals.name_abr].segments[local.vpc_name].public_subnets.pvt1.secondary
      },
      {
        name                       = "pvt2"
        primary_availabilty_zone   = local.region_blk.availability_zones.primary
        primary_cidr_block         = local.cidr_blocks[include.env.locals.name_abr].segments[local.vpc_name].public_subnets.pvt2.primary
        secondary_availabilty_zone = local.region_blk.availability_zones.secondary
        secondary_cidr_block       = local.cidr_blocks[include.env.locals.name_abr].segments[local.vpc_name].public_subnets.pvt2.secondary
      }
    ]
    private_subnets = [
      {
        name                       = "pvt1"
        primary_availabilty_zone   = local.region_blk.availability_zones.primary
        primary_cidr_block         = local.cidr_blocks[include.env.locals.name_abr].segments[local.vpc_name].private_subnets.pvt1.primary
        secondary_availabilty_zone = local.region_blk.availability_zones.secondary
        secondary_cidr_block       = local.cidr_blocks[include.env.locals.name_abr].segments[local.vpc_name].private_subnets.pvt1.secondary
      },
      {
        name                       = "pvt2"
        primary_availabilty_zone   = local.region_blk.availability_zones.primary
        primary_cidr_block         = local.cidr_blocks[include.env.locals.name_abr].segments[local.vpc_name].private_subnets.pvt2.primary
        secondary_availabilty_zone = local.region_blk.availability_zones.secondary
        secondary_cidr_block       = local.cidr_blocks[include.env.locals.name_abr].segments[local.vpc_name].private_subnets.pvt2.secondary
      }
    ]
    public_routes = {
      destination_cidr_block = "0.0.0.0/0"
    }
  }
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

