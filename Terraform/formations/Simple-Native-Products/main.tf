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
# Target groups 
#--------------------------------------------------------------------
module "target_groups" {
  source = "git::https://github.com/njibrigthain100/Cognitech-terraform-iac-modules.git//terraform/modules/Target-groups?ref=v1.3.9"
  #for_each     = (var.target_groups != null) ? { for item in var.target_groups : (item.key != null ? item.key : item.name) => item } : {}
  for_each     = (var.target_groups != null) ? { for item in var.target_groups : item.name => item } : {}
  common       = var.common
  target_group = each.value
}

#--------------------------------------------------------------------
# EC2 - Creates ec2 instances
#--------------------------------------------------------------------
module "ec2_instance" {
  source   = "git::https://github.com/njibrigthain100/Cognitech-terraform-iac-modules.git//terraform/modules/EC2-instance?ref=v1.3.34"
  for_each = (var.ec2_instances != null) ? { for item in var.ec2_instances : item.index => item } : {}
  common   = var.common
  ec2 = merge(
    each.value,
    {
      target_group_arns = (each.value.attach_tg != null) ? [
        for item in each.value.attach_tg :
        module.target_groups[item].target_group_arn
      ] : null
    }
  )
}


#--------------------------------------------------------------------
# Route 53 - Creates  DNS records 
#--------------------------------------------------------------------
module "hosted_zones" {
  source   = "git::https://github.com/njibrigthain100/Cognitech-terraform-iac-modules.git//terraform/modules/Route-53-records?ref=v1.1.81"
  for_each = (var.ec2_instances != null) ? { for item in var.ec2_instances : item.index => item if item.hosted_zones != null } : {}
  common   = var.common
  dns_record = merge(
    each.value.hosted_zones,
    {
      records = [module.ec2_instance[each.key].private_ip]
    }
  )
}

#--------------------------------------------------------------------
# DataSync Locations (Source and Destination)
#--------------------------------------------------------------------
module "datasync_locations" {
  source   = "git::https://github.com/njibrigthain100/Cognitech-terraform-iac-modules.git//terraform/modules/Datasync-locations?ref=v1.3.55"
  for_each = (var.datasync_locations != null) ? { for item in var.datasync_locations : item.key => item } : {}
  common   = var.common
  datasync = each.value
  depends_on = [
    module.iam_roles,
    module.s3_app_bucket
  ]
}

#--------------------------------------------------------------------
# DataSync Tasks
#--------------------------------------------------------------------
module "datasync_tasks" {
  source   = "git::https://github.com/njibrigthain100/Cognitech-terraform-iac-modules.git//terraform/modules/Datasync-Tasks?ref=v1.3.58"
  for_each = (var.datasync_tasks != null) ? { for item in var.datasync_tasks : item.key => item if item.task != null } : {}
  common   = var.common
  datasync = merge(
    each.value,
    {
      task = merge(
        each.value.task,
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
    }
  )
  depends_on = [
    module.datasync_locations,
    module.iam_roles,
    module.s3_app_bucket
  ]
}

#--------------------------------------------------------------------
# AWS VPC Endpoints
#--------------------------------------------------------------------
module "vpc_endpoints" {
  source   = "git::https://github.com/njibrigthain100/Cognitech-terraform-iac-modules.git//terraform/modules/VPCEndpoints?ref=v1.3.61"
  for_each = (var.vpc_endpoints && var.vpc_endpoints.create_vpc_endpoints != null) ? { for item in var.vpc_endpoints : item.key => item } : {}
  common   = var.common
  vpc_endpoints = merge(
    each.value,
    {
      security_group_ids = each.value.security_group_keys != null ? [
        for sg_key in each.value.security_group_keys : module.security_groups[sg_key].security_group_id
      ] : each.value.security_group_ids
    }
  )
}

#----------------------------------------------------------------
# Security Groups
#--------------------------------------------------------------------
module "security_groups" {
  source   = "git::https://github.com/njibrigthain100/Cognitech-terraform-iac-modules.git//terraform/modules/Security-group?ref=v1.1.28"
  for_each = var.security_groups != null && var.vpc_endpoints.create_vpc_endpoints != null ? { for item in var.security_groups : item.key => item } : {}
  common   = var.common
  security_group = {
    name                         = each.value.name
    vpc_id                       = each.value.vpc_id
    name_prefix                  = each.value.name_prefix
    description                  = each.value.description
    security_group_egress_rules  = each.value.egress
    security_group_ingress_rules = each.value.ingress
    vpc_name                     = each.value.vpc_name
  }

}

#--------------------------------------------------------------------
# Security Group Rules
#--------------------------------------------------------------------
module "security_group_rules" {
  source   = "git::https://github.com/njibrigthain100/Cognitech-terraform-iac-modules.git//terraform/modules/Security-group-rules?ref=v1.1.1"
  for_each = var.security_group_rules != null && var.vpc_endpoints.create_vpc_endpoints != null ? { for item in var.security_group_rules : item.sg_key => item } : {}
  common   = var.common
  security_group = {
    security_group_id = module.security_groups[each.value.sg_key].security_group_id
    egress_rules = [
      for item in coalesce(each.value.egress, []) : (
        item.target_sg_key != null ? merge(
          item,
          {
            target_sg_id = module.security_groups[item.target_sg_key].security_group_id,
            cidr_ipv4    = null,
            cidr_ipv6    = null
          }
        ) : item
      )
    ]
    ingress_rules = [
      for item in coalesce(each.value.ingress, []) : (
        item.source_sg_key != null ? merge(
          item,
          {
            source_sg_id   = module.security_groups[item.source_sg_key].security_group_id,
            cidr_ipv4      = null,
            cidr_ipv6      = null,
            prefix_list_id = null
          }
        ) : item
      )
    ]
  }
}
