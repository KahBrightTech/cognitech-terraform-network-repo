variable "common" {
  description = "Common variables used by all resources"
  type = object({
    global        = bool
    tags          = map(string)
    account_name  = string
    region_prefix = string
    region        = string
  })
  default = null
}

variable "tgw_routes" {
  description = "The transit gateway route variables"
  type = list(object({
    transit_gateway_id = string
    route_table_id     = string
  }))
}






