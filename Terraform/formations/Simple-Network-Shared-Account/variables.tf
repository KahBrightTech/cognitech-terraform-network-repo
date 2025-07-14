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
    public_routes = object({
      public_gateway_id      = optional(string)
      destination_cidr_block = optional(string)
      subnet_ids             = optional(list(string))
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
    name                     = string
    description              = string
    name_override            = optional(string)
    policy                   = optional(string)
    enable_versioning        = optional(bool, true)
    enable_bucket_policy     = optional(bool, true)
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
    replication = optional(object({
      role_arn = string
      rules = list(object({
        status                    = string
        delete_marker_replication = optional(bool, false)
        prefix                    = optional(string, "")
        filter = optional(object({
          prefix = string
        }))
        destination = object({
          bucket_arn    = string
          storage_class = optional(string, "STANDARD")
          access_control_translation = optional(object({
            owner = string
          }))
          account_id = optional(number)
          encryption_configuration = optional(object({
            replica_kms_key_id = string
          }))
          replication_time = optional(object({
            minutes = optional(number, 15)
          }))
          replica_modification = optional(object({
            enabled                         = optional(bool, false)
            metrics_event_threshold_minutes = optional(number, 15)
          }))
        })
      }))
    }))
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
    key                 = string
    name                = string
    internal            = optional(bool, false)
    type                = string # "application" or "network"
    security_groups     = optional(list(string))
    vpc_name            = string
    use_private_subnets = optional(bool, false)
    subnets             = optional(list(string))
    subnet_mappings = optional(list(object({
      subnet_key           = string
      az_subnet_selector   = string
      private_ipv4_address = optional(string)
    })))
    enable_deletion_protection = optional(bool, false)
    enable_access_logs         = optional(bool, false)
    access_logs_bucket         = optional(string)
    access_logs_prefix         = optional(string)
    create_default_listener    = optional(bool, false)
    default_listener = optional(object({
      port            = optional(number, "443")
      protocol        = optional(string, "HTTPS")
      action_type     = optional(string, "fixed-response")
      ssl_policy      = optional(string, "ELBSecurityPolicy-2016-08")
      certificate_arn = optional(string)
      fixed_response = object({
        content_type = optional(string, "text/plain")
        message_body = optional(string, "Oops! The page you are looking for does not exist.")
        status_code  = optional(string, "200")
      })
    }))
  }))
  default = null
}



