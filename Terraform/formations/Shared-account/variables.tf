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
    public_subnets = optional(list(object({
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
    })))
    private_subnets = optional(list(object({
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
    })))
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
    private_routes = optional(object({
      nat_gateway_id         = optional(string)
      destination_cidr_block = optional(string)
      primary_subnet_id      = optional(string)
      secondary_subnet_id    = optional(string)
      tertiary_subnet_id     = optional(string)
      quaternary_subnet_id   = optional(string)
      has_tertiary_subnet    = optional(bool, false)
      has_quaternary_subnet  = optional(bool, false)
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
    force_destroy            = optional(bool, true)
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
    create_custom_policy      = optional(bool, true)
    policy = optional(object({
      name          = optional(string)
      description   = optional(string)
      policy        = optional(string)
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
    name               = optional(string)
    name_prefix        = optional(string)
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

variable "certificates" {
  description = "ACM Certificate configuration"
  type = list(object({
    name              = string
    domain_name       = string
    validation_method = string # "DNS" or "EMAIL"
    zone_name         = string # Route53 zone name for DNS validation
  }))
  default = null
}

variable "backups" {
  description = "Backup configuration"
  type = list(object({
    name       = string
    kms_key_id = optional(string)
    role_name  = optional(string)
    plan = object({
      name = string
      rules = list(object({
        rule_name         = string
        schedule          = string
        start_window      = optional(number)
        completion_window = optional(number)
        lifecycle = optional(object({
          cold_storage_after_days = optional(number)
          delete_after_days       = optional(number)
        }))
        copy_actions = optional(list(object({
          destination_vault_arn = optional(string)
          lifecycle = optional(object({
            cold_storage_after_days = optional(number)
            delete_after_days       = optional(number)
          }))
        })))
      }))
      selection = optional(object({
        selection_name = string
        selection_tags = optional(list(object({
          type  = string
          key   = string
          value = string
        })), [])
        resources = optional(list(string))
      }))
    })
  }))
  default = null
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
    vpc_name_abr        = optional(string)
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
      key             = optional(string)
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

variable "secrets" {
  description = "Secrets Manager variables"
  type = list(object({
    key                     = string
    name                    = optional(string)
    name_prefix             = optional(string)
    description             = string
    recovery_window_in_days = optional(number)
    policy                  = optional(string)
    value                   = optional(map(string))
  }))
  default = null
}

variable "ssm_parameters" {
  description = "SSM Parameter variables"
  type = list(object({
    name        = string
    description = string
    type        = string
    value       = optional(string)
    secret_key  = optional(string)
    tier        = optional(string, "Standard") # Default to Standard if not specified
    overwrite   = optional(bool, false)        # Default to false if not specified
  }))
  default = null
}

variable "alb_listeners" {
  description = "Load Balancer listener configuration"
  type = list(object({
    key              = optional(string)
    alb_arn          = optional(string)
    alb_key          = optional(string)
    action           = optional(string, "forward")
    port             = number
    protocol         = string
    ssl_policy       = optional(string)
    certificate_arn  = optional(string)
    alt_alb_hostname = optional(string)
    vpc_id           = optional(string)
    vpc_name         = optional(string)
    fixed_response = optional(object({
      content_type = optional(string, "text/plain")
      message_body = optional(string, "Oops! The page you are looking for does not exist.")
      status_code  = optional(string, "200")
    }))
    sni_certificates = optional(list(object({
      domain_name     = string
      certificate_arn = string
    })))
    target_group = optional(object({
      name         = optional(string)
      port         = optional(number)
      protocol     = optional(string)
      target_type  = optional(string, "instance")
      vpc_name_abr = optional(string)
      attachments = optional(list(object({
        target_id = optional(string)
        port      = optional(number)
      })))
      stickiness = optional(object({
        enabled         = optional(bool)
        type            = optional(string)
        cookie_duration = optional(number)
        cookie_name     = optional(string)
      }))
      health_check = object({
        protocol = optional(string)
        port     = optional(number)
        path     = optional(string)
        matcher  = optional(string)
      })
    }))
  }))
  default = null
}

variable "alb_listener_rules" {
  description = "ALB Listener Rule Configuration"
  type = list(object({
    index_key    = optional(string)
    listener_arn = optional(string)
    listener_key = optional(string)
    rules = list(object({
      key      = optional(string)
      priority = optional(number)
      type     = string
      target_groups = optional(list(object({
        tg_name = optional(string)
        arn     = optional(string)
        weight  = optional(number)
      })))
      conditions = optional(list(object({
        host_headers         = optional(list(string))
        http_request_methods = optional(list(string))
        path_patterns        = optional(list(string))
        source_ips           = optional(list(string))
        http_headers = optional(list(object({
          name   = optional(string)
          values = list(string)
        })))
        query_strings = optional(list(object({
          key   = optional(string)
          value = string
        })))
      })))
    }))
  }))
  default = null
}

variable "nlb_listeners" {
  description = "Network Load Balancer listener configuration"
  type = list(object({
    key             = optional(string)
    name            = optional(string)
    nlb_key         = optional(string)
    nlb_arn         = optional(string)
    action          = optional(string, "forward")
    port            = number
    protocol        = string
    ssl_policy      = optional(string)
    certificate_arn = optional(string)
    vpc_id          = optional(string)
    vpc_name        = optional(string)
    sni_certificates = optional(list(object({
      domain_name     = optional(string)
      certificate_arn = optional(string)
    })))
    target_group = optional(object({
      name         = optional(string)
      port         = optional(number)
      protocol     = optional(string)
      vpc_name_abr = optional(string)
      target_type  = optional(string, "instance")
      attachments = optional(list(object({
        target_id      = optional(string)
        port           = optional(number)
        ec2_key        = optional(string)
        use_private_ip = optional(bool, false) # If true, use private IP of the EC2 instance
      })))
      stickiness = optional(object({
        enabled         = optional(bool)
        type            = optional(string)
        cookie_duration = optional(number)
        cookie_name     = optional(string)
      }))
      health_check = object({
        enabled  = optional(bool, true)
        protocol = optional(string)
        port     = optional(number)
        path     = optional(string)
        matcher  = optional(string, "200")
      })
    }))
  }))
  default = null
}

variable "target_groups" {
  description = "Target Group configuration"
  type = list(object({
    key                = optional(string)
    name               = string
    port               = number
    protocol           = string
    preserve_client_ip = optional(bool)
    target_type        = optional(string, "instance")
    tags               = optional(map(string))
    vpc_id             = optional(string)
    vpc_name_abr       = optional(string)
    vpc_name           = optional(string)
    attachments = optional(list(object({
      target_id = optional(string)
      port      = optional(number)
    })))
    stickiness = optional(object({
      enabled         = bool
      type            = string
      cookie_duration = optional(number)
      cookie_name     = optional(string)
    }))
    health_check = object({
      protocol = optional(string)
      port     = optional(number)
      path     = optional(string)
      matcher  = optional(string)
    })
  }))
  default = null
}


variable "ssm_documents" {
  description = "SSM Document configuration"
  type = list(object({
    name               = string
    content            = string
    create_association = optional(bool, false)
    document_type      = optional(string, "Command")
    document_format    = optional(string, "YAML")
    tags               = optional(map(string))
    targets = optional(object({
      key    = optional(string)
      values = optional(list(string))
    }))
    schedule_expression = optional(string)
    output_location = optional(object({
      s3_bucket_name = optional(string)
      s3_key_prefix  = optional(string)
    }))
  }))
  default = null
}

variable "iam_users" {
  description = "IAM User configuration"
  type = list(object({
    name                 = string
    description          = optional(string)
    path                 = optional(string)
    permissions_boundary = optional(string)
    force_destroy        = optional(bool, false)
    groups               = optional(list(string))
    regions              = optional(list(string))
    notifications_email  = string
    user_type            = optional(string, "standard")
    create_access_key    = optional(bool, true)
    secrets_manager = optional(object({
      name_prefix             = optional(string, "iam-user")
      recovery_window_in_days = optional(number, 30)
      description             = optional(string, null)
      policy                  = optional(string)
    }), {})
    policy = optional(object({
      name        = string
      description = optional(string)
      policy      = string
    }))
    group_policies = optional(list(object({
      group_name  = string
      policy_name = string
      description = optional(string)
      policy      = string
    })), [])
  }))
  default = null
}

variable "datasync_locations" {
  description = "DataSync configuration with all location types and task settings"
  type = list(object({
    key = optional(string)
    # S3 Location Configuration
    s3_location = optional(object({
      location_type          = string
      s3_bucket_arn          = string
      subdirectory           = optional(string)
      bucket_access_role_arn = string
      s3_storage_class       = optional(string)
    }))

    # EFS Location Configuration
    efs_location = optional(object({
      location_type       = string
      efs_file_system_arn = string
      access_point_arn    = optional(string)
      subdirectory        = optional(string)
      ec2_config = object({
        security_group_arns = list(string)
        subnet_arn          = string
      })
      in_transit_encryption = optional(string)
    }))

    # FSx for Windows File System Location Configuration
    fsx_windows_location = optional(object({
      location_type       = string
      fsx_filesystem_arn  = string
      subdirectory        = optional(string)
      user                = string
      domain              = optional(string)
      password            = string
      security_group_arns = list(string)
    }))

    # FSx for Lustre Location Configuration
    fsx_lustre_location = optional(object({
      location_type       = string
      fsx_filesystem_arn  = string
      subdirectory        = optional(string)
      security_group_arns = list(string)
    }))

    # FSx for NetApp ONTAP Location Configuration
    fsx_ontap_location = optional(object({
      location_type      = string
      fsx_filesystem_arn = string
      subdirectory       = optional(string)
      protocol = object({
        nfs = optional(object({
          mount_options = object({
            version = optional(string)
          })
        }))
        smb = optional(object({
          domain = optional(string)
          mount_options = object({
            version = optional(string)
          })
          password = string
          user     = string
        }))
      })
      security_group_arns         = list(string)
      storage_virtual_machine_arn = string
    }))

    # FSx for OpenZFS Location Configuration
    fsx_openzfs_location = optional(object({
      location_type      = string
      fsx_filesystem_arn = string
      subdirectory       = optional(string)
      protocol = object({
        nfs = object({
          mount_options = object({
            version = optional(string)
          })
        })
      })
      security_group_arns = list(string)
    }))

    # NFS Location Configuration
    nfs_location = optional(object({
      location_type   = string
      server_hostname = string
      subdirectory    = string
      on_prem_config = object({
        agent_arns = list(string)
      })
      mount_options = optional(object({
        version = optional(string)
      }))
    }))

    # SMB Location Configuration
    smb_location = optional(object({
      location_type   = string
      agent_arns      = list(string)
      domain          = optional(string)
      password        = string
      server_hostname = string
      subdirectory    = string
      user            = string
      mount_options = optional(object({
        version = optional(string)
      }))
    }))

    # HDFS Location Configuration
    hdfs_location = optional(object({
      location_type        = string
      cluster_type         = string
      agent_arns           = list(string)
      authentication_type  = optional(string)
      block_size           = optional(number)
      kerberos_keytab      = optional(string)
      kerberos_krb5_conf   = optional(string)
      kerberos_principal   = optional(string)
      kms_key_provider_uri = optional(string)
      namenode_configs = list(object({
        hostname = string
        port     = number
      }))
      qop_configuration = optional(object({
        data_transfer_protection = optional(string)
        rpc_protection           = optional(string)
      }))
      replication_factor = optional(number)
      simple_user        = optional(string)
      subdirectory       = string
    }))

    # Object Storage Location Configuration
    object_storage_location = optional(object({
      location_type      = string
      agent_arns         = list(string)
      bucket_name        = string
      server_hostname    = string
      subdirectory       = optional(string)
      access_key         = optional(string)
      secret_key         = optional(string)
      server_port        = optional(number)
      server_protocol    = optional(string)
      server_certificate = optional(string)
    }))

    # Azure Blob Storage Location Configuration
    azure_blob_location = optional(object({
      location_type       = string
      agent_arns          = list(string)
      container_url       = string
      subdirectory        = optional(string)
      authentication_type = string
      sas_configuration = optional(object({
        token = string
      }))
      blob_type   = optional(string)
      access_tier = optional(string)
    }))
  }))
  default = null
}

#--------------------------------------------------------------------
# WAF Configuration Variables (All-in-One)
#--------------------------------------------------------------------
variable "wafs" {
  description = "Complete WAF configuration object"
  type = list(object({
    key                        = string
    name                       = optional(string, null)
    description                = optional(string, "WAF Web ACL for application protection")
    scope                      = optional(string, "REGIONAL")
    default_action             = optional(string, "allow")
    cloudwatch_metrics_enabled = optional(bool, true)
    rule_file                  = optional(string)
    ip_set_arns                = optional(list(string))
    sampled_requests_enabled   = optional(bool, true)
    ip_sets = optional(list(object({
      key                = string
      name               = string
      description        = optional(string, null)
      scope              = optional(string, "REGIONAL")
      ip_address_version = optional(string, "IPV4")
      addresses          = list(string)
      additional_tags    = optional(map(string), {})
    })))
    rule_groups = optional(list(object({
      key             = string
      name            = string
      description     = optional(string)
      capacity        = number
      rule_group_file = optional(string)
      rules = optional(list(object({
        name                  = string
        priority              = number
        action                = string
        statement_type        = string
        ip_set_arn            = optional(string)
        country_codes         = optional(list(string))
        rate_limit            = optional(number)
        aggregate_key_type    = optional(string)
        field_to_match        = optional(string)
        header_name           = optional(string)
        positional_constraint = optional(string)
        search_string         = optional(string)
        text_transformation   = optional(string, "NONE")
        comparison_operator   = optional(string)
        size                  = optional(number)
      })))
      additional_tags = optional(map(string), {})
    })))
    # Custom Rules
    custom_rules = optional(list(object({
      name                  = string
      priority              = number
      action                = string
      statement_type        = string
      country_codes         = optional(list(string))
      rate_limit            = optional(number)
      aggregate_key_type    = optional(string)
      field_to_match        = optional(string)
      header_name           = optional(string)
      positional_constraint = optional(string)
      search_string         = optional(string)
      text_transformation   = optional(string, "NONE")
      ip_set_arn            = optional(string)
      ip_set_key            = optional(string)
    })))

    # Rule Group References (for custom rule groups)
    rule_group_references = optional(list(object({
      name            = string
      priority        = number
      arn             = optional(string)
      rule_group_key  = optional(string)
      override_action = optional(string, "none")
    })))

    # Association
    association = optional(object({
      associate_alb = optional(bool, false)
      alb_arns      = optional(list(string))
      alb_keys      = optional(list(string))
      web_acl_arn   = optional(string)
    }))

    # Logging
    logging = optional(object({
      enabled             = optional(bool, false)
      log_destination_arn = optional(string)
      create_log_group    = optional(bool)
      log_retention_days  = optional(number, 30)
      redacted_fields     = optional(list(string))
      logging_filter = optional(object({
        default_behavior = string
        filters = list(object({
          behavior    = string
          requirement = string
          conditions = list(object({
            type       = string
            action     = optional(string)
            label_name = optional(string)
          }))
        }))
      }))
    }))
  }))
  default = null
}

#--------------------------------------------------------------------
# EKS Configuration
#--------------------------------------------------------------------
variable "eks" {
  description = "EKS cluster configuration object."
  type = list(object({
    key                                         = string
    name                                        = string
    create_eks_cluster                          = optional(bool, false)
    role_arn                                    = optional(string)
    role_key                                    = optional(string)
    subnet_ids                                  = optional(list(string))
    subnet_keys                                 = optional(list(string))
    additional_security_group_ids               = optional(list(string))
    additional_security_group_keys              = optional(list(string))
    create_cloudwatch_role                      = optional(bool, false)
    cloudwatch_observability_role_arn           = optional(string)
    cloudwatch_observability_role_key           = optional(string)
    endpoint_private_access                     = optional(bool, false)
    endpoint_public_access                      = optional(bool, true)
    public_access_cidrs                         = optional(list(string), ["0.0.0.0/0"])
    authentication_mode                         = optional(string, "API_AND_CONFIG_MAP")
    bootstrap_cluster_creator_admin_permissions = optional(bool, true)
    enabled_cluster_log_types                   = optional(list(string), [])
    service_ipv4_cidr                           = optional(string, null)
    access_entries = optional(map(object({
      principal_arns = optional(list(string))
      policy_arn     = optional(string)
    })), {})
    version                 = optional(string, "1.33")
    oidc_thumbprint         = optional(string)
    is_this_ec2_node_group  = optional(bool, false)
    use_private_subnets     = optional(bool, false)
    vpc_name                = optional(string)
    create_node_group       = optional(bool, false)
    create_service_accounts = optional(bool, false)
    enable_eks_pia          = optional(bool, false)
    eks_addons = optional(object({
      enable_vpc_cni                     = optional(bool, false)
      enable_kube_proxy                  = optional(bool, false)
      enable_coredns                     = optional(bool, false)
      enable_metrics_server              = optional(bool, false)
      enable_cloudwatch_observability    = optional(bool, false)
      enable_secrets_manager_csi_driver  = optional(bool, false)
      enable_privateca_issuer            = optional(bool, false)
      vpc_cni_version                    = optional(string)
      kube_proxy_version                 = optional(string)
      coredns_version                    = optional(string)
      metrics_server_version             = optional(string)
      cloudwatch_observability_version   = optional(string)
      secrets_manager_csi_driver_version = optional(string)
      privateca_issuer_version           = optional(string)
      create_cloudwatch_role             = optional(bool, false)
      cloudwatch_observability_role_arn  = optional(string)
      cloudwatch_observability_role_key  = optional(string)
      enableSecretRotation               = optional(bool, false)
      rotationPollInterval               = optional(string)
    }))
    key_pair = object({
      name               = optional(string)
      name_prefix        = optional(string)
      secret_name        = optional(string)
      secret_description = optional(string)
      policy             = optional(string)
    })
    security_groups = optional(list(object({
      key         = optional(string)
      name        = optional(string)
      name_prefix = optional(string)
      vpc_id      = optional(string)
      description = optional(string)
      vpc_name    = string
      security_group_egress_rules = optional(list(object({
        description     = optional(string)
        from_port       = optional(number)
        to_port         = optional(number)
        protocol        = optional(string)
        security_groups = optional(list(string))
        cidr_blocks     = list(string)
        self            = optional(bool, false)
      })))
      security_group_ingress_rules = optional(list(object({
        description     = optional(string)
        from_port       = optional(number)
        to_port         = optional(number)
        protocol        = optional(string)
        security_groups = optional(list(string))
        cidr_blocks     = list(string)
        self            = optional(bool, false)
      })))
    })))
    security_group_rules = optional(list(object({
      key               = optional(string)
      security_group_id = optional(string)
      sg_key            = optional(string)
      egress_rules = optional(list(object({
        key               = string
        cidr_ipv4         = optional(string)
        cidr_ipv6         = optional(string)
        prefix_list_id    = optional(string)
        description       = optional(string)
        from_port         = optional(number)
        to_port           = optional(number)
        ip_protocol       = string
        target_sg_id      = optional(string)
        target_sg_key     = optional(string)
        target_vpc_sg_id  = optional(string)
        target_vpc_sg_key = optional(string)
      })))
      ingress_rules = optional(list(object({
        key               = string
        cidr_ipv4         = optional(string)
        cidr_ipv6         = optional(string)
        prefix_list_id    = optional(string)
        description       = optional(string)
        from_port         = optional(number)
        to_port           = optional(number)
        ip_protocol       = string
        source_sg_id      = optional(string)
        source_sg_key     = optional(string)
        source_vpc_sg_id  = optional(string)
        source_vpc_sg_key = optional(string)
      })))
    })))
    launch_templates = optional(list(object({
      key              = optional(string)
      name             = optional(string)
      instance_profile = optional(string)
      custom_ami       = optional(string)
      ami_config = object({
        os_release_date  = optional(string)
        os_base_packages = optional(string)
      })
      instance_type               = optional(string)
      key_name                    = optional(string)
      ec2_ssh_key                 = optional(string)
      associate_public_ip_address = optional(bool)
      vpc_security_group_ids      = optional(list(string))
      vpc_security_group_keys     = optional(list(string))
      account_security_group_keys = optional(list(string))
      tags                        = optional(map(string))
      user_data                   = optional(string)
      volume_size                 = optional(number)
      root_device_name            = optional(string)
    })))
    eks_node_groups = optional(list(object({
      key                        = optional(string)
      cluster_key                = optional(string)
      cluster_name               = optional(string)
      node_group_name            = string
      node_role_arn              = optional(string)
      node_role_key              = optional(string)
      subnet_ids                 = optional(list(string))
      subnet_keys                = optional(list(string))
      desired_size               = number
      max_size                   = number
      min_size                   = number
      instance_types             = optional(list(string), [])
      enable_remote_access       = optional(bool, false)
      ec2_ssh_key                = optional(string, "")
      source_security_group_ids  = optional(list(string), [])
      source_security_group_keys = optional(list(string), [])
      ami_type                   = optional(string)
      disk_size                  = optional(number)
      labels                     = optional(map(string), {})
      tags                       = optional(map(string), {})
      version                    = optional(string)
      force_update_version       = optional(bool, false)
      capacity_type              = optional(string, "ON_DEMAND")
      ec2_instance_name          = optional(string, "eks_node_group")
      launch_template_key        = optional(string)
      launch_template = optional(object({
        id      = string
        version = optional(string, "$Latest")
      }))
    })))
    service_accounts = optional(list(object({
      key       = optional(string)
      name      = string
      namespace = optional(string, "default")
      role_arn  = optional(string)
      role_key  = optional(string)
    })))
    eks_pia = optional(list(object({
      key                       = optional(string)
      service_account_keys      = optional(list(string), [])
      service_account_namespace = optional(string)
      role_arn                  = optional(string)
      role_key                  = optional(string)
    })))
    iam_roles = optional(list(object({
      key                                = optional(string)
      name                               = string
      description                        = optional(string)
      path                               = optional(string, "/")
      assume_role_policy                 = optional(string)
      use_default_eks_assume_role_policy = optional(bool, true)
      custom_assume_role_policy          = optional(bool, true)
      force_detach_policies              = optional(bool, false)
      managed_policy_arns                = optional(list(string))
      max_session_duration               = optional(number, 3600)
      permissions_boundary               = optional(string)
      create_custom_policy               = optional(bool, true)
      service_account_name               = optional(string)
      service_account_namespace          = optional(string)
      policy = optional(object({
        name          = optional(string)
        description   = optional(string)
        policy        = optional(string)
        path          = optional(string, "/")
        custom_policy = optional(bool, true)
      }))
    })))
  }))
  default = null
}
