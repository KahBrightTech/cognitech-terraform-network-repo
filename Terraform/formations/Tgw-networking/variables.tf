variable "common" {
  description = "Common variables used by all resources"
  type = object({
    global           = bool
    tags             = map(string)
    account_name     = string
    region_prefix    = string
    region           = string
    account_name_abr = optional(string)
  })
  default = null
}

variable "transit_gateway" {
  description = "values for transit gateway"
  type = object({
    name                            = string
    default_route_table_association = string
    default_route_table_propagation = string
    auto_accept_shared_attachments  = string
    dns_support                     = string
    amazon_side_asn                 = number
    vpc_name                        = string
    ram = optional(object({
      enabled                   = optional(bool, false)
      share_name                = optional(string, "transit-gateway-share")
      allow_external_principals = optional(bool, false)
      principals                = optional(list(string), [])
    }))
  })
  default = null
}

variable "tgw_attachments" {
  description = "The transit gateway attachment variables"
  type = object({
    transit_gateway_id   = optional(string)
    subnet_ids           = optional(list(string))
    transit_gateway_name = optional(string)
    name                 = optional(string)
  })
  default = null
}

variable "tgw_associations" {
  description = "The transit gateway association variables"
  type = list(object({
    key              = optional(string)
    attachment_id    = optional(string)
    route_table_id   = optional(string)
    route_table_name = optional(string) # Add this for referencing the route table by name
    route_table_key  = optional(string) # Add this for referencing the route table by key
  }))
  default = null
}

variable "tgw_propagations" {
  description = "The transit gateway propagation variables"
  type = list(object({
    key              = optional(string)
    attachment_id    = string
    route_table_id   = string
    route_table_name = optional(string) # Add this for referencing the route table by name
    route_table_key  = optional(string)
  }))
  default = null
}

variable "tgw_route_table" {
  description = "The transit gateway route table variables"
  type = list(object({
    key    = string
    name   = string
    tgw_id = optional(string)
  }))
  default = null
}

variable "tgw_routes" {
  description = "The transit gateway route variables"
  type = list(object({
    key                    = optional(string)
    name                   = string
    blackhole              = optional(bool)
    destination_cidr_block = string
    attachment_id          = optional(string)
    route_table_id         = optional(string)
    route_table_name       = optional(string) # Add this for referencing the route table by name
    route_table_key        = optional(string) # Add this for referencing the route table by key
  }))
  default = null
}

variable "tgw_subnet_route" {
  description = "The transit gateway private subnet route variables"
  type = list(object({
    name                = string
    route_table_id      = optional(string)
    cidr_block          = optional(string)
    transit_gateway_id  = optional(string)
    subnet_name         = optional(string, null)
    vpc_name            = optional(string, null)
    create_public_route = optional(bool, false)
  }))
  default = null
}
