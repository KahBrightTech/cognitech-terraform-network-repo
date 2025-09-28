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

variable "ec2_instances" {
  description = "EC2 Instance configuration"
  type = list(object({
    index             = optional(string)
    name              = string
    name_override     = optional(string)
    custom_ami        = optional(string)
    attach_tg         = optional(list(string))
    target_group_arns = optional(list(string))
    ami_config = object({
      os_release_date  = optional(string)
      os_base_packages = optional(string)
    })
    associate_public_ip_address = optional(bool, false)
    instance_type               = string
    iam_instance_profile        = string
    key_name                    = string
    custom_tags                 = optional(map(string))
    ebs_root_volume = optional(object({
      volume_size           = number
      volume_type           = optional(string, "gp3")
      delete_on_termination = optional(bool, true)
      encrypted             = optional(bool, false)
      kms_key_id            = optional(string, null)
    }))
    ebs_device_volume = optional(list(object({
      name                  = string
      volume_size           = number
      volume_type           = optional(string, "gp3")
      delete_on_termination = optional(bool, true)
      encrypted             = optional(bool, false)
      kms_key_id            = optional(string, null)
    })))
    subnet_id          = string
    Schedule_name      = optional(string)
    backup_plan_name   = optional(string)
    security_group_ids = list(string)
    hosted_zones = optional(object({
      name           = string
      zone_id        = string
      type           = string
      ttl            = optional(number, 60)
      records        = optional(list(string))
      set_identifier = optional(string)
      weight         = optional(number)
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
    vpc_name           = optional(string)
    vpc_name_abr       = optional(string)
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

variable "datasync_tasks" {
  description = "DataSync configuration with all location types and task settings"
  type = list(object({
    key = optional(string)
    # Common Configuration
    # CloudWatch Log Group Configuration
    create_cloudwatch_log_group   = optional(bool, false)
    cloudwatch_log_group_name     = optional(string)
    cloudwatch_log_retention_days = optional(number, 30)
    # DataSync Task Configuration
    task = optional(object({
      name                     = optional(string)
      source_key               = optional(string)
      destination_key          = optional(string)
      source_location_arn      = optional(string)
      destination_location_arn = optional(string)
      cloudwatch_log_group_arn = optional(string)
      options = optional(object({
        atime                          = optional(string)
        bytes_per_second               = optional(number)
        gid                            = optional(string)
        log_level                      = optional(string)
        mtime                          = optional(string)
        overwrite_mode                 = optional(string)
        posix_permissions              = optional(string)
        preserve_deleted_files         = optional(string)
        preserve_devices               = optional(string)
        security_descriptor_copy_flags = optional(string)
        task_queueing                  = optional(string)
        transfer_mode                  = optional(string)
        uid                            = optional(string)
        verify_mode                    = optional(string)
      }))
      schedule_expression = optional(string)
      excludes = optional(list(object({
        filter_type = string
        value       = string
      })))
      includes = optional(list(object({
        filter_type = string
        value       = string
      })))
    }))
  }))
  default = null
}


#--------------------------------------------------------------------
# VPC Endpoints Configuration
#--------------------------------------------------------------------
variable "vpc_endpoints" {
  description = "Configuration for VPC Endpoint"
  type = list(object({
    # Core Configuration
    key                  = optional(string)
    vpc_id               = string
    service_name         = string
    service_name_short   = optional(string)
    endpoint_name        = optional(string)
    endpoint_type        = optional(string)
    auto_accept          = optional(bool)
    create_vpc_endpoints = optional(bool, true)
    # Gateway Endpoint Configuration
    route_table_ids            = optional(list(string), [])
    additional_route_table_ids = optional(list(string))
    # Interface Endpoint Configuration
    subnet_ids          = optional(list(string), [])
    security_group_ids  = optional(list(string), [])
    security_group_keys = optional(list(string), [])
    private_dns_enabled = optional(bool, true)
    dns_record_ip_type  = optional(string)
    # Policy Configuration
    enable_policy   = optional(bool, false)
    policy_document = optional(string)
  }))
  default = null
}


variable "security_groups" {
  description = "The vpc security group"
  type = list(object({
    key         = string
    name        = optional(string)
    name_prefix = optional(string)
    vpc_id      = optional(string)
    description = optional(string)
    vpc_name    = optional(string)
    egress = optional(list(object({
      description     = optional(string)
      from_port       = optional(number)
      to_port         = optional(number)
      protocol        = optional(string)
      security_groups = optional(list(string))
      cidr_blocks     = list(string)
      self            = optional(bool, false)
    })))
    ingress = optional(list(object({
      description     = optional(string)
      from_port       = optional(number)
      to_port         = optional(number)
      protocol        = optional(string)
      security_groups = optional(list(string))
      cidr_blocks     = list(string)
      self            = optional(bool, false)
    })))
  }))
  default = null
}


variable "security_group_rules" {
  description = "The vpc security group rules"
  type = list(object({
    sg_key            = string
    security_group_id = optional(string) # This will be the ID of the security group created
    egress = optional(list(object({
      key           = string
      cidr_ipv4     = string
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
      cidr_ipv4     = string
      cidr_ipv6     = optional(string)
      description   = optional(string)
      from_port     = optional(string)
      to_port       = optional(string)
      ip_protocol   = optional(string)
      source_sg_id  = optional(string)
      source_sg_key = optional(string)
    })))
  }))
  default = null
}

