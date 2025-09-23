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
  region_context     = "primary"
  deploy_globally    = "true"
  internal           = "private"
  external           = "public"
  region             = local.region_context == "primary" ? include.cloud.locals.regions.use1.name : include.cloud.locals.regions.usw2.name
  region_prefix      = local.region_context == "primary" ? include.cloud.locals.region_prefix.primary : include.cloud.locals.region_prefix.secondary
  region_blk         = local.region_context == "primary" ? include.cloud.locals.regions.use1 : include.cloud.locals.regions.usw2
  deployment_name    = "terraform/${include.env.locals.name_abr}-${local.vpc_name}-${local.region_context}"
  cidr_blocks        = local.region_context == "primary" ? include.cloud.locals.cidr_block_use1 : include.cloud.locals.cidr_block_usw2
  state_bucket       = local.region_context == "primary" ? include.env.locals.remote_state_bucket.primary : include.env.locals.remote_state_bucket.secondary
  state_lock_table   = include.env.locals.remote_dynamodb_table
  vpc_name           = "shared-services"
  vpc_name_abr       = "shared"
  internet_cidr      = "0.0.0.0/0"
  account_id         = include.cloud.locals.account_info[include.env.locals.name_abr].number
  aws_account_name   = include.cloud.locals.account_info[include.env.locals.name_abr].name
  public_hosted_zone = "${local.vpc_name_abr}.${include.env.locals.public_domain}"

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
  source = "../../../..//formations/Simple-Native-Products"
}

#-------------------------------------------------------
# Dependencies 
#-------------------------------------------------------
dependency "shared_services" {
  config_path = "../../Shared-account/${local.region_context}"
}
#-------------------------------------------------------
# Inputs 
#-------------------------------------------------------
inputs = {
  common = {
    global           = local.deploy_globally
    account_name     = include.cloud.locals.account_info[include.env.locals.name_abr].name
    region_prefix    = local.region_prefix
    tags             = local.tags
    region           = local.region
    account_name_abr = include.env.locals.name_abr
  }

  datasync_locations = [
    # {
    #   key = "s3-nfs"
    #   s3_location = {
    #     location_type          = "S3"
    #     s3_bucket_arn          = "arn:aws:s3:::${local.aws_account_name}-${local.region_prefix}-${local.vpc_name}-datasync-bucket"
    #     subdirectory           = include.env.locals.datasync.s3.subdirectory.datasync_bucket
    #     bucket_access_role_arn = "arn:aws:iam::${local.account_id}:role/${local.aws_account_name}-${local.region_prefix}-${local.vpc_name}-datasync-role"
    #   }
    # },
    # {
    #   key = "nfs-wsl"
    #   nfs_location = {
    #     location_type   = "NFS"
    #     server_hostname = include.env.locals.datasync.nfs.server_hostname.nfs
    #     subdirectory    = include.env.locals.datasync.nfs.subdirectory.nfs
    #     on_prem_config = {
    #       agent_arns = [include.env.locals.datasync.agent_arns.int]
    #     }
    #   }
    # },
    {
      key = "smb-laptop"
      smb_location = {
        location_type   = "smb"
        server_hostname = include.env.locals.datasync.smb.server_hostname.laptop
        user            = include.env.locals.datasync.smb.user.first
        password        = include.env.locals.datasync.smb.password.first
        subdirectory    = include.env.locals.datasync.smb.subdirectory.smb
        agent_arns      = [include.env.locals.datasync.agent_arns.int]
      }
    },
    {
      key = "s3-smb"
      s3_location = {
        location_type          = "S3"
        s3_bucket_arn          = "arn:aws:s3:::${local.aws_account_name}-${local.region_prefix}-${local.vpc_name}-datasync-bucket"
        subdirectory           = include.env.locals.datasync.s3.subdirectory.smb
        bucket_access_role_arn = dependency.shared_services.outputs.IAM_roles.shared-services-datasync.iam_role_arn
      }
    }
  ]
  datasync_tasks = [
    # {
    #   key                         = "nfs-to-s3"
    #   create_cloudwatch_log_group = true
    #   cloudwatch_log_group_name   = "nfstos3"
    #   task = {
    #     name            = "${local.vpc_name}-nfs-to-s3"
    #     source_key      = "nfs-wsl"
    #     destination_key = "s3-nfs"
    #     options = {
    #       verify_mode            = "POINT_IN_TIME_CONSISTENT"
    #       overwrite_mode         = "ALWAYS"
    #       atime                  = "BEST_EFFORT"
    #       mtime                  = "PRESERVE"
    #       uid                    = "INT_VALUE"
    #       gid                    = "INT_VALUE"
    #       preserve_deleted_files = "PRESERVE"
    #       posix_permissions      = "NONE" # You have to set this if not datasync automatically selects PRESERVE
    #     }
    #     schedule_expression = "cron(0 5 ? * * *)" # Every day at 5 AM
    #   }
    # },
    {
      key                         = "smb-to-s3"
      create_cloudwatch_log_group = true
      cloudwatch_log_group_name   = "smbtos3"
      task = {
        name            = "${local.vpc_name}-smb-to-s3"
        source_key      = "smb-laptop"
        destination_key = "s3-smb"
        options = {
          verify_mode            = "POINT_IN_TIME_CONSISTENT"
          overwrite_mode         = "ALWAYS"
          atime                  = "BEST_EFFORT"
          mtime                  = "PRESERVE"
          log_level              = "TRANSFER"
          uid                    = "NONE"
          gid                    = "NONE"
          preserve_deleted_files = "PRESERVE"
          posix_permissions      = "NONE" # You have to set this if not datasync automatically selects PRESERVE
        }
        schedule_expression = "cron(0 8 ? * * *)" # Every day at 8AM
      }
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







