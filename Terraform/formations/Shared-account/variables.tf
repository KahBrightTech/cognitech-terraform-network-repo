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
variable "vpcs" {
  description = "All VPC resources to be created"
  type = list(object({
    name       = string
    cidr_block = string
    private_subnets = object({
      name                           = string
      primary_availabilty_zone       = optional(string)
      primary_availabilty_zone_id    = optional(string)
      primary_cidr_block             = string
      secondary_availabilty_zone     = optional(string)
      secondary_availabilty_zone_id  = optional(string)
      secondary_cidr_block           = optional(string)
      tertiary_availabilty_zone      = optional(string)
      tertiary_availabilty_zone_id   = optional(string)
      tertiary_cidr_block            = optional(string)
      quaternary_availabilty_zone    = optional(string)
      quaternary_availabilty_zone_id = optional(string)
      quaternary_cidr_block          = optional(string)
    })
    public_subnets = object({
      name                           = string
      primary_availabilty_zone       = optional(string)
      primary_availabilty_zone_id    = optional(string)
      primary_cidr_block             = optional(string)
      secondary_availabilty_zone     = optional(string)
      secondary_availabilty_zone_id  = optional(string)
      secondary_cidr_block           = optional(string)
      tertiary_availabilty_zone      = optional(string)
      tertiary_availabilty_zone_id   = optional(string)
      tertiary_cidr_block            = optional(string)
      quaternary_availabilty_zone    = optional(string)
      quaternary_availabilty_zone_id = optional(string)
      quaternary_cidr_block          = optional(string)
    })
    nat_gateway = optional(object({
      name              = string
      type              = string
      primary_subnet    = optional(string)
      secondary_subnet  = optional(string)
      tertiary_subnet   = optional(string)
      quaternary_subnet = optional(string)
    }))
    private_routes = object({
      nat_gateway_id         = optional(string)
      destination_cidr_block = optional(string)
      primary_subnet_id      = string
      secondary_subnet_id    = string
      tertiary_subnet_id     = optional(string)
      quaternary_subnet_id   = optional(string)
      has_tertiary_subnet    = optional(bool, false)
      has_quaternary_subnet  = optional(bool, false)
    })
    public_routes = object({
      public_gateway_id      = optional(string)
      destination_cidr_block = optional(string)
      primary_subnet_id      = optional(string)
      secondary_subnet_id    = optional(string)
      tertiary_subnet_id     = optional(string)
      quaternary_subnet_id   = optional(string)
      has_tertiary_subnet    = optional(bool, false)
      has_quaternary_subnet  = optional(bool, false)
    })
  }))
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
  })
}






