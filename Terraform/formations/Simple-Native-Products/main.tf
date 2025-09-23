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
