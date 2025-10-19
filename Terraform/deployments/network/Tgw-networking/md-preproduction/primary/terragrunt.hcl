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
  deployment_name  = "terraform/${include.env.locals.repo_name}-${local.aws_account_name}-${local.deployment}-${local.aws_account_name}-${local.region_context}"
  cidr_blocks      = local.region_context == "primary" ? include.cloud.locals.cidr_block_use1 : include.cloud.locals.cidr_block_usw2
  state_bucket     = local.region_context == "primary" ? include.env.locals.remote_state_bucket.primary : include.env.locals.remote_state_bucket.secondary
  state_lock_table = include.env.locals.remote_dynamodb_table
  ## Updates these variables as per the product/service
  deployment       = "Tgw-networking"
  aws_account_name = include.cloud.locals.account_info["mdpp"].name
  # vpc_name_abr     = "shared"
  # Composite variables 
  tags = merge(
    include.env.locals.tags,
    {
      ManagedBy = "terraform:${local.deployment_name}"
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
  source = "../../../../..//formations/Tgw-networking"
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

  tgw_route_table = [
    {
      key    = "shared-rtb"
      name   = "${local.aws_account_name}-shared-rtb"
      tgw_id = dependency.shared_services.outputs.transit_gateway.transit_gateway_id
    }
  ]
  tgw_association = [
    {
      key             = "shared-assoc"
      attachment_id   = local.cidr_blocks["mdpp"].segments["shared-services"].tgw_attachment
      route_table_key = "shared-rtb"
    }
  ]
  tgw_routes = [
    {
      key                    = "shared-rt"
      name                   = "shared-rt"
      blackhole              = false
      attachment_id          = local.cidr_blocks["mdp"].segments["shared-services"].tgw_attachment # Destination attachment
      destination_cidr_block = local.cidr_blocks["mdp"].segments["shared-services"].vpc # Destination CIDR
      route_table_key        = "shared-rtb"
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
