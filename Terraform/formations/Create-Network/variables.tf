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

variable "vpc" {
  description = "All VPC resources to be created"
  type = object({
    name       = string
    cidr_block = string

    private_subnets = object({
      name                            = string
      primary_availability_zone       = optional(string)
      primary_availability_zone_id    = optional(string)
      primary_cidr_block              = string
      secondary_availability_zone     = optional(string)
      secondary_availability_zone_id  = optional(string)
      secondary_cidr_block            = optional(string)
      tertiary_availability_zone      = optional(string)
      tertiary_availability_zone_id   = optional(string)
      tertiary_cidr_block             = optional(string)
      quaternary_availability_zone    = optional(string)
      quaternary_availability_zone_id = optional(string)
      quaternary_cidr_block           = optional(string)
    })

    public_subnets = object({
      name                            = string
      primary_availability_zone       = optional(string)
      primary_availability_zone_id    = optional(string)
      primary_cidr_block              = optional(string)
      secondary_availability_zone     = optional(string)
      secondary_availability_zone_id  = optional(string)
      secondary_cidr_block            = optional(string)
      tertiary_availability_zone      = optional(string)
      tertiary_availability_zone_id   = optional(string)
      tertiary_cidr_block             = optional(string)
      quaternary_availability_zone    = optional(string)
      quaternary_availability_zone_id = optional(string)
      quaternary_cidr_block           = optional(string)
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
      primary_subnet_id      = optional(string)
      secondary_subnet_id    = optional(string)
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
    security_groups = optional(list(object({
      key         = string
      description = string
      name        = string
      name_prefix = string
      egress = optional(list(object({
        name            = string
        description     = string
        protocol        = string
        from_port       = number
        to_port         = number
        security_groups = optional(list(string))
        cidr_blocks     = optional(list(string))
        self            = optional(bool, false)
      })))
      ingress = optional(list(object({
        name            = string
        description     = string
        protocol        = string
        from_port       = number
        to_port         = number
        security_groups = optional(list(string))
        cidr_blocks     = optional(list(string))
        self            = optional(bool, false)
      })))
    })))
    security_group_rules = optional(list(object({
      sg_key = string
      egress = optional(list(object({
        key           = string
        cidr_ipv4     = optional(string)
        cidr_ipv6     = optional(string)
        description   = optional(string)
        from_port     = optional(string)
        to_port       = optional(string)
        ip_protocol   = optional(string)
        target_sg_id  = optional(string)
        target_sg_key = optional(string)
      })))
      ingress = optional(list(object({
        key           = string
        cidr_ipv4     = optional(string)
        cidr_ipv6     = optional(string)
        description   = optional(string)
        from_port     = optional(string)
        to_port       = optional(string)
        ip_protocol   = optional(string)
        source_sg_id  = optional(string)
        source_sg_key = optional(string)
      })))
    })))
    s3 = optional(object({
      name                     = string
      description              = string
      name_override            = optional(string)
      policy                   = optional(string)
      enable_versioning        = optional(bool, true)
      data_transfer_policy     = optional(string)
      override_policy_document = optional(string)
      iam_role_arn_pattern     = optional(map(string), null)
      lifecycle = optional(object({
        standard_expiration_days          = number
        infrequent_access_expiration_days = number
        glacier_expiration_days           = number
        delete_expiration_days            = number
      }))
      lifecycle_noncurrent = optional(object({
        standard_expiration_days          = number
        infrequent_access_expiration_days = number
        glacier_expiration_days           = number
        delete_expiration_days            = number
      }))
      objects = optional(list(object({
        key = string
      })))
    }))
  })
  default = null
}
