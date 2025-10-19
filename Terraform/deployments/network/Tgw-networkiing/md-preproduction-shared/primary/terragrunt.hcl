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
  region           = local.region_context == "primary" ? include.cloud.locals.regions.use1.name : include.cloud.locals.regions.usw2.name
  region_prefix    = local.region_context == "primary" ? include.cloud.locals.region_prefix.primary : include.cloud.locals.region_prefix.secondary
  region_blk       = local.region_context == "primary" ? include.cloud.locals.regions.use1 : include.cloud.locals.regions.usw2
  deployment_name  = "terraform/${include.env.locals.repo_name}-${local.aws_account_name}-${local.deployment}-${local.aws_account_name}-${local.vpc_name_abr}-${local.region_context}"
  cidr_blocks      = local.region_context == "primary" ? include.cloud.locals.cidr_block_use1 : include.cloud.locals.cidr_block_usw2
  state_bucket     = local.region_context == "primary" ? include.env.locals.remote_state_bucket.primary : include.env.locals.remote_state_bucket.secondary
  state_lock_table = include.env.locals.remote_dynamodb_table
  ## Updates these variables as per the product/service
  deployment       = "Tgw-networking"
  aws_account_name = include.cloud.locals.account_info["mdpp"].name
  vpc_name_abr     = "shared"
  # Composite variables 
  tags = merge(
    include.env.locals.tags,
    {
      ManagedBy   = "terraform:${local.deployment_name}"
    }
  )
}
#-------------------------------------------------------
# Dependencies 
#-------------------------------------------------------
dependency "shared_services" {
  config_path = "../../../Shared-account/${local.region_context}"
}
#-------------------------------------------------------
# Source  
#-------------------------------------------------------
terraform {
  source = "../../../../..//formations/Tenant-account"
}
#-------------------------------------------------------
# Inputs 
#-------------------------------------------------------
inputs = {
  common = {
    global        = local.deploy_globally
    account_name  = local.aws_account_name
    region_prefix = local.region_prefix
    tags          = local.tags
    region        = local.region
  }
  tgw_attachments = {
    name               = local.vpc_name
    transit_gateway_id = dependency.shared_services.outputs.transit_gateway.transit_gateway_id
  }

  tgw_association = {
    route_table_id = dependency.shared_services.outputs.transit_gateway_route_table.tgw_rtb_id
  }

  tgw_routes = [
    {
      name                   = "dev"
      blackhole              = false
      destination_cidr_block = local.cidr_blocks[include.env.locals.name_abr].segments.app_vpc[local.vpc_name_abr].vpc
      route_table_id         = dependency.shared_services.outputs.transit_gateway_route_table.tgw_rtb_id
    }
  ]
  tgw_subnet_route = [
    {
      name               = "shared-subnet_rt"
      cidr_block         = local.cidr_blocks[include.env.locals.name_abr].segments.shared-services.vpc
      transit_gateway_id = dependency.shared_services.outputs.transit_gateway.transit_gateway_id
      subnet_name        = include.env.locals.subnet_prefix.primary
      vpc_name           = local.vpc_name
    },
    {
      name               = "shared-subnet_rt-secondary"
      cidr_block         = local.cidr_blocks[include.env.locals.name_abr].segments.shared-services.vpc
      transit_gateway_id = dependency.shared_services.outputs.transit_gateway.transit_gateway_id
      subnet_name        = include.env.locals.subnet_prefix.secondary
      vpc_name           = local.vpc_name
    }
  ]
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
    key                  = "${local.deployment_name}/terraform.tfstate "
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
