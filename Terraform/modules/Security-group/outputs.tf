output "security_group_id" {
  description = "Security groups ouput"
  value       = module.security_group.security_group_id
}
output "securiy_group_arn" {
  description = "Security groups ARN"
  value       = module.security_group.security_group_arn

}
