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
  deployment_name    = "terraform/${include.env.locals.repo_name}-${local.aws_account_name}-${local.deployment}-${local.native_resource}-${local.region_context}"
  cidr_blocks        = local.region_context == "primary" ? include.cloud.locals.cidr_block_use1 : include.cloud.locals.cidr_block_usw2
  state_bucket       = local.region_context == "primary" ? include.env.locals.remote_state_bucket.primary : include.env.locals.remote_state_bucket.secondary
  state_lock_table   = include.env.locals.remote_dynamodb_table
  internet_cidr      = "0.0.0.0/0"
  account_id         = include.cloud.locals.account_info[include.env.locals.name_abr].number
  aws_account_name   = include.cloud.locals.account_info[include.env.locals.name_abr].name
  public_hosted_zone = "${local.vpc_name_abr}.${include.env.locals.public_domain}"
  deployment         = "Native-products"
  ## Updates these variables as per the product/service
  vpc_name        = "shared-services"
  vpc_name_abr    = "shared"
  native_resource = "datasync"
  laptop_ip       = "69.143.134.56/32"
  Misc_tags = {
    "PrivateHostedZone" = "shared.cognitech.com"
    "PublicHostedZone"  = "cognitech.com"
  }

  # Composite variables 
  tags = merge(
    include.env.locals.tags,
    {
      Environment = "native-services"
      ManagedBy   = "terraform:${local.deployment_name}"
    }
  )
}
#-------------------------------------------------------
# Source  
#-------------------------------------------------------
terraform {
  source = "../../../.. //formations/Simple-Native-Products"
}

#-------------------------------------------------------
# Dependencies 
#-------------------------------------------------------
dependency "shared_services" {
  config_path = "../../../Shared-account/${local.region_context}"
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

  security_groups = [
    {
      key         = local.native_resource
      name        = "${local.vpc_name}-${local.native_resource}"
      description = "standard ${local.vpc_name} ${local.native_resource} security group"
      vpc_name    = local.vpc_name
    }
  ]

  security_group_rules = [
    {
      sg_key = "${local.native_resource}"
      ingress = [
        {
          key         = "ingress-443-laptop_ip"
          cidr_ipv4   = local.laptop_ip
          description = "BASE - nbound traffic from laptop IP on tcp port 443"
          from_port   = 443
          to_port     = 443
          ip_protocol = "tcp"
        },
        {
          key         = "ingress-1024-1064-laptop_ip"
          cidr_ipv4   = local.laptop_ip
          description = "BASE - Inbound traffic from laptop IP on tcp port 1024-1064"
          from_port   = 1024
          to_port     = 1064
          ip_protocol = "tcp"
        },
      ]
      egress = [
        {
          key         = "egress-all-traffic-bastion-sg"
          cidr_ipv4   = "0.0.0.0/0"
          description = "BASE - Outbound all traffic from Bastion SG to Internet"
          ip_protocol = "-1"
        }
      ]
    }
  ]

  iam_roles = [
    # {
    #   name               = "${local.vpc_name}-datasync"
    #   description        = "IAM Role for ${local.vpc_name} DataSync"
    #   path               = "/"
    #   assume_role_policy = "${include.cloud.locals.repo.root}/iam_policies/datasync_trust_policy.json"
    #   policy = {
    #     name        = "${local.vpc_name}-datasync"
    #     description = "IAM policy for ${local.vpc_name} DataSync"
    #     policy      = "${include.cloud.locals.repo.root}/iam_policies/iam_role_for_datasync.json"
    #   }
    # }
  ]

  vpc_endpoints = [
    {
      vpc_id            = dependency.shared_services.outputs.Account_products[local.vpc_name].vpc_id
      service_name      = "com.amazonaws.${local.region}.datasync"
      endpoint_name     = "${local.vpc_name}-datasync"
      vpc_endpoint_type = "Interface"
      subnet_ids = [
        dependency.shared_services.outputs.Account_products[local.vpc_name].public_subnet.sbnt1.primary_subnet_id,
        dependency.shared_services.outputs.Account_products[local.vpc_name].public_subnet.sbnt1.secondary_subnet_id
      ]
      security_group_ids = ["local.native_resource"]
    }
  ]
  ec2_instances = [
    {
      index            = "nfs"
      name             = "nfs-server"
      backup_plan_name = "${local.aws_account_name}-${local.region_context}-continous-backup"
      name_override    = "INTPP-SHR-L-NFS-01"
      ami_config = {
        os_release_date = "AL2023"
      }
      associate_public_ip_address = true
      instance_type               = "t3.large"
      iam_instance_profile        = dependency.shared_services.outputs.ec2_profiles[local.vpc_name].iam_profiles.name
      associate_public_ip_address = true
      key_name                    = dependency.shared_services.outputs.ec2_key_pairs["${local.vpc_name}-key-pair"].name
      custom_tags = merge(
        local.Misc_tags,
        {
          "Name"       = "INTPP-SHR-L-NFS-01"
          "DNS_Prefix" = "nfs01"
          "CreateUser" = "True"
        }
      )
      ebs_device_volume = []
      ebs_root_volume = {
        volume_size           = 30
        volume_type           = "gp3"
        delete_on_termination = true
      }
      subnet_id     = dependency.shared_services.outputs.Account_products[local.vpc_name].public_subnet.sbnt1.primary_subnet_id
      Schedule_name = "nfs-server-schedule"
      security_group_ids = [
        dependency.shared_services.outputs.Account_products[local.vpc_name].security_group.app.id
      ]
      hosted_zones = {
        name    = "nfs01.${dependency.shared_services.outputs.Account_products[local.vpc_name].zones.shared.zone_name}"
        zone_id = dependency.shared_services.outputs.Account_products[local.vpc_name].zones.shared.zone_id
        type    = "A"
      }
    },
    {
      index            = "smb1"
      name             = "smb1-server"
      backup_plan_name = "${local.aws_account_name}-${local.region_context}-continous-backup"
      name_override    = "INTPP-SHR-W-SSMB-01"
      ami_config = {
        os_release_date  = "W22"
        os_base_packages = "BASE"
      }
      associate_public_ip_address = true
      instance_type               = "t3.large"
      iam_instance_profile        = dependency.shared_services.outputs.ec2_profiles[local.vpc_name].iam_profiles.name
      associate_public_ip_address = true
      key_name                    = dependency.shared_services.outputs.ec2_key_pairs["${local.vpc_name}-key-pair"].name
      custom_tags = merge(
        local.Misc_tags,
        {
          "Name"         = "INTPP-SHR-W-SSMB-01"
          "DNS_Prefix"   = "ssmb01"
          "CreateUser"   = "True"
          "WinRMInstall" = "True"
        }
      )
      ebs_device_volume = []
      ebs_root_volume = {
        volume_size           = 30
        volume_type           = "gp3"
        delete_on_termination = true
      }
      subnet_id     = dependency.shared_services.outputs.Account_products[local.vpc_name].public_subnet.sbnt1.primary_subnet_id
      Schedule_name = "ansible-server-schedule"
      security_group_ids = [
        dependency.shared_services.outputs.Account_products[local.vpc_name].security_group.app.id
      ]
      hosted_zones = {
        name    = "ssmb01.${dependency.shared_services.outputs.Account_products[local.vpc_name].zones.shared.zone_name}"
        zone_id = dependency.shared_services.outputs.Account_products[local.vpc_name].zones.shared.zone_id
        type    = "A"
      }
    }
  ]
  # datasync_locations = [
  #   # {
  #   #   key = "s3-nfs"
  #   #   s3_location = {
  #   #     location_type          = "S3"
  #   #     s3_bucket_arn          = "arn:aws:s3:::${local.aws_account_name}-${local.region_prefix}-${local.vpc_name}-datasync-bucket"
  #   #     subdirectory           = include.env.locals.datasync.s3.subdirectory.datasync_bucket
  #   #     bucket_access_role_arn = "arn:aws:iam::${local.account_id}:role/${local.aws_account_name}-${local.region_prefix}-${local.vpc_name}-datasync-role"
  #   #   }
  #   # },
  #   # {
  #   #   key = "nfs-wsl"
  #   #   nfs_location = {
  #   #     location_type   = "NFS"
  #   #     server_hostname = include.env.locals.datasync.nfs.server_hostname.nfs
  #   #     subdirectory    = include.env.locals.datasync.nfs.subdirectory.nfs
  #   #     on_prem_config = {
  #   #       agent_arns = [include.env.locals.datasync.agent_arns.int]
  #   #     }
  #   #   }
  #   # },
  #   {
  #     key = "smb-laptop"
  #     smb_location = {
  #       location_type   = "smb"
  #       server_hostname = include.env.locals.datasync.smb.server_hostname.laptop
  #       user            = include.env.locals.datasync.smb.user.first
  #       password        = include.env.locals.datasync.smb.password.first
  #       subdirectory    = include.env.locals.datasync.smb.subdirectory.smb
  #       agent_arns      = [include.env.locals.datasync.agent_arns.int]
  #     }
  #   },
  #   {
  #     key = "s3-smb"
  #     s3_location = {
  #       location_type          = "S3"
  #       s3_bucket_arn          = dependency.shared_services.outputs.S3_buckets.shared-services-datasync-bucket.arn
  #       subdirectory           = include.env.locals.datasync.s3.subdirectory.smb
  #       bucket_access_role_arn = dependency.shared_services.outputs.IAM_roles.shared-services-datasync.iam_role_arn
  #     }
  #   }
  # ]
  # datasync_tasks = [
  #   # {
  #   #   key                         = "nfs-to-s3"
  #   #   create_cloudwatch_log_group = true
  #   #   cloudwatch_log_group_name   = "nfstos3"
  #   #   task = {
  #   #     name            = "${local.vpc_name}-nfs-to-s3"
  #   #     source_key      = "nfs-wsl"
  #   #     destination_key = "s3-nfs"
  #   #     options = {
  #   #       verify_mode            = "POINT_IN_TIME_CONSISTENT"
  #   #       overwrite_mode         = "ALWAYS"
  #   #       atime                  = "BEST_EFFORT"
  #   #       mtime                  = "PRESERVE"
  #   #       uid                    = "INT_VALUE"
  #   #       gid                    = "INT_VALUE"
  #   #       preserve_deleted_files = "PRESERVE"
  #   #       posix_permissions      = "NONE" # You have to set this if not datasync automatically selects PRESERVE
  #   #     }
  #   #     schedule_expression = "cron(0 5 ? * * *)" # Every day at 5 AM
  #   #   }
  #   # },
  #   {
  #     key                         = "smb-to-s3"
  #     create_cloudwatch_log_group = true
  #     cloudwatch_log_group_name   = "smbtos3"
  #     task = {
  #       name            = "${local.vpc_name}-smb-to-s3"
  #       source_key      = "smb-laptop"
  #       destination_key = "s3-smb"
  #       options = {
  #         verify_mode            = "POINT_IN_TIME_CONSISTENT"
  #         overwrite_mode         = "ALWAYS"
  #         atime                  = "BEST_EFFORT"
  #         mtime                  = "PRESERVE"
  #         log_level              = "TRANSFER"
  #         uid                    = "NONE"
  #         gid                    = "NONE"
  #         preserve_deleted_files = "PRESERVE"
  #         posix_permissions      = "NONE" # You have to set this if not datasync automatically selects PRESERVE
  #       }
  #       schedule_expression = "cron(0 8 ? * * *)" # Every day at 8AM
  #     }
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







