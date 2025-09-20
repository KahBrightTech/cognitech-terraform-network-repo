#-------------------------------------------------------
# Includes Block 
#-------------------------------------------------------

include "cloud" {
  path   = find_in_parent_folders("locals-cloud.hcl")
  expose = true
}

include "env" {
  path   = find_in_parent_folders("locals-env.hcl")
  expose = true
}
#-------------------------------------------------------
# Locals 
#-------------------------------------------------------
locals {
  region_context     = "primary"
  deploy_globally    = "true"
  internal           = "private"
  external           = "public"
  region             = local.region_context == "primary" ? include.cloud.locals.regions.use1.name : include.cloud.locals.regions.usw2.name
  region_prefix      = local.region_context == "primary" ? include.cloud.locals.region_prefix.primary : include.cloud.locals.region_prefix.secondary
  region_blk         = local.region_context == "primary" ? include.cloud.locals.regions.use1 : include.cloud.locals.regions.usw2
  deployment_name    = "terraform/${include.env.locals.name_abr}-${local.vpc_name}-${local.region_context}"
  cidr_blocks        = local.region_context == "primary" ? include.cloud.locals.cidr_block_use1 : include.cloud.locals.cidr_block_usw2
  state_bucket       = local.region_context == "primary" ? include.env.locals.remote_state_bucket.primary : include.env.locals.remote_state_bucket.secondary
  state_lock_table   = include.env.locals.remote_dynamodb_table
  vpc_name           = "shared-services"
  vpc_name_abr       = "shared"
  internet_cidr      = "0.0.0.0/0"
  account_id         = include.cloud.locals.account_info[include.env.locals.name_abr].number
  aws_account_name   = include.cloud.locals.account_info[include.env.locals.name_abr].name
  public_hosted_zone = "${local.vpc_name_abr}.${include.env.locals.public_domain}"

  # Composite variables 
  tags = merge(
    include.env.locals.tags,
    {
      Environment = "shared-services"
      ManagedBy   = "terraform:${local.deployment_name}"
    }
  )
}
#-------------------------------------------------------
# Source  
#-------------------------------------------------------
terraform {
  source = "../../../..//formations/Simple-Network-Shared-Account"
}
#-------------------------------------------------------
# Inputs 
#-------------------------------------------------------
inputs = {
  common = {
    global           = local.deploy_globally
    account_name     = include.cloud.locals.account_info[include.env.locals.name_abr].name
    region_prefix    = local.region_prefix
    tags             = local.tags
    region           = local.region
    account_name_abr = include.env.locals.name_abr
  }
  vpcs = [
    {
      name       = local.vpc_name
      cidr_block = local.cidr_blocks[include.env.locals.name_abr].segments[local.vpc_name].vpc
      public_subnets = [
        {
          key                         = include.env.locals.subnet_prefix.primary
          name                        = include.env.locals.subnet_prefix.primary
          primary_availability_zone   = local.region_blk.availability_zones.primary
          primary_cidr_block          = local.cidr_blocks[include.env.locals.name_abr].segments[local.vpc_name].public_subnets.sbnt1.primary
          secondary_availability_zone = local.region_blk.availability_zones.secondary
          secondary_cidr_block        = local.cidr_blocks[include.env.locals.name_abr].segments[local.vpc_name].public_subnets.sbnt1.secondary
          subnet_type                 = local.external
          vpc_name                    = local.vpc_name
        },
        {
          key                         = include.env.locals.subnet_prefix.secondary
          name                        = include.env.locals.subnet_prefix.secondary
          primary_availability_zone   = local.region_blk.availability_zones.primary
          primary_cidr_block          = local.cidr_blocks[include.env.locals.name_abr].segments[local.vpc_name].public_subnets.sbnt2.primary
          secondary_availability_zone = local.region_blk.availability_zones.secondary
          secondary_cidr_block        = local.cidr_blocks[include.env.locals.name_abr].segments[local.vpc_name].public_subnets.sbnt2.secondary
          subnet_type                 = local.external
          vpc_name                    = local.vpc_name
        }
      ]
      public_routes = {
        destination_cidr_block = "0.0.0.0/0"
      }
      security_groups = [
        {
          key         = "bastion"
          name        = "shared-bastion"
          description = "standrad sharewd bastion security group"
          vpc_name    = local.vpc_name
        },
        {
          key         = "alb"
          name        = "shared-alb"
          description = "standard shared alb security group"
          vpc_name    = local.vpc_name
        },
        {
          key         = "app"
          name        = "shared-app"
          description = "standard shared app security group"
          vpc_name    = local.vpc_name
        },
        {
          key         = "db"
          name        = "shared-db"
          description = "standard shared db security group"
          vpc_name    = local.vpc_name
        },
        {
          key         = "nlb"
          name        = "shared-nlb"
          description = "standard shared nlb security group"
          vpc_name    = local.vpc_name
        }
      ]
      security_group_rules = [
        {
          sg_key = "bastion"
          ingress = concat(
            include.cloud.locals.security_group_rules.locals.ingress.windows_bastion_base,
            include.cloud.locals.security_group_rules.locals.ingress.linux_bastion_base,
            [
              {
                key         = "ingress-22-Account"
                cidr_ipv4   = local.cidr_blocks[include.env.locals.name_abr].segments.Account_cidr
                description = "BASE - Inbound SSH traffic from entire account cidr on tcp port 22"
                from_port   = 22
                to_port     = 22
                ip_protocol = "tcp"
              },
              {
                key         = "ingress-3389-Account"
                cidr_ipv4   = local.cidr_blocks[include.env.locals.name_abr].segments.Account_cidr
                description = "BASE - Inbound SSH traffic from  entire account cidr on tcp port 3389"
                from_port   = 3389
                to_port     = 3389
                ip_protocol = "tcp"
              },
            ]
          )
          egress = concat(
            include.cloud.locals.security_group_rules.locals.egress.windows_bastion_base,
            include.cloud.locals.security_group_rules.locals.egress.linux_bastion_base,
            [
              {
                key         = "egress-all-traffic-bastion-sg"
                cidr_ipv4   = "0.0.0.0/0"
                description = "BASE - Outbound all traffic from Bastion SG to Internet"
                ip_protocol = "-1"
              }
            ]
          )
        },
        {
          sg_key = "alb"
          ingress = concat(
            include.cloud.locals.security_group_rules.locals.ingress.alb_base,
            []
          )
          egress = concat(
            include.cloud.locals.security_group_rules.locals.egress.alb_base,
            [
              {
                key           = "egress-8080-app-sg"
                target_sg_key = "app"
                description   = "BASE - Outbound traffic to App SG to Internet on tcp port 8080"
                from_port     = 8080
                to_port       = 8080
                ip_protocol   = "tcp"
              },
              {
                key           = "egress-8081-app-sg"
                target_sg_key = "app"
                description   = "BASE - Outbound traffic to App SG to Internet on tcp port 8081"
                from_port     = 8081
                to_port       = 8081
                ip_protocol   = "tcp"
              },
              {
                key           = "egress-8082-app-sg"
                target_sg_key = "app"
                description   = "BASE - Outbound traffic to App SG to Internet on tcp port 8082"
                from_port     = 8082
                to_port       = 8082
                ip_protocol   = "tcp"
              },
              {
                key           = "egress-8083-app-sg"
                target_sg_key = "app"
                description   = "BASE - Outbound traffic to App SG to Internet on tcp port 8083"
                from_port     = 8083
                to_port       = 8083
                ip_protocol   = "tcp"
              }
            ]
          )
        },
        {
          sg_key = "nlb"
          ingress = concat(
            include.cloud.locals.security_group_rules.locals.ingress.nlb_base,
            []
          )
          egress = concat(
            include.cloud.locals.security_group_rules.locals.egress.nlb_base,
            []
          )
        },
        {
          sg_key = "app"
          ingress = concat(
            include.cloud.locals.security_group_rules.locals.ingress.app_base,
            [
              {
                key         = "ingress-22-internet"
                cidr_ipv4   = local.internet_cidr
                description = "BASE - Inbound SSH traffic from the internet on tcp port 22"
                from_port   = 22
                to_port     = 22
                ip_protocol = "tcp"
              },
              {
                key         = "ingress-3389-internet"
                cidr_ipv4   = local.internet_cidr
                description = "BASE - Inbound SSH traffic from the internet on tcp port 3389"
                from_port   = 3389
                to_port     = 3389
                ip_protocol = "tcp"
              },
              {
                key           = "ingress-8080-alb-sg"
                source_sg_key = "alb"
                description   = "BASE - Inbound traffic from ALB SG to Internet on tcp port 8080"
                from_port     = 8080
                to_port       = 8080
                ip_protocol   = "tcp"
              },
              {
                key           = "ingress-8081-alb-sg"
                source_sg_key = "alb"
                description   = "BASE - Inbound traffic from ALB SG to Internet on tcp port 8081"
                from_port     = 8081
                to_port       = 8081
                ip_protocol   = "tcp"
              },
              {
                key           = "ingress-8082-alb-sg"
                source_sg_key = "alb"
                description   = "BASE - Inbound traffic from ALB SG to Internet on tcp port 8082"
                from_port     = 8082
                to_port       = 8082
                ip_protocol   = "tcp"
              },
              {
                key           = "ingress-8083-alb-sg"
                source_sg_key = "alb"
                description   = "BASE - Inbound traffic from ALB SG to Internet on tcp port 8083"
                from_port     = 8083
                to_port       = 8083
                ip_protocol   = "tcp"
              }
            ]
          )
          egress = concat(
            include.cloud.locals.security_group_rules.locals.egress.app_base,
            [
              {
                key         = "egress-all-traffic-bastion-sg"
                cidr_ipv4   = "0.0.0.0/0"
                description = "BASE - Outbound all traffic from Bastion SG to Internet"
                ip_protocol = "-1"
              }
            ]
          )
        }
      ]
      s3 = {
        name        = "${local.vpc_name}-data-xfer"
        description = "The bucket used for data transfers"
        policy      = "${include.cloud.locals.repo.root}/iam_policies/s3_data_policy.json"

      }
      route53_zones = [
        {
          key  = local.vpc_name_abr
          name = "${local.vpc_name_abr}.cognitech.com"
        }
      ]
    }
  ]
  s3_private_buckets = [
    {
      name              = "${local.vpc_name}-app-bucket"
      description       = "The application bucket for different apps"
      enable_versioning = true
      policy            = "${include.cloud.locals.repo.root}/iam_policies/s3_app_policy.json"
    },
    {
      name              = "${local.vpc_name}-config-bucket"
      description       = "The configuration bucket for different apps"
      enable_versioning = true
      policy            = "${include.cloud.locals.repo.root}/iam_policies/s3_config_state_policy.json"
    },

    {
      name                 = "${local.vpc_name}-src-replication-bucket"
      description          = "The source replication bucket"
      enable_versioning    = true
      enable_bucket_policy = false
      # encryption = {
      #   enabled            = true
      #   sse_algorithm      = "aws:kms"
      #   kms_master_key_id  = "arn:aws:kms:us-east-1:730335294148:key/784d68ea-880c-4755-ae12-beb3037aefc2"
      #   bucket_key_enabled = false
      # }
      # replication = {
      #   role_arn = "arn:aws:iam::${local.account_id}:role/${local.aws_account_name}-${local.region_prefix}-${local.vpc_name}-source-replication-role"
      #   rules = [
      #     {
      #       id     = "replication-rule-1"
      #       status = "Enabled"
      #       destination = {
      #         bucket_arn    = "arn:aws:s3:::mdproduction-use1-shared-services-dest-replication-bucket"
      #         storage_class = "STANDARD"
      #         access_control_translation = {
      #           owner = "Destination"
      #         }
      #         account_id = "485147667400"
      #         replication_time = {
      #           minutes = "15"
      #         }
      #         encryption_configuration = {
      #           replica_kms_key_id = "arn:aws:kms:${local.region}:485147667400:key/mrk-587301af90c9440c813284f882515d18"
      #         }
      #         replica_modification = {
      #           enabled = true
      #         }
      #       }
      #     }
      #   ]
      # }
    },
    {
      key               = "audit-bucket"
      name              = "${local.vpc_name}-audit-bucket"
      description       = "The audit bucket for different apps"
      enable_versioning = true
      policy            = "${include.cloud.locals.repo.root}/iam_policies/s3_audit_policy.json"
    },
    {
      key               = "report-bucket"
      name              = "${local.vpc_name}-report-bucket"
      description       = "The report bucket for different apps"
      enable_versioning = true
      policy            = "${include.cloud.locals.repo.root}/iam_policies/s3_batch_report_bucket.json"
    },
    {
      key               = "software-bucket"
      name              = "${local.vpc_name}-software-bucket"
      description       = "The software bucket for different apps"
      enable_versioning = true
      objects = [
        {
          key = "Ansible_Tower/"
        }
      ]
    },
    {
      key               = "datasync-bucket"
      name              = "${local.vpc_name}-datasync-bucket"
      description       = "The data sync bucket for different apps"
      enable_versioning = true
      objects = [
        {
          key = "Data/"
        }
      ]
    }
  ]
  ec2_profiles = [
    {
      name               = "${local.vpc_name}"
      description        = "EC2 Instance Profile for Shared Services"
      assume_role_policy = "${include.cloud.locals.repo.root}/iam_policies/ec2_trust_policy.json"
      managed_policy_arns = [
        "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess",
        "arn:aws:iam::aws:policy/AmazonEC2ReadOnlyAccess",
        "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
        "arn:aws:iam::aws:policy/AdministratorAccess"
      ]
      policy = {
        name        = "${local.vpc_name}-ec2-instance-profile"
        description = "EC2 Instance Permission for S3"
        policy      = "${include.cloud.locals.repo.root}/iam_policies/ec2_instance_permission_for_s3.json"
      }
    }
  ]
  iam_roles = [
    {
      name               = "${local.vpc_name}-instance"
      description        = "IAM Role for Shared Services"
      path               = "/"
      assume_role_policy = "${include.cloud.locals.repo.root}/iam_policies/ec2_trust_policy.json"
      managed_policy_arns = [
        "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess",
        "arn:aws:iam::aws:policy/AmazonEC2ReadOnlyAccess",
        "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
      ]
      policy = {
        name        = "${local.vpc_name}-instance"
        description = "Test IAM policy"
        policy      = "${include.cloud.locals.repo.root}/iam_policies/ec2_instance_permission_for_s3.json"
      }
    },
    {
      name               = "${local.vpc_name}-source-replication"
      description        = "IAM Role for Shared Services replication rule"
      path               = "/"
      assume_role_policy = "${include.cloud.locals.repo.root}/iam_policies/s3_trust_policy.json"
      policy = {
        name        = "${local.vpc_name}-source-replication"
        description = "IAM policy for source replication"
        policy      = "${include.cloud.locals.repo.root}/iam_policies/iam_role_for_s3_source_bucket.json"
      }
    },
    {
      name               = "${local.vpc_name}-datasync-role"
      description        = "IAM Role for Shared Services DataSync"
      path               = "/"
      assume_role_policy = "${include.cloud.locals.repo.root}/iam_policies/datasync_trust_policy.json"
      policy = {
        name        = "${local.vpc_name}-datasync-role"
        description = "IAM policy for DataSync"
        policy      = "${include.cloud.locals.repo.root}/iam_policies/iam_role_for_datasync.json"
      }
    }
  ]
  iam_users = [
    {
      name                = "ansible-user"
      description         = "Ansible user credentials"
      path                = "/"
      force_destroy       = true
      groups              = ["Admins"]
      regions             = null
      notifications_email = include.env.locals.owner
      create_access_key   = true
      secrets_manager = {
        recovery_window_in_days = 7
        description             = "Access and Secret key for Ansible Service Account"
        policy                  = file("${include.cloud.locals.repo.root}/iam_policies/secrets_manager_policy.json")
      }
      group_policies = [
        {
          group_name  = "Admins"
          policy_name = "Admin-group-policy"
          description = "Admin group policy"
          policy      = file("${include.cloud.locals.repo.root}/iam_policies/Admin_group_policy.json")
        }
      ]
    }
  ]
  key_pairs = [
    {
      name               = "${local.vpc_name}-key-pair"
      secret_name        = "${local.vpc_name}-ec2-private-key"
      secret_description = "Private key for ${local.vpc_name} VPC"
      policy             = file("${include.cloud.locals.repo.root}/iam_policies/secrets_manager_policy.json")
      create_secret      = true
    }
  ]
  certificates = [
    {
      name              = "${local.vpc_name}"
      domain_name       = "*.${local.vpc_name_abr}.${include.env.locals.public_domain}"
      validation_method = "DNS"
      zone_name         = include.env.locals.public_domain
    }
  ]
  secrets = [
    {
      name                    = "Ansible-Credentials"
      description             = "Ansible tower credentials"
      recovery_window_in_days = 0
      policy                  = file("${include.cloud.locals.repo.root}/iam_policies/secrets_manager_policy.json")
      value = {
        username = "${get_env("TF_VAR_ANSIBLE_TOWER_USERNAME")}"
        password = "${get_env("TF_VAR_ANSIBLE_TOWER_PASSWORD")}"
      }
    },
    {
      name                    = "User-Credentials"
      description             = "User credentials for ${local.aws_account_name} environment"
      recovery_window_in_days = 0
      policy                  = file("${include.cloud.locals.repo.root}/iam_policies/secrets_manager_policy.json")
      value = {
        username1 = "${get_env("TF_VAR_USER_USERNAME1")}"
        password1 = "${get_env("TF_VAR_USER_PASSWORD1")}"
        username2 = "${get_env("TF_VAR_USER_USERNAME2")}"
        password2 = "${get_env("TF_VAR_USER_PASSWORD2")}"
      }
    },
    {
      name                    = "Docker-Credentials"
      description             = "Docker credentials for ${local.aws_account_name} environment"
      recovery_window_in_days = 0
      policy                  = file("${include.cloud.locals.repo.root}/iam_policies/secrets_manager_policy.json")
      value = {
        username = "${get_env("TF_VAR_DOCKER_USERNAME")}"
        password = "${get_env("TF_VAR_DOCKER_PASSWORD")}"
      }
    }
  ]
  ssm_parameters = [
    {
      name        = "/Standard/ansible/username"
      description = "Ansible Tower Username"
      type        = "String"
      value       = "${get_env("TF_VAR_ANSIBLE_TOWER_USERNAME")}"
    },
    {
      name        = "/Standard/ansible/password"
      description = "Ansible Tower Password"
      type        = "String"
      value       = "${get_env("TF_VAR_ANSIBLE_TOWER_PASSWORD")}"
    },
    {
      name        = "/Standard/ansible/bucketName"
      description = "Ansible Tower Bucket Name"
      type        = "String"
      value       = "ansibleautomationbucket"
    },
    {
      name        = "/Standard/account/UserCredentials"
      description = "Ansible Tower User Credentials"
      type        = "String"
      overwrite   = true
      value       = "${local.aws_account_name}-${local.region_prefix}-User-Credentials"
    }
  ]
  backups = [
    {
      name       = "${local.aws_account_name}-${local.region_prefix}-backup-vault"
      kms_key_id = include.env.locals.kms_key_id.primary
      plan = {
        name = "${local.aws_account_name}-${local.region_prefix}-backup-plan"
        rules = [
          {
            rule_name         = "DailyBackup"
            schedule          = "cron(0 15 ? * * *)"
            start_window      = 60
            completion_window = 120
            lifecycle = {
              delete_after_days = 30
            }
            copy_actions = [
              {
                destination_vault_arn = "arn:aws:backup:us-west-2:${local.account_id}:backup-vault:${local.aws_account_name}-usw2-backup-vault"
                lifecycle = {
                  cold_storage_after_days = 30
                }
              }
            ]
          },
          {
            rule_name         = "WeeklyBackup"
            schedule          = "cron(0 15 ? * 1 *)"
            start_window      = 120
            completion_window = 360
            lifecycle = {
              cold_storage_after_days = 60
              delete_after_days       = 180
            }
            copy_actions = [
              {
                destination_vault_arn = "arn:aws:backup:us-west-2:${local.account_id}:backup-vault:${local.aws_account_name}-usw2-backup-vault"
                lifecycle = {
                  cold_storage_after_days = 60
                  delete_after_days       = 180
                }
              }
            ]
          }
        ]
        selection = {
          selection_name = "${local.aws_account_name}-${local.region_prefix}-backup-selection"
          selection_tags = [
            {
              type  = "STRINGEQUALS"
              key   = "Backup"
              value = "${local.aws_account_name}-${local.region_prefix}-continous-backup"
            }
          ]
        }
      }
    }
  ]
  ssm_documents = [
    {
      name               = "ansible-tower-install"
      content            = file("${include.cloud.locals.repo.root}/documents/AnsibleInstall.yaml")
      document_type      = "Command"
      document_format    = "YAML"
      create_association = true
      targets = {
        key    = "tag:AnsibleInstall"
        values = ["True"]
      }
      schedule_expression = "cron(0 2 ? * SUN *)" # Every Sunday at 2 AM
    },
    {
      name               = "universal-user-credentials"
      content            = file("${include.cloud.locals.repo.root}/documents/UniversalUserCreation.yaml")
      document_type      = "Command"
      document_format    = "YAML"
      create_association = true
      targets = {
        key    = "tag:CreateUser"
        values = ["True"]
      }
      schedule_expression = "cron(0 3 ? * SUN *)" # Every Sunday at 3 AM
    },
    {
      name               = "Docker-Install"
      content            = file("${include.cloud.locals.repo.root}/documents/DockerInstall.yaml")
      document_type      = "Command"
      document_format    = "YAML"
      create_association = true
      targets = {
        key    = "tag:DockerInstall"
        values = ["True"]
      }
      schedule_expression = "cron(0 8 ? * SUN *)" # Every Sunday at 8 AM
    },
    {
      name               = "WinRM-Config"
      content            = file("${include.cloud.locals.repo.root}/documents/WinRM.yaml")
      document_type      = "Command"
      document_format    = "YAML"
      create_association = true
      targets = {
        key    = "tag:WinRMInstall"
        values = ["True"]
      }
      schedule_expression = "cron(0 7 ? * SUN *)" # Every Sunday at 7 AM
    }
  ]
  load_balancers = [
    # {
    #   key             = "app"
    #   name            = "app"
    #   vpc_name_abr    = "${local.vpc_name_abr}"
    #   type            = "application"
    #   security_groups = ["alb"]
    #   subnets = [
    #     include.env.locals.subnet_prefix.primary
    #   ]
    #   enable_deletion_protection = false
    #   enable_access_logs         = true
    #   access_logs_bucket         = "${local.aws_account_name}-${local.region_prefix}-${local.vpc_name}-audit-bucket"
    #   vpc_name                   = local.vpc_name
    #   create_default_listener    = true
    # },
    # {
    #   key             = " etl "
    #   name            = " etl "
    #   vpc_name_abr    = " $ { local.vpc_name_abr } "
    #   type            = " application "
    #   security_groups = [" alb "]
    #   subnets = [
    #     include.env.locals.subnet_prefix.primary
    #   ]
    #   enable_deletion_protection = true
    #   enable_access_logs         = true
    #   access_logs_bucket         = " $ { local.aws_account_name } - $ { local.region_prefix } - $ { local.vpc_name } - audit-bucket "
    #   vpc_name                   = local.vpc_name
    # },
    # {
    #   key             = " ssrs "
    #   name            = " ssrs "
    #   vpc_name_abr    = " $ { local.vpc_name_abr } "
    #   type            = " network "
    #   security_groups = [" nlb "]
    #   subnets = [
    #     include.env.locals.subnet_prefix.primary
    #   ]
    #   enable_deletion_protection = false
    #   enable_access_logs         = true
    #   access_logs_bucket         = " $ { local.aws_account_name } - $ { local.region_prefix } - $ { local.vpc_name } - audit-bucket "
    #   vpc_name                   = local.vpc_name
    # }
  ]

  alb_listeners = [
    # {
    #   key      = " etl "
    #   alb_key  = " etl "
    #   protocol = " HTTPS "
    #   port     = 443
    #   action   = " fixed-response "
    #   vpc_name = local.vpc_name
    #   fixed_response = {
    #     content_type = " text / plain "
    #     message_body = " This is a default response from the ETL ALB listener."
    #     status_code  = " 200 "
    #   }
    # }
  ]
  alb_listener_rules = [
    # {
    #   index_key    = " etl "
    #   listener_key = " etl "
    #   rules = [
    #     {
    #       key      = " etl "
    #       priority = 10
    #       type     = " forward "
    #       target_groups = [
    #         {
    #           tg_name = " etl "
    #           weight  = 99
    #         }
    #       ]
    #       conditions = [
    #         {
    #           host_headers = [
    #             " etl.$ { local.public_hosted_zone } ",
    #           ]
    #         }
    #       ]
    #     }
    #   ]
    # }
  ]
  nlb_listeners = [
    # {
    #   key        = " ssrs "
    #   nlb_key    = " ssrs "
    #   protocol   = " TLS "
    #   port       = 443
    #   ssl_policy = " ELBSecurityPolicy-TLS-1-2-2017-01 "
    #   action     = " forward "
    #   vpc_name   = local.vpc_name
    #   target_group = {
    #     name         = " ssrs "
    #     protocol     = " TLS "
    #     port         = 443
    #     vpc_name_abr = local.vpc_name_abr
    #     health_check = {
    #       protocol = " HTTPS "
    #       port     = " 443 "
    #       path     = " / "
    #     }
    #   }
    # }
  ]
  target_groups = [
    # {
    #   key      = " etl "
    #   name     = " etl "
    #   protocol = " HTTPS "
    #   port     = 443
    #   health_check = {
    #     protocol = " HTTPS "
    #     port     = " 443 "
    #     path     = " / "
    #   }
    #   vpc_name     = local.vpc_name
    #   vpc_name_abr = " $ { local.vpc_name_abr } "
    # }
  ]
  datasync_locations = [
    s3_location = [
      {
        key                    = "s3"
        s3_bucket_arn          = "arn:aws:s3:::${local.vpc_name}-datasync-bucket"
        subdirectory           = include.env.locals.datasync.s3.subdirectory.datasync_bucket
        bucket_access_role_arn = "arn:aws:iam::${local.account_id}:role/${local.aws_account_name}-${local.region_prefix}-${local.vpc_name}-datasync-role"
      }
    ]
    nfs_location = [
      {
        key             = "nfs"
        server_hostname = include.env.locals.datasync.nfs.server_hostname.wsl
        subdirectory    = include.env.locals.datasync.nfs.subdirectory.wsl
        on_prem_config = {
          agent_arns = include.env.locals.datasync.agent_arns.int
        }
      }
    ]
  ]
  datasync_tasks = [
    {
      create_cloudwatch_log_group = true
      cloudwatch_log_group_name   = "nfstos3"
      task = {
        name            = "${local.vpc_name}-nfs-to-s3"
        source_key      = "nfs"
        destination_key = "s3"
        options = {
          verify_mode            = "POINT_IN_TIME_CONSISTENT"
          overwrite_mode         = "ALWAYS"
          atime                  = "BEST_EFFORT"
          mtime                  = "PRESERVE"
          uid                    = "INT_VALUE"
          gid                    = "INT_VALUE"
          preserve_deleted_files = "PRESERVE"
          preserve_devices       = "NONE"
          posix_permissions      = "PRESERVE"
        }
      }
      schedule = {
        schedule_expression = "cron(0 5 ? * * *)" # Every day at 5 AM
      }
    }
  ]
}
#-------------------------------------------------------
# State Configuration
#-------------------------------------------------------
remote_state {
  backend = "s3"
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite"
  }
  config = {
    bucket               = local.state_bucket
    bucket_sse_algorithm = "AES256"
    dynamodb_table       = local.state_lock_table
    encrypt              = true
    key                  = "${local.deployment_name}/terraform.tfstate"
    region               = local.region
  }
}
#-------------------------------------------------------
# Providers 
#-------------------------------------------------------
generate "aws-providers" {
  path      = "aws-provider.tf"
  if_exists = "overwrite"
  contents  = <<-EOF
  provider "aws" {
    region = "${local.region}"
  }
  EOF
}






