#--------------------------------------------------------------------
# Data
#--------------------------------------------------------------------
data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

data "aws_iam_roles" "admin_role" {
  name_regex  = "AWSReservedSSO_AdministratorAccess_.*"
  path_prefix = "/aws-reserved/sso.amazonaws.com/"
}

data "aws_iam_roles" "network_role" {
  name_regex  = "AWSReservedSSO_NetworkAdministrator_.*"
  path_prefix = "/aws-reserved/sso.amazonaws.com/"
}

module "shared_vpc" {
  source   = "../Simple-network"
  for_each = { for vpc in var.vpcs : vpc.name => vpc }
  vpc      = each.value
  common   = var.common
}
#--------------------------------------------------------------------
# S3 Private app bucket
#--------------------------------------------------------------------
module "s3_app_bucket" {
  source   = "git::https://github.com/njibrigthain100/Cognitech-terraform-iac-modules.git//terraform/modules/S3-Private-bucket?ref=v1.3.7"
  for_each = (var.s3_private_buckets != null) ? { for item in var.s3_private_buckets : item.name => item } : {}
  common   = var.common
  s3 = merge(
    {
      name              = each.value.name
      description       = each.value.description
      enable_versioning = each.value.enable_versioning
      replication       = each.value.replication != null ? each.value.replication : null
      encryption        = each.value.encryption != null ? each.value.encryption : null
      objects           = each.value.objects != null ? each.value.objects : null
    },
    (each.value.enable_bucket_policy != false && each.value.policy != null) ? { policy = each.value.policy } : {}
  )
}

#--------------------------------------------------------------------
# IAM Roles and Policies
#--------------------------------------------------------------------
module "iam_roles" {
  source   = "git::https://github.com/njibrigthain100/Cognitech-terraform-iac-modules.git//terraform/modules/IAM-Roles?ref=v1.1.76"
  for_each = (var.iam_roles != null) ? { for item in var.iam_roles : item.name => item } : {}
  common   = var.common
  iam_role = each.value
}


#--------------------------------------------------------------------
# EC2 instance profiles
#--------------------------------------------------------------------
module "ec2_profiles" {
  source       = "git::https://github.com/njibrigthain100/Cognitech-terraform-iac-modules.git//terraform/modules/EC2-profiles?ref=v1.1.77"
  for_each     = (var.ec2_profiles != null) ? { for item in var.ec2_profiles : item.name => item } : {}
  common       = var.common
  ec2_profiles = each.value
}

#--------------------------------------------------------------------
# IAM policies
#--------------------------------------------------------------------
module "iam_policies" {
  source     = "git::https://github.com/njibrigthain100/Cognitech-terraform-iac-modules.git//terraform/modules/IAM-Policies?ref=v1.1.77"
  for_each   = (var.iam_policies != null) ? { for item in var.iam_policies : item.name => item } : {}
  common     = var.common
  iam_policy = each.value
}

#--------------------------------------------------------------------
# Creates key pairs for EC2 instances
#--------------------------------------------------------------------
module "ec2_key_pairs" {
  source   = "git::https://github.com/njibrigthain100/Cognitech-terraform-iac-modules.git//terraform/modules/EC2-key-pair?ref=v1.1.72"
  for_each = (var.key_pairs != null) ? { for item in var.key_pairs : item.name => item } : {}
  common   = var.common
  key_pair = each.value
}

#--------------------------------------------------------------------
# Creates Certificates
#--------------------------------------------------------------------
module "certificates" {
  source   = "git::https://github.com/njibrigthain100/Cognitech-terraform-iac-modules.git//terraform/modules/ACM-Public-Certs?ref=v1.2.29"
  for_each = var.certificates != null ? { for item in var.certificates : item.name => item } : {}
  common   = var.common
  certificate = {
    name              = each.value.name
    domain_name       = each.value.domain_name
    validation_method = each.value.validation_method
    zone_name         = each.value.zone_name
  }
}

#--------------------------------------------------------------------
# Creates AWS Backup 
#--------------------------------------------------------------------
module "backups" {
  source   = "git::https://github.com/njibrigthain100/Cognitech-terraform-iac-modules.git//terraform/modules/AWSBackup?ref=v1.2.97"
  for_each = var.backups != null ? { for item in var.backups : item.name => item } : {}
  common   = var.common
  backup   = each.value
}

#--------------------------------------------------------------------
# Createss load balancers
#--------------------------------------------------------------------
module "load_balancers" {
  source   = "git::https://github.com/njibrigthain100/Cognitech-terraform-iac-modules.git//terraform/modules/Load-Balancers?ref=v1.2.98"
  for_each = (var.load_balancers != null) ? { for item in var.load_balancers : item.key => item } : {}
  common   = var.common
  load_balancer = merge(
    each.value,
    {
      security_groups = [
        for sg_key in each.value.security_groups :
        module.shared_vpc[each.value.vpc_name].security_group[sg_key].id
      ]
      subnets = flatten([
        for subnet_key in each.value.subnets :
        (each.value.use_private_subnets == true) ?
        module.shared_vpc[each.value.vpc_name].private_subnet[subnet_key].subnet_ids :
        module.shared_vpc[each.value.vpc_name].public_subnet[subnet_key].subnet_ids
      ])
      subnet_mappings = (each.value.subnet_mappings != null) ? [
        for mapping in each.value.subnet_mappings : {
          subnet_id = lookup(
            module.shared_vpc[each.value.vpc_name].private_subnet[mapping.subnet_key],
            "${mapping.az_subnet_selector}_subnet_id",
            null
          )
          private_ipv4_address = mapping.private_ipv4_address
        }
      ] : []
      # Set default certificate from shared VPC module when create_default_listener is true
      default_listener = (each.value.create_default_listener == true) ? merge(
        {
          port        = 443
          protocol    = "HTTPS"
          action_type = "fixed-response"
          ssl_policy  = "ELBSecurityPolicy-2016-08"
          fixed_response = {
            content_type = "text/plain"
            message_body = "Oops! The page you are looking for does not exist."
            status_code  = "200"
          }
        },
        lookup(each.value, "default_listener", {}),
        {
          certificate_arn = try(lookup(each.value, "default_listener", {}).certificate_arn, null) != null ? lookup(each.value, "default_listener", {}).certificate_arn : try(module.certificates[each.value.vpc_name].arn, null)
        }
      ) : null
    }
  )
}


#--------------------------------------------------------------------
# Creates secrets
#--------------------------------------------------------------------
module "secrets" {
  source          = "git::https://github.com/njibrigthain100/Cognitech-terraform-iac-modules.git//terraform/modules/Secrets-manager?ref=v1.2.42"
  for_each        = (var.secrets != null) ? { for item in var.secrets : item.name => item } : {}
  common          = var.common
  secrets_manager = each.value
}


#--------------------------------------------------------------------
# Creates SSM Parameters
#--------------------------------------------------------------------
module "ssm_parameters" {
  source        = "git::https://github.com/njibrigthain100/Cognitech-terraform-iac-modules.git//terraform/modules/SSM-Parameter-store?ref=v1.2.45"
  for_each      = (var.ssm_parameters != null) ? { for item in var.ssm_parameters : item.name => item } : {}
  common        = var.common
  ssm_parameter = each.value
}

#--------------------------------------------------------------------
# Target groups
#--------------------------------------------------------------------
module "target_groups" {
  source   = "git::https://github.com/njibrigthain100/Cognitech-terraform-iac-modules.git//terraform/modules/Target-groups?ref=v1.2.98"
  for_each = (var.target_groups != null) ? { for item in var.target_groups : item.key => item } : {}
  common   = var.common
  target_group = merge(
    each.value,
    {
      vpc_id = each.value.vpc_name != null ? module.shared_vpc[each.value.vpc_name].vpc_id : each.value.vpc_id
    }
  )
}

#--------------------------------------------------------------------
# ALB listeners
#--------------------------------------------------------------------
module "alb_listeners" {
  source   = "git::https://github.com/njibrigthain100/Cognitech-terraform-iac-modules.git//terraform/modules/alb-listeners?ref=v1.2.98"
  for_each = (var.alb_listeners != null) ? { for item in var.alb_listeners : item.key => item } : {}
  common   = var.common
  alb_listener = merge(
    each.value,
    {
      # Resolve load balancer ARN from the load balancer key
      alb_arn = try(
        module.load_balancers[each.value.alb_key].arn,
        each.value.alb_arn
      )
      certificate_arn = each.value.protocol == "HTTPS" ? try(
        module.certificates[each.value.vpc_name].arn,
        each.value.certificate_arn
      ) : null
      vpc_id = each.value.vpc_name != null ? module.shared_vpc[each.value.vpc_name].vpc_id : each.value.vpc_id
      target_group = each.value.target_group != null ? merge(
        each.value.target_group,
        {
          attachments = each.value.target_group.attachments != null ? each.value.target_group.attachments : []
        }
      ) : null
    }
  )
}

#--------------------------------------------------------------------
# ALB listener rules
#--------------------------------------------------------------------
module "alb_listener_rules" {
  source   = "git::https://github.com/njibrigthain100/Cognitech-terraform-iac-modules.git//terraform/modules/alb-listener-rule?ref=v1.2.98"
  for_each = (var.alb_listener_rules != null) ? { for item in var.alb_listener_rules : item.index_key => item } : {}
  common   = var.common
  rule = [
    for item in each.value.rules : merge(
      item,
      {
        listener_arn = each.value.listener_key != null ? module.alb_listeners[each.value.listener_key].alb_listener_arn : each.value.listener_arn
        target_groups = [
          for tg in item.target_groups :
          {
            arn    = tg.tg_name != null ? module.target_groups[tg.tg_name].target_group_arn : tg.arn
            weight = tg.weight
          }
        ]
      }
    )
  ]
}

#--------------------------------------------------------------------
# NLB listeners
#--------------------------------------------------------------------
module "nlb_listeners" {
  source   = "git::https://github.com/njibrigthain100/Cognitech-terraform-iac-modules.git//terraform/modules/nlb-listener?ref=v1.2.98"
  for_each = (var.nlb_listeners != null) ? { for item in var.nlb_listeners : item.key => item } : {}
  common   = var.common
  nlb_listener = merge(
    each.value,
    {
      nlb_arn = try(
        module.load_balancers[each.value.nlb_key].arn,
        each.value.nlb_arn
      )
      certificate_arn = each.value.protocol == "TLS" ? try(
        module.certificates[each.value.vpc_name].arn,
        each.value.certificate_arn
      ) : null
      vpc_id = each.value.vpc_name != null ? module.shared_vpc[each.value.vpc_name].vpc_id : each.value.vpc_id
      target_group = each.value.target_group != null ? merge(
        each.value.target_group,
        {
          attachments = each.value.target_group.attachments != null ? each.value.target_group.attachments : []
        }
      ) : null
    }
  )
}

#--------------------------------------------------------------------
# Creates SSM Document and Association
# #--------------------------------------------------------------------
module "ssm_documents" {
  source       = "git::https://github.com/njibrigthain100/Cognitech-terraform-iac-modules.git//terraform/modules/SSM-Documents?ref=v1.3.5"
  for_each     = (var.ssm_documents != null) ? { for item in var.ssm_documents : item.name => item } : {}
  common       = var.common
  ssm_document = each.value
}

#--------------------------------------------------------------------
# Creates lIAM users
#--------------------------------------------------------------------
module "iam_users" {
  source   = "git::https://github.com/njibrigthain100/Cognitech-terraform-iac-modules.git//terraform/modules/IAM-User?ref=v1.3.29"
  for_each = (var.iam_users != null) ? { for item in var.iam_users : item.name => item } : {}
  common   = var.common
  iam_user = each.value
}


#--------------------------------------------------------------------
# DataSync Locations (Source and Destination)
#--------------------------------------------------------------------
module "datasync_locations" {
  source     = "git::https://github.com/njibrigthain100/Cognitech-terraform-iac-modules.git//terraform/modules/Datasync-locations?ref=v1.3.54"
  for_each   = (var.datasync_locations != null) ? { for item in var.datasync_locations : item.key => item } : {}
  common     = var.common
  datasync   = each.value
  depends_on = [module.iam_roles]
}

#--------------------------------------------------------------------
# DataSync Tasks
#--------------------------------------------------------------------
module "datasync_tasks" {
  source   = "git::https://github.com/njibrigthain100/Cognitech-terraform-iac-modules.git//terraform/modules/Datasync-Tasks?ref=v1.3.54"
  for_each = (var.datasync_tasks != null) ? { for item in var.datasync_tasks : item.key => item if item.task != null } : {}
  common   = var.common
  datasync = merge(
    each.value,
    {
      source_location_arn = each.value.task.source_key != null ? coalesce(
        module.datasync_locations[each.value.task.source_key].s3_location_arn,
        module.datasync_locations[each.value.task.source_key].efs_location_arn,
        module.datasync_locations[each.value.task.source_key].fsx_windows_location_arn,
        module.datasync_locations[each.value.task.source_key].fsx_lustre_location_arn,
        module.datasync_locations[each.value.task.source_key].fsx_ontap_location_arn,
        module.datasync_locations[each.value.task.source_key].fsx_openzfs_location_arn,
        module.datasync_locations[each.value.task.source_key].nfs_location_arn,
        module.datasync_locations[each.value.task.source_key].smb_location_arn,
        module.datasync_locations[each.value.task.source_key].hdfs_location_arn,
        module.datasync_locations[each.value.task.source_key].object_storage_location_arn,
        module.datasync_locations[each.value.task.source_key].azure_blob_location_arn
      ) : each.value.task.source_location_arn
      destination_location_arn = each.value.task.destination_key != null ? coalesce(
        module.datasync_locations[each.value.task.destination_key].s3_location_arn,
        module.datasync_locations[each.value.task.destination_key].efs_location_arn,
        module.datasync_locations[each.value.task.destination_key].fsx_windows_location_arn,
        module.datasync_locations[each.value.task.destination_key].fsx_lustre_location_arn,
        module.datasync_locations[each.value.task.destination_key].fsx_ontap_location_arn,
        module.datasync_locations[each.value.task.destination_key].fsx_openzfs_location_arn,
        module.datasync_locations[each.value.task.destination_key].nfs_location_arn,
        module.datasync_locations[each.value.task.destination_key].smb_location_arn,
        module.datasync_locations[each.value.task.destination_key].hdfs_location_arn,
        module.datasync_locations[each.value.task.destination_key].object_storage_location_arn,
        module.datasync_locations[each.value.task.destination_key].azure_blob_location_arn
      ) : each.value.task.destination_location_arn
    }
  )
  depends_on = [
    module.datasync_locations,
    module.iam_roles
  ]
}
