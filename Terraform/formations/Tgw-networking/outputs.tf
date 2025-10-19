output "transit_gateway_route_table" {
  description = "Transit Gateway route table details"
  value       = length(module.transit_gateway_route_table) > 0 ? module.transit_gateway_route_table : null
}

output "transit_gateway_association" {
  description = "Transit Gateway association details"
  value       = length(module.transit_gateway_association) > 0 ? module.transit_gateway_association : null
}
