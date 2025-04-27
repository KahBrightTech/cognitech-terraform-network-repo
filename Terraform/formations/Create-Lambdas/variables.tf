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
variable "Lambdas" {
  description = "Lambda functions to be created"
  type = list(object({
    function_name        = string
    description          = string
    runtime              = string
    handler              = string
    timeout              = number
    private_bucklet_name = optional(string)
    s3_key               = optional(string)
    layer_description    = optional(string)
    layer_filename       = optional(string)
  }))
  default = null
}








