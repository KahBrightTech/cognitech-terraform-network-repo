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
variable "vpcs" {
  description = "All VPC resources to be created"
  type = list(object({
    name       = string
    cidr_block = string
    public_subnets = list(object({
      key                            = string
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
    private_subnets = list(object({
      key                             = string
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
      subnet_type                     = optional(string)
      vpc_name                        = string
    }))
    public_routes = optional(object({
      public_gateway_id      = optional(string)
      destination_cidr_block = optional(string)
      subnet_ids             = optional(list(string))
      subnet_name            = optional(string)
    }))
    nat_gateway = optional(object({
      name              = string
      type              = string
      primary_subnet    = optional(string)
      secondary_subnet  = optional(string)
      tertiary_subnet   = optional(string)
      quaternary_subnet = optional(string)
      subnet_name       = optional(string)
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
      subnet_name            = optional(string)
    })
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
      key                      = string
      name                     = string
      description              = string
      name_override            = optional(string)
      policy                   = optional(string)
      enable_versioning        = optional(bool, true)
      data_transfer_policy     = optional(string)
      override_policy_document = optional(string)
      encryption = optional(object({
        enabled            = optional(bool, true)
        sse_algorithm      = optional(string, "AES256")
        kms_master_key_id  = optional(string, null)
        bucket_key_enabled = optional(bool, false)
        }), {
        enabled            = true
        sse_algorithm      = "AES256"
        kms_master_key_id  = null
        bucket_key_enabled = false
      })
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
      key           = string
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
    key                      = string
    name                     = string
    description              = string
    name_override            = optional(string)
    policy                   = optional(string)
    enable_versioning        = optional(bool, true)
    override_policy_document = optional(string)
    encryption = optional(object({
      enabled            = optional(bool, true)
      sse_algorithm      = optional(string, "AES256")
      kms_master_key_id  = optional(string, null)
      bucket_key_enabled = optional(bool, false)
      }), {
      enabled            = true
      sse_algorithm      = "AES256"
      kms_master_key_id  = null
      bucket_key_enabled = false
    })
    iam_role_arn_pattern = optional(map(string), null)
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

variable "tgw_association" {
  description = "The transit gateway association variables"
  type = object({
    route_table_id = optional(string)
  })
  default = null
}
variable "tgw_routes" {
  description = "The transit gateway route variables"
  type = list(object({
    name                   = string
    blackhole              = optional(bool)
    destination_cidr_block = string
    attachment_id          = optional(string)
    route_table_id         = string
  }))
  default = null
}
variable "tgw_subnet_route" {
  description = "The transit gateway subnet route variables"
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

variable "key_pairs" {
  description = "Key pair configuration for EC2 instances"
  type = list(object({
    name               = string
    secret_name        = optional(string)
    secret_description = optional(string)
    policy             = optional(string)
    create_secret      = bool
  }))
  default = null
}

variable "vpc_id" {
  description = "The vpc id"
  type        = string
  default     = null
}
variable "load_balancers" {
  description = "Load Balancer configuration"
  type = list(object({
    key             = string
    name            = string
    internal        = optional(bool, false)
    type            = string # "application" or "network"
    security_groups = list(string)
    subnets         = optional(list(string))
    subnet_mappings = optional(list(object({
      subnet_id            = string
      private_ipv4_address = optional(string)
    })))
    enable_deletion_protection = optional(bool, false)
    enable_access_logs         = optional(bool, false)
    access_logs_bucket         = optional(string)
    access_logs_prefix         = optional(string)
  }))
  default = null
}

