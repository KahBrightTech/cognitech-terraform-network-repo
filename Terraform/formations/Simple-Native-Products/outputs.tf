#-------------------------------------------------------
# IAM outputs
#-------------------------------------------------------
output "IAM_roles" {
  description = "IAM roles and policies details"
  value       = module.iam_roles
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