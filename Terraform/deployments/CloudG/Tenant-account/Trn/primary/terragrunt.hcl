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
  region_context   = "primary"
  deploy_globally  = "true"
  internal         = "private"
  external         = "public"
  region           = local.region_context == "primary" ? include.cloud.locals.regions.use1.name : include.cloud.locals.regions.usw2.name
  region_prefix    = local.region_context == "primary" ? include.cloud.locals.region_prefix.primary : include.cloud.locals.region_prefix.secondary
  region_blk       = local.region_context == "primary" ? include.cloud.locals.regions.use1 : include.cloud.locals.regions.usw2
  deployment_name  = "terraform/${include.env.locals.name_abr}-${local.vpc_name}-${local.region_context}"
  cidr_blocks      = local.region_context == "primary" ? include.cloud.locals.cidr_block_use1 : include.cloud.locals.cidr_block_usw2
  state_bucket     = local.region_context == "primary" ? include.env.locals.remote_state_bucket.primary : include.env.locals.remote_state_bucket.secondary
  state_lock_table = include.env.locals.remote_dynamodb_table
  vpc_name         = "trn"
  vpc_name_abr     = "cgtt"
  internet_cidr    = "0.0.0.0/0"
  account_id       = include.cloud.locals.account_info[include.env.locals.name_abr].number
  aws_account_name = include.cloud.locals.account_info[include.env.locals.name_abr].name

  # Composite variables 
  tags = merge(
    include.env.locals.tags,
    {
      Environment = "trn"
      ManagedBy   = "terraform:${local.deployment_name}"
    }
  )
}
#-------------------------------------------------------
# Dependencies 
#-------------------------------------------------------
dependency "shared_services" {
  config_path = "../../../Shared-account/${local.region_context}"
}
#-------------------------------------------------------
# Source  
#-------------------------------------------------------
terraform {
  source = "../../../../..//formations/Simple-Network-Tenant-Account"
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
      cidr_block = local.cidr_blocks[include.env.locals.name_abr].segments.app_vpc[local.vpc_name].vpc
      public_subnets = [
        {
          key                         = include.env.locals.subnet_prefix.primary
          name                        = include.env.locals.subnet_prefix.primary
          primary_availability_zone   = local.region_blk.availability_zones.primary
          primary_cidr_block          = local.cidr_blocks[include.env.locals.name_abr].segments.app_vpc[local.vpc_name].public_subnets.sbnt1.primary
          secondary_availability_zone = local.region_blk.availability_zones.secondary
          secondary_cidr_block        = local.cidr_blocks[include.env.locals.name_abr].segments.app_vpc[local.vpc_name].public_subnets.sbnt1.secondary
          subnet_type                 = local.external
          vpc_name                    = local.vpc_name
        },
        {
          key                         = include.env.locals.subnet_prefix.secondary
          name                        = include.env.locals.subnet_prefix.secondary
          primary_availability_zone   = local.region_blk.availability_zones.primary
          primary_cidr_block          = local.cidr_blocks[include.env.locals.name_abr].segments.app_vpc[local.vpc_name].public_subnets.sbnt2.primary
          secondary_availability_zone = local.region_blk.availability_zones.secondary
          secondary_cidr_block        = local.cidr_blocks[include.env.locals.name_abr].segments.app_vpc[local.vpc_name].public_subnets.sbnt2.secondary
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
            []
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
      key               = "audit-bucket"
      name              = "${local.vpc_name}-audit-bucket"
      description       = "The audit bucket for different apps"
      enable_versioning = true
      policy            = "${include.cloud.locals.repo.root}/iam_policies/s3_audit_policy.json"
    },
  ]
  ec2_profiles = [
    {
      name               = "${local.vpc_name}"
      description        = "EC2 Instance Profile for Shared Services"
      assume_role_policy = "${include.cloud.locals.repo.root}/iam_policies/ec2_trust_policy.json"
      managed_policy_arns = [
        "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess",
        "arn:aws:iam::aws:policy/AmazonEC2ReadOnlyAccess",
        "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
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
  secrets        = []
  ssm_parameters = []
  load_balancers = [
    # {
    #   key             = "${local.vpc_name}"
    #   name            = "${local.vpc_name}"
    #   vpc_name_abr    = "${local.vpc_name_abr}"
    #   type            = "application"
    #   security_groups = ["alb"]
    #   subnets = [
    #     include.env.locals.subnet_prefix.primary
    #   ]
    #   enable_deletion_protection = true
    #   enable_access_logs         = true
    #   access_logs_bucket         = "${local.aws_account_name}-${local.region_prefix}-${local.vpc_name}-audit-bucket"
    #   vpc_name                   = local.vpc_name
    #   create_default_listener    = true
    # },
    # {
    #   key             = "etl"
    #   name            = "etl"
    #   vpc_name_abr    = "${local.vpc_name_abr}"
    #   type            = "application"
    #   security_groups = ["alb"]
    #   subnets = [
    #     include.env.locals.subnet_prefix.primary
    #   ]
    #   enable_deletion_protection = true
    #   enable_access_logs         = true
    #   access_logs_bucket         = "${local.aws_account_name}-${local.region_prefix}-${local.vpc_name}-audit-bucket"
    #   vpc_name                   = local.vpc_name
    #   # create_default_listener    = false
    # },
    # {
    #   key             = "ssrs"
    #   name            = "ssrs"
    #   vpc_name_abr    = "${local.vpc_name_abr}"
    #   type            = "network"
    #   security_groups = ["nlb"]
    #   subnets = [
    #     include.env.locals.subnet_prefix.primary
    #   ]
    #   enable_deletion_protection = true
    #   enable_access_logs         = true
    #   access_logs_bucket         = "${local.aws_account_name}-${local.region_prefix}-${local.vpc_name}-audit-bucket"
    #   vpc_name                   = local.vpc_name
    # }
  ]
  alb_listeners = [
    # {
    #   key      = "etl"
    #   alb_key  = "etl"
    #   protocol = "HTTPS"
    #   port     = 443
    #   action   = "fixed-response"
    #   # certificate_arn = dependency.shared_services.outputs.certificates.shared-services.arn
    #   vpc_name = local.vpc_name
    #   fixed_response = {
    #     content_type = "text/plain"
    #     message_body = "This is a default response from the ETL ALB listener."
    #     status_code  = "200"
    #   }
    # }
  ]
  nlb_listeners = [
    # {
    #   key        = "ssrs"
    #   nlb_key    = "ssrs"
    #   protocol   = "TLS"
    #   port       = 443
    #   ssl_policy = "ELBSecurityPolicy-TLS-1-2-2017-01"
    #   # certificate_arn = dependency.shared_services.outputs.certificates.shared-services.arn
    #   action   = "forward"
    #   vpc_name = local.vpc_name
    #   target_group = {
    #     name         = "ssrs"
    #     protocol     = "TLS"
    #     port         = 443
    #     vpc_name_abr = local.vpc_name_abr
    #     health_check = {
    #       protocol = "HTTPS"
    #       port     = "443"
    #       path     = "/"
    #     }
    #   }
    # }
  ]
  target_groups = [
    # {
    #   key      = "ssrs"
    #   name     = "ssrs"
    #   protocol = "HTTPS"
    #   port     = 443
    #   health_check = {
    #     protocol = "HTTPS"
    #     port     = "443"
    #     path     = "/"
    #   }
    #   vpc_name = local.vpc_name
    # }
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

















