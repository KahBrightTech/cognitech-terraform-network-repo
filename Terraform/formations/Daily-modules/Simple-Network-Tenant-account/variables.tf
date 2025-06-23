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
    public_subnets = list(object({
      name                           = string
      primary_availability_zone      = optional(string)
      primary_availability_zone_id   = optional(string)
      primary_cidr_block             = optional(string)
      secondary_availability_zone    = optional(string)
      secondary_availability_zone_id = optional(string)
      secondary_cidr_block           = optional(string)
      tertiary_availability_zone     = optional(string)
      tertiary_availability_zone_id  = optional(string)
      tertiary_cidr_block            = optional(string)
      subnet_ids                     = optional(list(string))
      subnet_type                    = optional(string)
      vpc_name                       = string
    }))
    public_routes = optional(object({
      public_gateway_id      = optional(string)
      destination_cidr_block = optional(string)
      subnet_ids             = optional(list(string))
      subnet_name            = optional(string)
    }))
    security_groups = optional(list(object({
      key         = string
      description = string
      name        = string
      name_prefix = optional(string)
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
    route53_zones = optional(list(object({
      name          = string
      vpc_id        = optional(string)
      comment       = optional(string, null)
      private_zone  = optional(bool, true)
      force_destroy = optional(bool, true)
    })))
  }))
  default = null
}

variable "s3_private_buckets" {
  description = "S3 bucket variables"
  type = list(object({
    name                     = string
    description              = string
    name_override            = optional(string)
    policy                   = optional(string)
    enable_versioning        = optional(bool, true)
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
  default = null
}
variable "iam_roles" {
  description = "IAM Roles and policies to be created"
  type = list(object({
    name                      = string
    description               = optional(string)
    path                      = optional(string, "/")
    assume_role_policy        = string
    custom_assume_role_policy = optional(bool, true)
    force_detach_policies     = optional(bool, false)
    managed_policy_arns       = optional(list(string))
    max_session_duration      = optional(number, 3600)
    permissions_boundary      = optional(string)
    policy = optional(object({
      name          = string
      description   = optional(string)
      policy        = string
      path          = optional(string, "/")
      custom_policy = optional(bool, true)
    }))
  }))
  default = null
}


variable "ec2_profiles" {
  description = "IAM Role configuration"
  type = list(object({
    name                      = string
    description               = optional(string)
    path                      = optional(string, "/")
    assume_role_policy        = string
    custom_assume_role_policy = optional(bool, true)
    force_detach_policies     = optional(bool, false)
    managed_policy_arns       = optional(list(string))
    max_session_duration      = optional(number, 3600)
    permissions_boundary      = optional(string)
    policy = optional(object({
      name          = string
      description   = optional(string)
      policy        = string
      path          = optional(string, "/")
      custom_policy = optional(bool, true)
    }))
  }))
  default = null
}

variable "iam_policies" {
  description = "IAM Role configuration"
  type = list(object({
    name          = string
    description   = optional(string)
    policy        = string
    path          = optional(string, "/")
    custom_policy = optional(bool, true)
  }))
  default = null
}

variable "vpc_id" {
  description = "The vpc id"
  type        = string
  default     = null
}


