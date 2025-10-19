
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
