variable "common" {
  description = "Common variables used by all resources"
  type = object({
    global        = bool
    tags          = map(string)
    account_name  = string
    region_prefix = string
  })
}

variable "secrets" {
  description = "Secrets Manager variables"
  type = list(object({
    name                    = string
    description             = string
    recovery_window_in_days = optional(number)
    policy                  = optional(string)
    value                   = optional(map(string))
    record_folder_uid       = optional(string)
  }))
  default = null
}
