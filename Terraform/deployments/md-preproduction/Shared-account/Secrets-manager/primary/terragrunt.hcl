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
  source = "../../../../../..//modules/Create-secrets"
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


  secrets = [
    {
      name              = include.env.locals.secrets.primary[include.env.locals.name_abr].name
      description       = "Secrets for fsx share"
      record_folder_uid = include.env.locals.secrets.primary[include.env.locals.name_abr].record_folder_uid
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
  provider "secretsmanager" {
    credential = "${get_env("TF_VAR_KSM_CONFIG")}" 
  }
  EOF
}





