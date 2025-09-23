#-------------------------------------------------------
# IAM outputs
#-------------------------------------------------------
output "IAM_roles" {
  description = "IAM roles and policies details"
  value       = module.iam_roles
}

#-------------------------------------------------------
# S3 outputs
#-------------------------------------------------------
output "S3_buckets" {
  description = "S3 buckets details"
  value       = module.s3_app_bucket
}

#-------------------------------------------------------
# DataSync Locations outputs
#-------------------------------------------------------
output "datasync_locations" {
  description = "Output for DataSync Locations"
  value       = module.datasync_locations
}


#-------------------------------------------------------
# DataSync Tasks outputs
#-------------------------------------------------------
output "datasync_tasks" {
  description = "Output for DataSync Tasks"
  value       = module.datasync_tasks
}