output "security_group_id" {
  description = "The security group id beking created"
  value       = module.security_ggroup_rules.security_group_id

}

output "security_group_rule_id" {
  description = "The security group rule id"
  value       = module.security_group_rules.security_group_rule_id

}

output "security_group_rule_type" {
  description = "The type of the security group rule (ingress/egress)"
  value       = module.security_group_rules.security_group_rules[0].type

}

output "security_group_rule_protocol" {
  description = "The protocol of the security group rule"
  value       = module.security_group_rules.security_group_rules[0].protocol

}

output "security_group_rule_from_port" {
  description = "The starting port of the security group rule"
  value       = module.security_group_rules.security_group_rules[0].from_port

}

output "security_group_rule_to_port" {
  description = "The ending port of the security group rule"
  value       = module.security_group_rules.security_group_rules[0].to_port

}

output "security_group_rule_cidr_blocks" {
  description = "The CIDR blocks associated with the security group rule"
  value       = module.security_group_rules.security_group_rules[0].cidr_blocks

}
