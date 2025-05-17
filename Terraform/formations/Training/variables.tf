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
    lamda_s3_key         = optional(string)
    layer_description    = optional(string)
    layer_s3_key         = optional(string)
    env_variables        = optional(map(string))
  }))
  default = null
}

variable "service_catalogs" {
  description = "Service Catalog variables"
  type = list(object({
    name          = string
    description   = optional(string)
    provider_name = optional(string)
    products = list(object({
      name        = string
      description = optional(string)
      type        = string
      owner       = optional(string)
    }))
    provisioning_artifact_parameters = list(object({
      name         = string
      description  = string
      type         = string
      template_url = string
    }))
  }))
  default = null
}








