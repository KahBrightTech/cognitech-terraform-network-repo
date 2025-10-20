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
  deployment_name    = "terraform/${include.cloud.locals.repo_name}-${local.aws_account_name}-${local.deployment}-${local.region_context}"
  cidr_blocks        = local.region_context == "primary" ? include.cloud.locals.cidr_block_use1 : include.cloud.locals.cidr_block_usw2
  state_bucket       = local.region_context == "primary" ? include.env.locals.remote_state_bucket.primary : include.env.locals.remote_state_bucket.secondary
  state_lock_table   = include.env.locals.remote_dynamodb_table
  account_id         = include.cloud.locals.account_info[include.env.locals.name_abr].number
  aws_account_name   = include.cloud.locals.account_info[include.env.locals.name_abr].name
  public_hosted_zone = "${local.vpc_name_abr}.${include.env.locals.public_domain}"
  internet_cidr      = "0.0.0.0/0"
  deployment         = "Shared-account"
  ## Updates these variables as per the product/service
  vpc_name     = "shared-services"
  vpc_name_abr = "shared"

  # Composite variables 
  tags = merge(
    include.env.locals.tags,
    {
      Environment = local.vpc_name
      ManagedBy   = "${local.deployment_name}"
    }
  )
}
#-------------------------------------------------------
# Dependencies 
#-------------------------------------------------------
dependency "network" {
  config_path = "../../../network/Shared-account/${local.region_context}"
}
#-------------------------------------------------------
# Source  
#-------------------------------------------------------
terraform {
  source = "../../../..//formations/Shared-account"
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
      name       = local.vpc_name_abr
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
          vpc_name                    = local.vpc_name_abr
        },
        {
          key                         = include.env.locals.subnet_prefix.secondary
          name                        = include.env.locals.subnet_prefix.secondary
          primary_availability_zone   = local.region_blk.availability_zones.primary
          primary_cidr_block          = local.cidr_blocks[include.env.locals.name_abr].segments[local.vpc_name].public_subnets.sbnt2.primary
          secondary_availability_zone = local.region_blk.availability_zones.secondary
          secondary_cidr_block        = local.cidr_blocks[include.env.locals.name_abr].segments[local.vpc_name].public_subnets.sbnt2.secondary
          subnet_type                 = local.external
          vpc_name                    = local.vpc_name_abr
        }
      ]
      private_subnets = [
        {
          key                         = include.env.locals.subnet_prefix.primary
          name                        = include.env.locals.subnet_prefix.primary
          primary_availability_zone   = local.region_blk.availability_zones.primary
          primary_cidr_block          = local.cidr_blocks[include.env.locals.name_abr].segments[local.vpc_name].private_subnets.sbnt1.primary
          secondary_availability_zone = local.region_blk.availability_zones.secondary
          secondary_cidr_block        = local.cidr_blocks[include.env.locals.name_abr].segments[local.vpc_name].private_subnets.sbnt1.secondary
          subnet_type                 = local.internal
          vpc_name                    = local.vpc_name_abr
        },
        {
          key                         = include.env.locals.subnet_prefix.secondary
          name                        = include.env.locals.subnet_prefix.secondary
          primary_availability_zone   = local.region_blk.availability_zones.primary
          primary_cidr_block          = local.cidr_blocks[include.env.locals.name_abr].segments[local.vpc_name].private_subnets.sbnt2.primary
          secondary_availability_zone = local.region_blk.availability_zones.secondary
          secondary_cidr_block        = local.cidr_blocks[include.env.locals.name_abr].segments[local.vpc_name].private_subnets.sbnt2.secondary
          subnet_type                 = local.internal
          vpc_name                    = local.vpc_name_abr
        }
      ]
      public_routes = {
        destination_cidr_block = "0.0.0.0/0"
      }
      private_routes = {
        destination_cidr_block = "0.0.0.0/0"
      }
      nat_gateway = {
        name     = "nat"
        type     = local.external
        vpc_name = local.vpc_name_abr
      }
      security_groups = [
        {
          key         = "bastion"
          name        = "bastion"
          description = "standard ${local.vpc_name} bastion security group"
          vpc_name    = local.vpc_name_abr
        },
        {
          key         = "alb"
          name        = "alb"
          description = "standard ${local.vpc_name} alb security group"
          vpc_name    = local.vpc_name_abr
        },
        {
          key         = "app"
          name        = "app"
          description = "standard ${local.vpc_name} app security group"
          vpc_name    = local.vpc_name_abr
        },
        {
          key         = "db"
          name        = "db"
          description = "standard ${local.vpc_name} db security group"
          vpc_name    = local.vpc_name_abr
        },
        {
          key         = "efs"
          name        = "efs"
          description = "standard ${local.vpc_name} efs security group"
          vpc_name    = local.vpc_name_abr
        },
        {
          key         = "nlb"
          name        = "nlb"
          description = "standard ${local.vpc_name} nlb security group"
          vpc_name    = local.vpc_name_abr
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
              },
              {
                key         = "ingress-2049-internet"
                cidr_ipv4   = local.internet_cidr
                description = "BASE - Inbound NFS traffic from the internet on tcp port 2049"
                from_port   = 2049
                to_port     = 2049
                ip_protocol = "tcp"
              },
              {
                key         = "ingress-445-internet"
                cidr_ipv4   = local.internet_cidr
                description = "BASE - Inbound NFS traffic from the internet on tcp port 445"
                from_port   = 445
                to_port     = 445
                ip_protocol = "tcp"
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
        },
        {
          sg_key = "efs"
          ingress = [
            {
              key           = "ingress-2049-app-sg"
              source_sg_key = "app"
              description   = "BASE - Inbound traffic from App SG to EFS on tcp port 2049"
              from_port     = 2049
              to_port       = 2049
              ip_protocol   = "tcp"
            }
          ]
          egress = []
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
          name = "${local.vpc_name_abr}.mdprod.com"
        }
      ]
    }
  ]

  s3_private_buckets = [
    {
      name              = "${local.vpc_name_abr}-app-bucket"
      description       = "The application bucket for different apps"
      enable_versioning = true
      policy            = "${include.cloud.locals.repo.root}/iam_policies/s3_app_policy.json"
    },
    {
      name              = "${local.vpc_name_abr}-config-bucket"
      description       = "The configuration bucket for different apps"
      enable_versioning = true
      policy            = "${include.cloud.locals.repo.root}/iam_policies/s3_config_state_policy.json"
    },
    {
      key               = "audit-bucket"
      name              = "${local.vpc_name_abr}-audit-bucket"
      description       = "The audit bucket for different apps"
      enable_versioning = true
      policy            = "${include.cloud.locals.repo.root}/iam_policies/s3_audit_policy.json"
    },
    {
      key               = "software-bucket"
      name              = "${local.vpc_name_abr}-software-bucket"
      description       = "The software bucket for different apps"
      enable_versioning = true
      objects = [
        {
          key = "Ansible_Tower/"
        }
      ]
    }
  ]
  ec2_profiles = [
    {
      name               = "${local.vpc_name_abr}"
      description        = "EC2 Instance Profile for Shared Services"
      assume_role_policy = "${include.cloud.locals.repo.root}/iam_policies/ec2_trust_policy.json"
      managed_policy_arns = [
        "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess",
        "arn:aws:iam::aws:policy/AmazonEC2ReadOnlyAccess",
        "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
        "arn:aws:iam::aws:policy/AdministratorAccess"
      ]
      policy = {
        name        = "${local.vpc_name_abr}-ec2-instance-profile"
        description = "EC2 Instance Permission for instances"
        policy      = "${include.cloud.locals.repo.root}/iam_policies/ec2_instance_permission_for_s3.json"
      }
    }
  ]
  iam_roles = [
    {
      name               = "${local.vpc_name_abr}-default"
      description        = "Default IAM Role for ${local.vpc_name_abr}"
      path               = "/"
      assume_role_policy = "${include.cloud.locals.repo.root}/iam_policies/ec2_trust_policy.json"
      managed_policy_arns = [
        "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess",
        "arn:aws:iam::aws:policy/AmazonEC2ReadOnlyAccess",
        "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
      ]
      policy = {
        name        = "${local.vpc_name_abr}-default"
        description = "${local.vpc_name_abr} default role policy"
        policy      = "${include.cloud.locals.repo.root}/iam_policies/ec2_instance_permission_for_s3.json"
      }
    },
    {
      name               = "${local.vpc_name_abr}-source-replication"
      description        = "IAM Role for ${local.vpc_name_abr} replication rule"
      path               = "/"
      assume_role_policy = "${include.cloud.locals.repo.root}/iam_policies/s3_trust_policy.json"
      policy = {
        name        = "${local.vpc_name_abr}-source-replication"
        description = "IAM policy for ${local.vpc_name_abr} source replication"
        policy      = "${include.cloud.locals.repo.root}/iam_policies/iam_role_for_s3_source_bucket.json"
      }
    },
    {
      name               = "${local.vpc_name_abr}-datasync"
      description        = "IAM Role for ${local.vpc_name_abr} DataSync"
      path               = "/"
      assume_role_policy = "${include.cloud.locals.repo.root}/iam_policies/datasync_trust_policy.json"
      policy = {
        name        = "${local.vpc_name_abr}-datasync"
        description = "IAM policy for ${local.vpc_name_abr} DataSync"
        policy      = "${include.cloud.locals.repo.root}/iam_policies/iam_role_for_datasync.json"
      }
    }
  ]
  iam_users = [
    {
      name                = "${local.vpc_name_abr}-${include.cloud.locals.secret_names.iam_user}"
      description         = "${local.vpc_name_abr} IAM user credentials"
      path                = "/"
      force_destroy       = true
      groups              = ["${local.vpc_name_abr}-Admins"]
      regions             = null
      notifications_email = include.env.locals.owner
      create_access_key   = true
      secrets_manager = {
        name_prefix             = "${local.vpc_name_abr}-${include.cloud.locals.secret_names.iam_user}"
        recovery_window_in_days = 7
        description             = "Access and Secret key for Ansible Service Account"
        policy                  = file("${include.cloud.locals.repo.root}/iam_policies/secrets_manager_policy.json")
      }
      group_policies = [
        {
          group_name  = "${local.vpc_name_abr}-Admins"
          policy_name = "${local.vpc_name_abr}Admin-group-policy"
          description = "${local.vpc_name_abr} Admin group policy"
          policy      = file("${include.cloud.locals.repo.root}/iam_policies/Admin_group_policy.json")
        }
      ]
    }
  ]

  key_pairs = [
    {
      name               = "${local.vpc_name_abr}-key-pair"
      name_prefix        = "${local.vpc_name_abr}-key-pair"
      secret_name        = "${local.vpc_name_abr}-${include.cloud.locals.secret_names.keys}"
      secret_description = "Private key for ${local.vpc_name_abr} VPC"
      policy             = file("${include.cloud.locals.repo.root}/iam_policies/secrets_manager_policy.json")
      create_secret      = true
    }
  ]
  certificates = [
    # {
    #   name              = "${local.vpc_name}"
    #   domain_name       = "*.${local.vpc_name_abr}.${include.env.locals.public_domain}"
    #   validation_method = "DNS"
    #   zone_name         = include.env.locals.public_domain
    # }
  ]
  secrets = [
    {
      key                     = "ansible"
      name_prefix             = include.cloud.locals.secret_names.ansible
      description             = "Ansible tower credentials"
      recovery_window_in_days = 7
      policy                  = file("${include.cloud.locals.repo.root}/iam_policies/secrets_manager_policy.json")
      value = {
        username = "${get_env("TF_VAR_ANSIBLE_TOWER_USERNAME")}"
        password = "${get_env("TF_VAR_ANSIBLE_TOWER_PASSWORD")}"
      }
    },
    {
      key                     = "user" 
      name_prefix             = include.cloud.locals.secret_names.user
      description             = "User credentials for ${local.aws_account_name} environment"
      recovery_window_in_days = 7
      policy                  = file("${include.cloud.locals.repo.root}/iam_policies/secrets_manager_policy.json")
      value = {
        username1 = "${get_env("TF_VAR_USER_USERNAME1")}"
        password1 = "${get_env("TF_VAR_USER_PASSWORD1")}"
        username2 = "${get_env("TF_VAR_USER_USERNAME2")}"
        password2 = "${get_env("TF_VAR_USER_PASSWORD2")}"
      }
    },
    {
      key                     = "docker"
      name_prefix             = include.cloud.locals.secret_names.docker
      description             = "Docker credentials for ${local.aws_account_name} environment"
      recovery_window_in_days = 7
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
      description = "Account User Credentials"
      type        = "String"
      overwrite   = true
      secret_key  = "user"
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
      schedule_expression = "cron(0 8 ? * SUN *)" # Every Sunday at 8 AM
    },
    {
      name               = "Windows-Banner-Config"
      content            = file("${include.cloud.locals.repo.root}/documents/LogonBanner.yaml")
      document_type      = "Command"
      document_format    = "YAML"
      create_association = true
      targets = {
        key    = "tag:WindowsBannerConfig"
        values = ["True"]
      }
      schedule_expression = "cron(0 9 ? * SUN *)" # Every Sunday at 9 AM
    },
    {
      name            = "NFS-Install"
      content         = file("${include.cloud.locals.repo.root}/documents/NFSInstall.yaml")
      document_type   = "Command"
      document_format = "YAML"
    }
  ]
  tgw_attachments = {
    name               = local.vpc_name_abr
    transit_gateway_id = dependency.network.outputs.transit_gateway.transit_gateway_id
    ram = {
      key                       = "${local.vpc_name_abr}-tgw-attachment"
      allow_external_principals = true
      enabled                   = true
      share_name                = "${local.vpc_name_abr}-tgw-attachment"
      principals                = include.cloud.locals.ntw_principals
    }
  }

  tgw_routes = [ # Creates routes in TGW route table to point to spoke VPCs
    # {
    #   name                   = "default-to-dev"
    #   blackhole              = false
    #   attachment_id         = dependency.network.tgw_attachments["development"].id
    #   destination_cidr_block = local.cidr_blocks[include.env.locals.name_abr].segments[local.vpc_name].vpc
    # }
  ]
  tgw_subnet_route = [ # Creates routes in subnet route tables to point to TGW
    {
      name               = "dev-subnet_rt"
      cidr_block         = local.cidr_blocks[include.env.locals.name_abr].segments.app_vpc.development.vpc
      subnet_name        = include.env.locals.subnet_prefix.primary
      transit_gateway_id = dependency.network.outputs.transit_gateway.transit_gateway_id
      vpc_name           = local.vpc_name_abr
    },
    {
      name               = "dev-subnet_rt-secondary"
      cidr_block         = local.cidr_blocks[include.env.locals.name_abr].segments.app_vpc.development.vpc
      subnet_name        = include.env.locals.subnet_prefix.secondary
      transit_gateway_id = dependency.network.outputs.transit_gateway.transit_gateway_id
      vpc_name           = local.vpc_name_abr
    },
    {
      name               = "trn-subnet_rt"
      cidr_block         = local.cidr_blocks[include.env.locals.name_abr].segments.app_vpc.training.vpc
      subnet_name        = include.env.locals.subnet_prefix.primary
      transit_gateway_id = dependency.network.outputs.transit_gateway.transit_gateway_id
      vpc_name           = local.vpc_name_abr
    },
    {
      name               = "trn-subnet_rt-secondary"
      cidr_block         = local.cidr_blocks[include.env.locals.name_abr].segments.app_vpc.training.vpc
      subnet_name        = include.env.locals.subnet_prefix.secondary
      transit_gateway_id = dependency.network.outputs.transit_gateway.transit_gateway_id
      vpc_name           = local.vpc_name_abr
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

