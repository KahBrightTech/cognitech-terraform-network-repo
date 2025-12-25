output "Account_products" {
  description = "List of resources to be created"
  value       = module.shared_vpc
}
output "transit_gateway" {
  description = "Transit Gateway details"
  value       = length(module.transit_gateway) > 0 ? module.transit_gateway[0] : null
}
output "transit_gateway_attachment" {
  description = "Transit Gateway attachment details"
  value       = length(module.transit_gateway_attachment) > 0 ? module.transit_gateway_attachment[0] : null
}

output "transit_gateway_route_table" {
  description = "Transit Gateway route table details"
  value       = length(module.transit_gateway_route_table) > 0 ? module.transit_gateway_route_table : null
}

output "transit_gateway_association" {
  description = "Transit Gateway association details"
  value       = length(module.transit_gateway_association) > 0 ? module.transit_gateway_association[0] : null
}

output "transit_gateway_propagation" {
  description = "Transit Gateway propagation details"
  value       = length(module.transit_gateway_propagation) > 0 ? module.transit_gateway_propagation[0] : null
}
output "s3_app_bucket" {
  description = "S3 bucket details"
  value       = module.s3_app_bucket
  depends_on  = [module.shared_vpc]
}

output "IAM_roles" {
  description = "IAM roles and policies details"
  value       = module.iam_roles
}

output "ec2_profiles" {
  description = "EC2 instance profiles details"
  value       = module.ec2_profiles
}

output "iam_policies" {
  description = "IAM policies details"
  value       = module.iam_policies
}

output "ec2_key_pairs" {
  description = "ec2 key pairs details"
  value       = module.ec2_key_pairs
}
#-------------------------------------------------------
# SSL/TLS Certificate outputs
#-------------------------------------------------------
output "certificates" {
  description = "ACM Certificates details"
  value       = module.certificates
}

#-------------------------------------------------------
# AWS Load Balancer outputs
#-------------------------------------------------------
output "load_balancers" {
  description = "Load balancers details"
  value       = module.load_balancers

}

#-------------------------------------------------------
# AWS Backup outputs
#-------------------------------------------------------
output "backup" {
  description = "AWS Backup outputs"
  value       = module.backups
}

#-------------------------------------------------------
# AWS Secrets Manager outputs
#-------------------------------------------------------
output "secrets" {
  description = "Output for Secrets Manager"
  value       = module.secrets
}

#-------------------------------------------------------
# AWS SSM Parameters outputs
#-------------------------------------------------------
output "ssm_parameters" {
  description = "Output for SSM Parameters"
  value       = module.ssm_parameters
}

#-------------------------------------------------------
# ALB listener outputs
#-------------------------------------------------------
output "alb_listeners" {
  description = "Output for ALB Listeners"
  value       = module.alb_listeners
}

#-------------------------------------------------------
# ALB listener rules outputs
#-------------------------------------------------------
output "alb_listener_rules" {
  description = "Output for ALB Listener Rules"
  value       = (var.alb_listener_rules != null) ? module.alb_listener_rules : null
}

#-------------------------------------------------------
# NLB listener outputs
#-------------------------------------------------------
output "nlb_listeners" {
  description = "Output for NLB Listeners"
  value       = module.nlb_listeners
}

#-------------------------------------------------------
# Target Group outputs  
#-------------------------------------------------------
output "target_groups" {
  description = "Output for Target Groups"
  value       = module.target_groups
}

#-------------------------------------------------------
# SSM Document outputs
#-------------------------------------------------------
output "ssm_documents" {
  description = "Output for SSM Documents"
  value       = module.ssm_documents
}

#-------------------------------------------------------
# IAM User outputs
#-------------------------------------------------------
output "iam_users" {
  description = "Output for IAM Users"
  value       = module.iam_users
}

#-------------------------------------------------------
# WAF IP Sets outputs
#-------------------------------------------------------
output "ip_sets" {
  description = "Output for WAF IP Sets"
  value       = module.ip_sets
}

#-------------------------------------------------------
# WAF Rule Groups outputs
#-------------------------------------------------------
output "rule_groups" {
  description = "Output for WAF Rule Groups"
  value       = module.rule_groups
}

#-------------------------------------------------------
# WAF User outputs
#-------------------------------------------------------
output "waf" {
  description = "Output for WAFs"
  value       = module.waf
}

#-------------------------------------------------------
# EKS Cluster outputs
#-------------------------------------------------------
output "eks_clusters" {
  description = "Output for EKS Clusters"
  value       = module.eks_clusters
}


# #-------------------------------------------------------
# # EKS Cluster Services Accounts outputs
# #-------------------------------------------------------
# output "eks_service_accounts" {
#   description = "Output for EKS Cluster Service Accounts"
#   value       = module.eks_service_accounts
# }