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
variable "tgw_attachments" {
  description = "The transit gateway attachment variables"
  type = object({
    transit_gateway_id   = string
    primary_subnet_id    = string
    secondary_subnet_id  = string
    transit_gateway_name = optional(string)
    shared_vpc_name      = optional(string)
    attachment_name      = optional(string)
  })
  default = null
}

variable "vpc_id" {
  description = "The vpc id"
  type        = string
}






