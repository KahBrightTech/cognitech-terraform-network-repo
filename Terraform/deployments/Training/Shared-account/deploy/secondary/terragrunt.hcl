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
  vpc_name         = "Dev"

  # Composite variables 
  tags = merge(
    include.env.locals.tags,
    {
      Environment = "Development"
      ManagedBy   = "terraform:${local.deployment_name}"
    }
  )
}

#-------------------------------------------------------
# Source  
#-------------------------------------------------------
terraform {
  source = "../../../../..//formations/Training"
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
  Lambdas = [
    {
      function_name        = "${local.vpc_name}-start-instance"
      description          = "Lambda function to start an EC2 instance"
      runtime              = include.cloud.locals.lambda.start_instance.runtime
      handler              = include.cloud.locals.lambda.start_instance.handler
      timeout              = include.cloud.locals.lambda.start_instance.timeout
      private_bucklet_name = include.cloud.locals.lambda.start_instance.private_bucklet_name
      lamda_s3_key         = include.cloud.locals.lambda.start_instance.lamda_s3_key
      layer_description    = "Lambda Layer for shared libraries"
      layer_s3_key         = include.cloud.locals.lambda.start_instance.layer_s3_key
    },
    {
      function_name        = "${local.vpc_name}-stop-instance"
      description          = "Lambda function to stop an EC2 instance"
      runtime              = include.cloud.locals.lambda.stop_instance.runtime
      handler              = include.cloud.locals.lambda.stop_instance.handler
      timeout              = include.cloud.locals.lambda.stop_instance.timeout
      private_bucklet_name = include.cloud.locals.lambda.stop_instance.private_bucklet_name
      lamda_s3_key         = include.cloud.locals.lambda.stop_instance.lamda_s3_key
      layer_description    = "Lambda Layer for shared libraries"
      layer_s3_key         = include.cloud.locals.lambda.stop_instance.layer_s3_key
    },
    {
      function_name        = "${local.vpc_name}-User-Credentials"
      description          = "Lambda function to Verify User Credentials"
      runtime              = include.cloud.locals.lambda.user_credentials.runtime
      handler              = include.cloud.locals.lambda.user_credentials.handler
      timeout              = include.cloud.locals.lambda.user_credentials.timeout
      private_bucklet_name = include.cloud.locals.lambda.user_credentials.private_bucklet_name
      lamda_s3_key         = include.cloud.locals.lambda.user_credentials.lamda_s3_key
      layer_description    = "Lambda Layer for shared libraries"
      layer_s3_key         = include.cloud.locals.lambda.user_credentials.layer_s3_key
      env_variables = {
        SNS_TOPIC_ARN = include.env.locals.sns_topic_arn
        REGION        = local.region
      }
    }
  ]
  service_catalogs = [
    {
      name          = include.cloud.locals.service_catalogs.Training.name
      description   = include.cloud.locals.service_catalogs.Training.description
      provider_name = include.cloud.locals.service_catalogs.Training.provider_name
      products = [
        {
          name        = include.cloud.locals.service_catalogs.Training.products[0].name
          description = include.cloud.locals.service_catalogs.Training.products[0].description
          type        = "CLOUD_FORMATION_TEMPLATE"
          owner       = "Sysops"
        },
        {
          name        = include.cloud.locals.service_catalogs.Training.products[1].name
          description = include.cloud.locals.service_catalogs.Training.products[1].description
          type        = "CLOUD_FORMATION_TEMPLATE"
          owner       = "Sysops"
        }
      ]
      provisioning_artifact_parameters = [
        {
          name         = include.cloud.locals.service_catalogs.Training.provisioning_artifact_parameters[0].name
          description  = include.cloud.locals.service_catalogs.Training.provisioning_artifact_parameters[0].description
          type         = "CLOUD_FORMATION_TEMPLATE"
          template_url = include.cloud.locals.service_catalogs.Training.provisioning_artifact_parameters[0].template_url
        },
        {
          name         = include.cloud.locals.service_catalogs.Training.provisioning_artifact_parameters[1].name
          description  = include.cloud.locals.service_catalogs.Training.provisioning_artifact_parameters[1].description
          type         = "CLOUD_FORMATION_TEMPLATE"
          template_url = include.cloud.locals.service_catalogs.Training.provisioning_artifact_parameters[1].template_url
        }
      ]
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
