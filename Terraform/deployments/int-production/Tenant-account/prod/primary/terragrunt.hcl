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
  deployment_name    = "terraform/${include.cloud.locals.repo_name}-${local.aws_account_name}-${local.deployment}-${local.vpc_name_abr}-${local.region_context}"
  cidr_blocks        = local.region_context == "primary" ? include.cloud.locals.cidr_block_use1 : include.cloud.locals.cidr_block_usw2
  state_bucket       = local.region_context == "primary" ? include.env.locals.remote_state_bucket.primary : include.env.locals.remote_state_bucket.secondary
  state_lock_table   = include.env.locals.remote_dynamodb_table
  account_id         = include.cloud.locals.account_info[include.env.locals.name_abr].number
  aws_account_name   = include.cloud.locals.account_info[include.env.locals.name_abr].name
  public_hosted_zone = "${local.vpc_name_abr}.${include.env.locals.public_domain}"
  internet_cidr      = "0.0.0.0/0"
  deployment         = "Tenant-account"
  ## Updates these variables as per the product/service
  vpc_name            = "production"
  vpc_name_abr        = "prod"
  create_eks_cluster  = false
  create_ecs_cluster  = false
  create_postgres_rds = false
  create_mysql_rds    = false
  vpn_ip              = "69.143.134.56/32"


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
dependency "platform" {
  config_path = "../../../Shared-account/${local.region_context}"
}
#-------------------------------------------------------
# Source  
#-------------------------------------------------------
terraform {
  source = "../../../../..//formations/Tenant-account"
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
          vpc_name                    = local.vpc_name_abr
        },
        {
          key                         = include.env.locals.subnet_prefix.secondary
          name                        = include.env.locals.subnet_prefix.secondary
          primary_availability_zone   = local.region_blk.availability_zones.primary
          primary_cidr_block          = local.cidr_blocks[include.env.locals.name_abr].segments.app_vpc[local.vpc_name].public_subnets.sbnt2.primary
          secondary_availability_zone = local.region_blk.availability_zones.secondary
          secondary_cidr_block        = local.cidr_blocks[include.env.locals.name_abr].segments.app_vpc[local.vpc_name].public_subnets.sbnt2.secondary
          subnet_type                 = local.external
          vpc_name                    = local.vpc_name_abr
        }
      ]
      # private_subnets = [
      #   {
      #     key                         = include.env.locals.subnet_prefix.primary
      #     name                        = include.env.locals.subnet_prefix.primary
      #     primary_availability_zone   = local.region_blk.availability_zones.primary
      #     primary_cidr_block          = local.cidr_blocks[include.env.locals.name_abr].segments[local.vpc_name].private_subnets.sbnt1.primary
      #     secondary_availability_zone = local.region_blk.availability_zones.secondary
      #     secondary_cidr_block        = local.cidr_blocks[include.env.locals.name_abr].segments[local.vpc_name].private_subnets.sbnt1.secondary
      #     subnet_type                 = local.internal
      #     vpc_name                    = local.vpc_name_abr
      #   },
      #   {
      #     key                         = include.env.locals.subnet_prefix.secondary
      #     name                        = include.env.locals.subnet_prefix.secondary
      #     primary_availability_zone   = local.region_blk.availability_zones.primary
      #     primary_cidr_block          = local.cidr_blocks[include.env.locals.name_abr].segments[local.vpc_name].private_subnets.sbnt2.primary
      #     secondary_availability_zone = local.region_blk.availability_zones.secondary
      #     secondary_cidr_block        = local.cidr_blocks[include.env.locals.name_abr].segments[local.vpc_name].private_subnets.sbnt2.secondary
      #     subnet_type                 = local.internal
      #     vpc_name                    = local.vpc_name_abr
      #   }
      # ]
      # private_routes = {
      #   destination_cidr_block = "0.0.0.0/0"
      # }
      # nat_gateway = {
      #   name     = "nat"
      #   type     = local.external
      #   vpc_name = local.vpc_name_abr
      # }
      public_routes = {
        destination_cidr_block = "0.0.0.0/0"
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
        },
        {
          key         = "ecs-nlb-internal"
          name        = "ecs-nlb-internal"
          description = "standard ${local.vpc_name} ecs nlb internal security group"
          vpc_name    = local.vpc_name_abr
        },
        {
          key         = "ecs-frontend"
          name        = "ecs-frontend"
          description = "standard ${local.vpc_name} ecs frontend service security group"
          vpc_name    = local.vpc_name_abr
        },
        {
          key         = "ecs-backend"
          name        = "ecs-backend"
          description = "standard ${local.vpc_name} ecs backend service security group"
          vpc_name    = local.vpc_name_abr
        },
        {
          key         = "ecs-database"
          name        = "ecs-database"
          description = "standard ${local.vpc_name} ecs database service security group"
          vpc_name    = local.vpc_name_abr
        },
        {
          key         = "ecs-instance"
          name        = "ecs-instance"
          description = "standard ${local.vpc_name} ecs instance security group"
          vpc_name    = local.vpc_name_abr
        },
        {
          key         = "firehose"
          name        = "firehose"
          description = "standard ${local.vpc_name} firehose service security group"
          vpc_name    = local.vpc_name_abr
        },
        {
          key         = "opensearch"
          name        = "opensearch"
          description = "standard ${local.vpc_name} opensearch service security group"
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
                description   = "BASE - Outbound traffic to App SG on tcp port 8081"
                from_port     = 8081
                to_port       = 8081
                ip_protocol   = "tcp"
              },
              {
                key           = "egress-8082-app-sg"
                target_sg_key = "app"
                description   = "BASE - Outbound traffic to App SG on tcp port 8082"
                from_port     = 8082
                to_port       = 8082
                ip_protocol   = "tcp"
              },
              {
                key           = "egress-8083-app-sg"
                target_sg_key = "app"
                description   = "BASE - Outbound traffic to App SG on tcp port 8083"
                from_port     = 8083
                to_port       = 8083
                ip_protocol   = "tcp"
              },
              {
                key           = "egress-30000-32767-app-sg"
                target_sg_key = "app"
                description   = "BASE - Outbound traffic to App SG on tcp port 30000-32767"
                from_port     = 30000
                to_port       = 32767
                ip_protocol   = "tcp"
              },
              {
                key           = "egress-80-ecs-frontend-sg"
                target_sg_key = "ecs-frontend"
                description   = "ECS - Outbound HTTP traffic to ECS Service SG on tcp port 80"
                from_port     = 80
                to_port       = 80
                ip_protocol   = "tcp"
              },
              {
                key           = "egress-443-ecs-frontend-sg"
                target_sg_key = "ecs-frontend"
                description   = "ECS - Outbound HTTPS traffic to ECS Service SG on tcp port 443"
                from_port     = 443
                to_port       = 443
                ip_protocol   = "tcp"
              },
              {
                key           = "egress-dynamic-ports-ecs-frontend-sg"
                target_sg_key = "ecs-frontend"
                description   = "ECS - Outbound traffic to ECS Service SG on dynamic ports 32768-65535"
                from_port     = 32768
                to_port       = 65535
                ip_protocol   = "tcp"
              }
            ]
          )
        },
        {
          sg_key  = "firehose"
          ingress = []
          egress = [
            {
              key         = "egress-all-traffic"
              cidr_ipv4   = "0.0.0.0/0"
              description = "BASE - Outbound all traffic to the Internet"
              ip_protocol = "-1"
            }
          ]
        },
        {
          sg_key = "opensearch"
          ingress = [
            {
              key           = "ingress-443-firehose-sg"
              source_sg_key = "firehose"
              description   = "BASE - Inbound traffic from Firehose SG to OpenSearch on tcp port 443"
              from_port     = 443
              to_port       = 443
              ip_protocol   = "tcp"
            }
          ]
          egress = [
            {
              key         = "egress-all-traffic"
              cidr_ipv4   = "0.0.0.0/0"
              description = "BASE - Outbound all traffic to the Internet"
              ip_protocol = "-1"
            }
          ]
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
                key           = "ingress-3000-alb-sg"
                source_sg_key = "alb"
                description   = "BASE - Inbound traffic from ALB SG to Internet on tcp port 3000"
                from_port     = 3000
                to_port       = 3000
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
              },
              {
                key           = "ingress-30000-32767-alb-sg"
                source_sg_key = "alb"
                description   = "BASE - Inbound traffic from ALB SG on tcp port 30000-32767"
                from_port     = 30000
                to_port       = 32767
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
        },
        {
          sg_key = "db"
          ingress = [
            {
              key         = "ingress-3306-vpn_ip"
              cidr_ipv4   = local.vpn_ip
              description = "BASE - Inbound MySQL traffic from the VPN on tcp port 3306"
              from_port   = 3306
              to_port     = 3306
              ip_protocol = "tcp"
            },
            {
              key           = "ingress-ecs-backend-3306-sg"
              source_sg_key = "ecs-backend"
              description   = "BASE - Inbound traffic from ECS Backend SG to Backend on tcp port 3306"
              from_port     = 3306
              to_port       = 3306
              ip_protocol   = "tcp"
            },
            {
              key           = "ingress-ecs-backend-5432-sg"
              source_sg_key = "ecs-backend"
              description   = "BASE - Inbound traffic from ECS Backend SG to Backend on tcp port 5432"
              from_port     = 5432
              to_port       = 5432
              ip_protocol   = "tcp"
            }
          ]
          egress = []
        },
        {
          sg_key = "ecs-frontend"
          ingress = [
            {
              key           = "ingress-80-alb-sg"
              source_sg_key = "alb"
              description   = "ECS - Inbound HTTP traffic from ALB SG on tcp port 80"
              from_port     = 80
              to_port       = 80
              ip_protocol   = "tcp"
            },
            {
              key           = "ingress-443-alb-sg"
              source_sg_key = "alb"
              description   = "ECS - Inbound HTTPS traffic from ALB SG on tcp port 443"
              from_port     = 443
              to_port       = 443
              ip_protocol   = "tcp"
            }
          ]
          egress = [
            {
              key           = "egress-3000-ecs-nlb-internal-sg"
              target_sg_key = "ecs-nlb-internal"
              description   = "ECS - Outbound traffic to NLB Internal SG on tcp port 3000"
              from_port     = 3000
              to_port       = 3000
              ip_protocol   = "tcp"
            },
            {
              key           = "egress-8080-ecs-backend-sg"
              target_sg_key = "ecs-backend"
              description   = "ECS - Outbound traffic to Backend SG on tcp port 8080"
              from_port     = 8080
              to_port       = 8080
              ip_protocol   = "tcp"
            },
            {
              key           = "egress-3000-ecs-backend-sg"
              target_sg_key = "ecs-backend"
              description   = "ECS - Outbound traffic to Backend SG on tcp port 3000"
              from_port     = 3000
              to_port       = 3000
              ip_protocol   = "tcp"
            },
            {
              key         = "egress-all-traffic-ecs-frontend"
              cidr_ipv4   = "0.0.0.0/0"
              description = "ECS - Outbound all traffic from ECS Frontend to Internet"
              ip_protocol = "-1"
            }
          ]
        },
        {
          sg_key = "ecs-nlb-internal"
          ingress = [
            {
              key           = "ingress-3000-ecs-frontend-sg"
              source_sg_key = "ecs-frontend"
              description   = "BASE - Inbound traffic from ECS Frontend SG to NLB Internal on tcp port 3000"
              from_port     = 3000
              to_port       = 3000
              ip_protocol   = "tcp"
            },
          ]
          egress = [
            {
              key           = "egress-3000-ecs-backend-sg"
              target_sg_key = "ecs-backend"
              description   = "ECS - Outbound traffic to Backend SG on tcp port 3000"
              from_port     = 3000
              to_port       = 3000
              ip_protocol   = "tcp"
            }
          ]
        },
        {
          sg_key = "ecs-backend"
          ingress = [
            {
              key           = "ingress-3000-ecs-nlb-internal-sg"
              source_sg_key = "ecs-nlb-internal"
              description   = "ECS - Inbound traffic from NLB Internal SG on tcp port 3000"
              from_port     = 3000
              to_port       = 3000
              ip_protocol   = "tcp"
            },
            {
              key           = "ingress-3000-ecs-frontend-sg"
              source_sg_key = "ecs-frontend"
              description   = "ECS - Inbound traffic from ECS Frontend SG on tcp port 3000"
              from_port     = 3000
              to_port       = 3000
              ip_protocol   = "tcp"
            }
          ]
          egress = [
            {
              key           = "egress-3306-ecs-database-sg"
              target_sg_key = "ecs-database"
              description   = "ECS - Outbound traffic to Database SG on tcp port 3306"
              from_port     = 3306
              to_port       = 3306
              ip_protocol   = "tcp"
            },
            {
              key           = "egress-3306-db-sg"
              target_sg_key = "db"
              description   = "ECS - Outbound traffic to DB SG on tcp port 3306"
              from_port     = 3306
              to_port       = 3306
              ip_protocol   = "tcp"
            },
            {
              key           = "egress-5432-db-sg"
              target_sg_key = "db"
              description   = "ECS - Outbound traffic to DB SG on tcp port 5432"
              from_port     = 5432
              to_port       = 5432
              ip_protocol   = "tcp"
            },
            {
              key           = "egress-5432-ecs-database-sg"
              target_sg_key = "ecs-database"
              description   = "ECS - Outbound traffic to Database SG on tcp port 5432"
              from_port     = 5432
              to_port       = 5432
              ip_protocol   = "tcp"
            },
            {
              key         = "egress-all-traffic-ecs-backend"
              cidr_ipv4   = "0.0.0.0/0"
              description = "ECS - Outbound all traffic from ECS Backend to Internet"
              ip_protocol = "-1"
            }
          ]
        },
        {
          sg_key = "ecs-database"
          ingress = [
            {
              key           = "ingress-3306-ecs-backend-sg"
              source_sg_key = "ecs-backend"
              description   = "ECS - Inbound MySQL traffic from Backend SG on tcp port 3306"
              from_port     = 3306
              to_port       = 3306
              ip_protocol   = "tcp"
            },
            {
              key           = "ingress-5432-ecs-backend-sg"
              source_sg_key = "ecs-backend"
              description   = "ECS - Inbound PostgreSQL traffic from Backend SG on tcp port 5432"
              from_port     = 5432
              to_port       = 5432
              ip_protocol   = "tcp"
            }
          ]
          egress = []
        },
        {
          sg_key = "ecs-instance"
          ingress = [
            {
              key           = "ingress-all-ecs-frontend-sg"
              source_sg_key = "ecs-frontend"
              description   = "ECS - Inbound traffic from ECS Frontend SG"
              ip_protocol   = "-1"
            },
            {
              key           = "ingress-all-ecs-backend-sg"
              source_sg_key = "ecs-backend"
              description   = "ECS - Inbound traffic from ECS Backend SG"
              ip_protocol   = "-1"
            },
            {
              key           = "ingress-all-ecs-database-sg"
              source_sg_key = "ecs-database"
              description   = "ECS - Inbound traffic from ECS Database SG"
              ip_protocol   = "-1"
            }
          ]
          egress = [
            {
              key         = "egress-all-traffic-ecs-instance"
              cidr_ipv4   = "0.0.0.0/0"
              description = "ECS - Outbound all traffic from ECS Instance to Internet"
              ip_protocol = "-1"
            }
          ]
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
      name              = "${local.vpc_name_abr}-app-bucket"
      description       = "The application bucket for different apps"
      enable_versioning = true
      policy            = "${include.cloud.locals.repo.root}/iam_policies/s3_app_policy.json"
    },
    {
      name              = "${local.vpc_name_abr}-firehose-backup"
      description       = "The Firehose bucket for different apps"
      enable_versioning = true
      policy            = "${include.cloud.locals.repo.root}/iam_policies/s3_firehose_bucket.json"
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

  ec2_profiles = []
  iam_roles    = []
  iam_users    = []
  key_pairs    = []
  certificates = [
    {
      name              = "${local.vpc_name_abr}"
      domain_name       = "*.${local.vpc_name_abr}.${include.env.locals.public_domain}"
      validation_method = "DNS"
      zone_name         = include.env.locals.public_domain
    }
  ]

  secrets        = []
  ssm_parameters = []

  ssm_documents = []
  load_balancers = [
    # {
    #   key             = "ecs-web"
    #   name            = "ecs-web"
    #   vpc_name_abr    = "${local.vpc_name_abr}"
    #   type            = "application"
    #   security_groups = ["alb"]
    #   subnets = [
    #     include.env.locals.subnet_prefix.primary
    #   ]
    #   enable_deletion_protection = false
    #   enable_access_logs         = true
    #   access_logs_bucket         = "${local.aws_account_name}-${local.region_prefix}-${local.vpc_name_abr}-audit-bucket"
    #   vpc_name                   = local.vpc_name_abr
    #   create_default_listener    = false
    # }
    # {
    #   key             = "ecs-app"
    #   name            = "ecs-app"
    #   vpc_name_abr    = "${local.vpc_name_abr}"
    #   type            = "network"
    #   security_groups = ["ecs-nlb-internal"]
    #   subnets = [
    #     include.env.locals.subnet_prefix.primary
    #   ]
    #   enable_deletion_protection = false
    #   enable_access_logs         = true
    #   access_logs_bucket         = "${local.aws_account_name}-${local.region_prefix}-${local.vpc_name_abr}-audit-bucket"
    #   vpc_name                   = local.vpc_name_abr
    # }
  ]
  alb_listeners = [
    # {
    #   key             = "ecs-web-https"
    #   alb_key         = "ecs-web"
    #   protocol        = "HTTPS"
    #   certificate_key = "${local.vpc_name_abr}"
    #   port            = 443
    #   action          = "forward"
    #   tg_name         = "ecs-frontend"
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
    #   key        = "ecs-app"
    #   nlb_key    = "ecs-app"
    #   protocol   = "TCP"
    #   port       = 3000
    #   ssl_policy = "ELBSecurityPolicy-TLS-1-2-2017-01"
    #   action     = "forward"
    #   vpc_name   = local.vpc_name_abr
    #   tg_name    = "ecs-backend"
    # }
  ]
  target_groups = [
    # {
    #   key         = "ecs-frontend"
    #   name        = "ecs-frontend"
    #   protocol    = "HTTP"
    #   port        = 80
    #   target_type = "ip"
    #   health_check = {
    #     protocol = "HTTP"
    #     port     = 80
    #     path     = "/"
    #     matcher  = "200-299"
    #   }
    #   vpc_name     = local.vpc_name_abr
    #   vpc_name_abr = "${local.vpc_name_abr}"
    # }
    # {
    #   key         = "ecs-backend"
    #   name        = "ecs-backend"
    #   protocol    = "TCP"
    #   port        = 3000
    #   target_type = "ip"
    #   health_check = {
    #     protocol = "TCP"
    #     port     = 3000
    #   }
    #   vpc_name     = local.vpc_name_abr
    #   vpc_name_abr = "${local.vpc_name_abr}"
    # }
  ]

  wafs = [
    #   {
    #     key         = "org"
    #     name        = "org"
    #     description = "Organization wide WAF"
    #     rule_file   = "${include.cloud.locals.repo.root}/documents/waf/managedrules.json"
    #     logging = {
    #       enabled          = true
    #       create_log_group = true
    #     }
    #     rule_groups = [
    #       {
    #         key             = "country-based-blocking"
    #         name            = "CountryBasedBlocking"
    #         description     = "Block requests from specific countries"
    #         capacity        = 1000
    #         rule_group_file = "${include.cloud.locals.repo.root}/documents/waf/countrybasedblocking.json"
    #       },
    #       {
    #         key             = "rate-based"
    #         name            = "RateBasedBlocking"
    #         description     = "Block requests exceeding rate limit"
    #         capacity        = 1000
    #         rule_group_file = "${include.cloud.locals.repo.root}/documents/waf/ratebasedblocking.json"
    #       }
    #     ]
    #     rule_group_references = [
    #       {
    #         name           = "country-based-blocking"
    #         priority       = 45
    #         rule_group_key = "country-based-blocking"
    #       },
    #       {
    #         name           = "rate-based"
    #         priority       = 50
    #         rule_group_key = "rate-based"
    #       }
    #     ]
    #     ip_sets = [
    #       {
    #         key         = "my-ip"
    #         name        = "my-ip"
    #         description = "Block my home IPs"
    #         addresses   = ["69.143.134.56/32"]
    #       },
    #       {
    #         key         = "josh-ip"
    #         name        = "josh-ip"
    #         description = "Block Josh IPs"
    #         addresses   = ["70.22.20.54/32"]
    #       }
    #     ]
    #     custom_rules = [
    #       {
    #         name           = "allow-my-ip"
    #         priority       = 65
    #         action         = "allow"
    #         statement_type = "ip_set"
    #         ip_set_key     = "my-ip"
    #       },
    #       {
    #         name           = "block-josh-ip"
    #         priority       = 70
    #         action         = "block"
    #         statement_type = "ip_set"
    #         ip_set_key     = "josh-ip"
    #       }
    #     ]
    #     association = {
    #       associate_alb = true
    #       alb_keys      = ["app"]
    #     }
    #   }
  ]

  eks = [
    {
      create_eks_cluster      = local.create_eks_cluster
      create_node_group       = true
      create_service_accounts = true
      enable_eks_pia          = true
      create_rbac             = true
      create_namespaces       = true
      key                     = include.env.locals.eks_cluster_keys.primary_cluster
      name                    = "${local.vpc_name_abr}-${include.env.locals.eks_cluster_keys.primary_cluster}"
      role_arn                = dependency.platform.outputs.IAM_roles.shared-eks.iam_role_arn
      oidc_thumbprint         = "${get_env("TF_VAR_EKS_CLUSTER_THUMPRINT")}"
      access_entries = {
        admin = {
          principal_arns = [
            include.env.locals.eks_roles.admin,
            include.env.locals.eks_roles.system
          ]
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
          # kubernetes_groups omitted: system:* groups are rejected by the EKS Access Entry API.
          # AmazonEKSClusterAdminPolicy already grants full cluster-admin access.
        },
        readonly = {
          principal_arns = [
            include.env.locals.eks_roles.readonly
          ]
          kubernetes_groups = ["cognitech-viewers", "infogrid"] # Allows binding of the IAM role to Kubernetes RBAC groups for read-only access
        },
        audit = {
          principal_arns = [
            include.env.locals.eks_roles.network
          ]
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSViewPolicy" #This grants the roles default kubernetes view cluster role permission. To avoid the role from getting these permissions remove this permissions. view cluster role permission. To avoid the role from getting these permissions remove this permissions. 
        }
      }
      auth = {
        cluster_roles = [
          {
            key  = "cognitech-view"
            name = "cognitech-view" # renamed from "view" to avoid conflict with the built-in Kubernetes ClusterRole
            rules = [
              {
                api_groups = ["*"]
                resources  = ["deployments", "pods", "services"]
                verbs      = ["get", "list", "watch"]
              }
            ]
          }
        ]
        cluster_role_bindings = [
          {
            key              = "view-binding"
            name             = "view-binding"
            cluster_role_key = "cognitech-view" # references the cognitech-view cluster role above
            subjects = [
              {
                kind      = "Group"
                name      = "cognitech-viewers"
                api_group = "rbac.authorization.k8s.io"
              }
            ]
          }
        ]
        roles = [
          {
            key       = "infogrid"
            name      = "infogrid"
            namespace = "infogrid"
            rules = [
              {
                api_groups = ["*"]
                resources  = ["deployments", "pods", "services"]
                verbs      = ["get", "list", "watch"]
              }
            ]
          }
        ]
        role_bindings = [
          {
            key       = "infogrid-binding"
            name      = "infogrid-binding"
            namespace = "infogrid" # This namespace has to be thesame as the one defined in the infogrid role above
            role_key  = "infogrid" # references the infogrid cluster role above
            subjects = [
              {
                kind      = "Group"
                name      = "infogrid"
                api_group = "rbac.authorization.k8s.io"
              }
            ]
          }
        ]
      }
      namespaces = [
        {
          name = "infogrid"
          labels = {
            team = "infogrid-devops"
          }
        }
      ]
      subnet_keys = [
        include.env.locals.subnet_prefix.primary,
        include.env.locals.subnet_prefix.secondary
      ]
      additional_security_group_keys = [
        "eks-cluster-secondary"
      ]
      vpc_name = "${local.vpc_name_abr}"
      key_pair = {
        name               = "${local.vpc_name_abr}-eks-node-key"
        name_prefix        = "${local.vpc_name_abr}-eks-node-key"
        secret_name        = "${local.vpc_name_abr}-${include.cloud.locals.secret_names.eks_node}"
        secret_description = "Private key for ${local.vpc_name_abr} EKS Nodes"
        create_secret      = true
      }
      security_groups = [
        {
          key         = "eks-nodes"
          name        = "eks-nodes"
          description = "standard ${local.vpc_name} bastion security group"
          vpc_name    = local.vpc_name_abr
        },
        {
          key         = "eks-cluster-secondary"
          name        = "eks-cluster-secondary"
          description = "standard ${local.vpc_name} eks cluster secondary security group"
          vpc_name    = local.vpc_name_abr
        }
      ]
      security_group_rules = [
        {
          sg_key = "eks-nodes"
          ingress_rules = [
            {
              key           = "ingress-all-eks-sg"
              source_sg_key = "eks_cluster_sg_id"
              description   = "BASE - Inbound traffic from EKS Cluster SG to EKS Nodes SG"
              ip_protocol   = "-1"
            },
            {
              key           = "ingress-self-sg"
              source_sg_key = "eks-nodes"
              description   = "BASE - Inbound traffic from EKS Nodes SG to itself"
              ip_protocol   = "-1"
            },
            {
              key               = "ingress-app-sg"
              source_vpc_sg_key = "app"
              description       = "BASE - Inbound traffic from EKS Nodes SG to app SG"
              ip_protocol       = "-1"
            },
            {
              key               = "ingress-22-bastion-sg"
              source_vpc_sg_key = "bastion"
              description       = "BASE - Inbound traffic from bastion SG on tcp port 22"
              from_port         = 22
              to_port           = 22
              ip_protocol       = "tcp"
            },
            {
              key               = "ingress-3389-bastion-sg"
              source_vpc_sg_key = "bastion"
              description       = "BASE - Inbound traffic from bastion SG on tcp port 3389"
              from_port         = 3389
              to_port           = 3389
              ip_protocol       = "tcp"
            },
            {
              key         = "ingress-80-my-ip"
              cidr_ipv4   = include.cloud.locals.external_cidrs.org_ip
              description = "BASE - Inbound traffic from org IP on tcp port 80"
              from_port   = 80
              to_port     = 80
              ip_protocol = "tcp"
            },
            {
              key         = "ingress-443-my-ip"
              cidr_ipv4   = include.cloud.locals.external_cidrs.org_ip
              description = "BASE - Inbound traffic from org IP on tcp port 443"
              from_port   = 443
              to_port     = 443
              ip_protocol = "tcp"
            },
            {
              key         = "ingress-30000-32767-my-ip"
              cidr_ipv4   = include.cloud.locals.external_cidrs.org_ip
              description = "BASE - Inbound traffic from org IP on tcp port range 30000-32767 for nodeport test"
              from_port   = 30000
              to_port     = 32767
              ip_protocol = "tcp"
            }
          ]
          egress_rules = [
            {
              key         = "egress-all-traffic-internet"
              cidr_ipv4   = "0.0.0.0/0"
              description = "BASE - Outbound all traffic from EKS Nodes SG to Internet"
              ip_protocol = "-1"
            }
          ]
        },
        {
          sg_key = "eks-cluster-secondary"
          ingress_rules = [
            {
              key           = "ingress-all-eks-nodes"
              source_sg_key = "eks-nodes"
              description   = "BASE - Inbound traffic from EKS Nodes SG on all ports"
              ip_protocol   = "-1"
            }
          ]
          egress_rules = []
        }
      ]
      launch_templates = [
        {
          key  = "${local.vpc_name_abr}-${include.env.locals.eks_cluster_keys.primary_cluster}"
          name = "${local.vpc_name_abr}-${include.env.locals.eks_cluster_keys.primary_cluster}"
          ami_config = {
            os_release_date = "EKSAL2023"
          }
          associate_public_ip_address = true
          instance_type               = "t3.medium"
          root_device_name            = "/dev/xvda"
          volume_size                 = 20
          vpc_security_group_keys     = ["eks-nodes", "eks_cluster_sg_id"]
          account_security_group_keys = ["app"]
        }
      ]
      service_accounts = [
        {
          key       = "infogrid"
          name      = "secrets"
          namespace = "default"
          role_key  = "${include.env.locals.eks_cluster_keys.primary_cluster}-sa-role"
        },
        {
          key       = "s3-access"
          name      = "s3-access"
          namespace = "default"
        },
        {
          key       = "secrets-pia"
          name      = "secrets-pia"
          namespace = "default"
        }
      ]
      eks_pia = [
        {
          key                       = "s3-access"
          service_account_namespace = "default"
          service_account_keys      = ["s3-access"]
          role_key                  = "${include.env.locals.eks_cluster_keys.primary_cluster}-s3-role"
        },
        {
          key                       = "ebs-csi-driver"
          service_account_namespace = "kube-system"           # This is the default namespace used by the EBS CSI Driver
          service_account_name      = "ebs-csi-controller-sa" # This is the default name used by the EBS CSI Driver
          role_key                  = "${include.env.locals.eks_cluster_keys.primary_cluster}-ebs-csi-driver"
        },
        {
          key                       = "secrets-pia"
          service_account_namespace = "default"
          service_account_keys      = ["secrets-pia"]
          role_key                  = "${include.env.locals.eks_cluster_keys.primary_cluster}-secrets-pia-role"
        },
      ]
      iam_roles = [
        {
          key                       = "${include.env.locals.eks_cluster_keys.primary_cluster}-sa-role"
          name                      = "${include.env.locals.eks_cluster_keys.primary_cluster}-sa"
          description               = "IAM Role for ${local.vpc_name_abr} Infogrid Service Account"
          path                      = "/"
          service_account_namespace = "default"
          service_account_name      = "secrets"
          policy = {
            name        = "${local.vpc_name_abr}-${include.env.locals.eks_cluster_keys.primary_cluster}-sa"
            description = "IAM policy for ${local.vpc_name_abr} Infogrid Service Account"
            policy      = "${include.cloud.locals.repo.root}/iam_policies/secrets_manager_infogrid_eks_policy.json"
          }
        },
        {
          key                       = "${include.env.locals.eks_cluster_keys.primary_cluster}-elb-controller"
          name                      = "${include.env.locals.eks_cluster_keys.primary_cluster}-elb-controller"
          description               = "IAM Role for ${local.vpc_name_abr} ELB Controller Service Account"
          path                      = "/"
          service_account_namespace = "kube-system" # No assume role policy provided so automatically uses OIDC for federation
          service_account_name      = "aws-load-balancer-controller"
          policy = {
            name        = "${local.vpc_name_abr}-${include.env.locals.eks_cluster_keys.primary_cluster}-elb-controller"
            description = "IAM policy for ${local.vpc_name_abr} ELB Controller Service Account."
            policy      = "${include.cloud.locals.repo.root}/iam_policies/iam_ingress_controller_policy.json"
          }
        },
        {
          key                       = "${include.env.locals.eks_cluster_keys.primary_cluster}-fluent-bit"
          name                      = "${include.env.locals.eks_cluster_keys.primary_cluster}-fluent-bit"
          description               = "IAM Role for ${local.vpc_name_abr} Fluent Bit Service Account"
          path                      = "/"
          service_account_namespace = "amazon-cloudwatch" # No assume role policy provided so automatically uses OIDC for federation
          service_account_name      = "fluent-bit"
          policy = {
            name        = "${local.vpc_name_abr}-${include.env.locals.eks_cluster_keys.primary_cluster}-fluent-bit"
            description = "IAM policy for ${local.vpc_name_abr} Fluent Bit Service Account."
            policy      = "${include.cloud.locals.repo.root}/iam_policies/iam_fluent_bit_dev.json"
          }
        },
        {
          key                = "${include.env.locals.eks_cluster_keys.primary_cluster}-secrets-pia-role"
          name               = "${include.env.locals.eks_cluster_keys.primary_cluster}-secrets-pia"
          description        = "IAM Role for ${local.vpc_name_abr} Secrets PIA Service Account"
          path               = "/"
          assume_role_policy = "${include.cloud.locals.repo.root}/iam_policies/pia_trust_policy.json"
          policy = {
            name        = "${local.vpc_name_abr}-${include.env.locals.eks_cluster_keys.primary_cluster}-secrets-pia"
            description = "IAM policy for ${local.vpc_name_abr} Infogrid Service Account"
            policy      = "${include.cloud.locals.repo.root}/iam_policies/secrets_manager_infogrid_eks_policy.json"
          }
        },
        {
          key                       = "${include.env.locals.eks_cluster_keys.primary_cluster}-s3-role"
          name                      = "${include.env.locals.eks_cluster_keys.primary_cluster}-s3"
          description               = "IAM Role for ${local.vpc_name_abr} S3 Access"
          path                      = "/"
          assume_role_policy        = "${include.cloud.locals.repo.root}/iam_policies/pia_trust_policy.json"
          service_account_namespace = "default"
          service_account_name      = "secrets"
          policy = {
            name        = "${local.vpc_name_abr}-${include.env.locals.eks_cluster_keys.primary_cluster}-s3"
            description = "IAM policy for ${local.vpc_name_abr} S3 Access"
            policy      = "${include.cloud.locals.repo.root}/iam_policies/pia_s3_access_policy.json"
          }
        },
        {
          key                       = "${include.env.locals.eks_cluster_keys.primary_cluster}-external-dns-role"
          name                      = "${include.env.locals.eks_cluster_keys.primary_cluster}-external-dns"
          description               = "IAM Role for ${local.vpc_name_abr} External DNS Access"
          path                      = "/"
          service_account_namespace = "kube-system"
          service_account_name      = "external-dns"
          policy = {
            name        = "${local.vpc_name_abr}-${include.env.locals.eks_cluster_keys.primary_cluster}-external-dns"
            description = "IAM policy for ${local.vpc_name_abr} External DNS Access"
            policy      = "${include.cloud.locals.repo.root}/iam_policies/external_dns_policy.json"
          }
        },
        {
          key                  = "${include.env.locals.eks_cluster_keys.primary_cluster}-ebs-csi-driver"
          name                 = "${include.env.locals.eks_cluster_keys.primary_cluster}-ebs-csi-driver"
          description          = "IAM Role for ${local.vpc_name_abr} EBS CSI Driver"
          path                 = "/"
          assume_role_policy   = "${include.cloud.locals.repo.root}/iam_policies/pia_trust_policy.json"
          create_custom_policy = false
          managed_policy_arns = [
            "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy",
            "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
          ]
        }
      ]
      eks_node_groups = [
        {
          key             = "${local.vpc_name_abr}-${include.env.locals.eks_cluster_keys.primary_cluster}"
          node_group_name = "${local.vpc_name_abr}-${include.env.locals.eks_cluster_keys.primary_cluster}-node-groups"
          node_role_arn   = dependency.platform.outputs.IAM_roles.shared-ec2-nodes.iam_role_arn
          subnet_keys = [
            include.env.locals.subnet_prefix.primary
          ]
          desired_size        = 2
          max_size            = 4
          min_size            = 1
          launch_template_key = "${local.vpc_name_abr}-${include.env.locals.eks_cluster_keys.primary_cluster}"
        }
      ]
      eks_addons = {
        enable_vpc_cni                        = true
        enable_kube_proxy                     = true
        enable_coredns                        = true
        enable_cloudwatch_observability       = false
        enable_secrets_manager_csi_driver     = true
        enable_metrics_server                 = true
        enableSecretRotation                  = true
        enable_pod_identity_agent             = true
        enable_external_dns                   = true
        enable_ebs_csi_driver                 = true
        enable_fluent_bit                     = true
        rotationPollInterval                  = "2m"
        cloudwatch_observability_role_arn     = dependency.platform.outputs.IAM_roles.shared-cw-observability.iam_role_arn
        ebs_csi_driver_role_key               = "${include.env.locals.eks_cluster_keys.primary_cluster}-ebs-csi-driver"
        enable_aws_load_balancer_controller   = true
        aws_load_balancer_controller_role_key = "${include.env.locals.eks_cluster_keys.primary_cluster}-elb-controller"
        external_dns_role_key                 = "${include.env.locals.eks_cluster_keys.primary_cluster}-external-dns-role"
        external_dns_policy                   = "sync"                                  # This determines if external-dns creates/deletes DNS records or just syncs existing ones. Another option is "upsert-only"
        external_dns_domain_filters           = ["${include.env.locals.public_domain}"] # Add your Route53 hosted zone domain
        external_dns_version                  = "1.14.3"
        enable_kube_prometheus_stack          = true
        kube_prometheus_stack_version         = "69.8.2"
        grafana_namespace                     = "monitoring"
        grafana_service_type                  = "ClusterIP"
        grafana_ingress_enabled               = true
        grafana_ingress_class_name            = "alb"
        grafana_ingress_annotations           = yamldecode(file("${include.cloud.locals.repo.root}/iam_policies/grafana_ingress_annotation.yaml"))
        grafana_persistence_enabled           = true
        grafana_persistence_size              = "20Gi"
        grafana_persistence_storage_class     = "gp3"
        prometheus_retention                  = "30d"
        prometheus_persistence_enabled        = true
        prometheus_persistence_size           = "100Gi"
        prometheus_persistence_storage_class  = "gp3"
      }
    }
  ]

  firehose_streams = [
    {
      key         = "${local.vpc_name_abr}-firehose"
      name        = "${local.vpc_name_abr}-firehose"
      vpc_name    = local.vpc_name_abr
      destination = "opensearch"
      role_arn    = dependency.platform.outputs.IAM_roles.shared-firehose.iam_role_arn
      s3_configuration = { # This is required even when the destination is OpenSearch because Firehose uses S3 as a backup for failed deliveries to OpenSearch
        bucket_key          = "${local.vpc_name_abr}-firehose-backup"
        prefix              = "firehose/${local.vpc_name_abr}-logs/"
        error_output_prefix = "firehose/${local.vpc_name_abr}-logs/errors/"
        buffering_size      = 5
        buffering_interval  = 300
        compression_format  = "GZIP"
      }
      opensearch_configuration = {
        domain_key = "${local.vpc_name_abr}-es"
        index_name = "${local.vpc_name_abr}-logs"
        type_name  = "_doc"
        vpc_config = {
          subnet_keys = [
            include.env.locals.subnet_prefix.primary
          ]
          security_group_keys = ["firehose"]
        }
      }
    }
  ]

  opensearch_domains = [
    {
      key            = "${local.vpc_name_abr}-es"
      domain_name    = "${local.vpc_name_abr}-es"
      vpc_name       = local.vpc_name_abr
      engine_version = "OpenSearch_2.3"
      cluster_config = {
        instance_type            = "t3.small.search"
        instance_count           = 2
        dedicated_master_enabled = false
        zone_awareness_enabled   = false
      }
      ebs_options = {
        ebs_enabled = true
        volume_size = 10
        volume_type = "gp3"
      }
      vpc_options = {
        subnet_keys = [
          include.env.locals.subnet_prefix.primary
        ]
        security_group_keys = ["opensearch"]
      }
    }
  ]

  # events = [
  #   {
  #     rule_name        = "${local.vpc_name_abr}-eks-node-tagger-rule"
  #     event_pattern    = <<-EOF
  #     {
  #       "source": ["aws.ec2"],
  #       "detail-type": ["EC2 Instance State-change Notification"],
  #       "detail": {
  #         "state": ["running"]
  #       }
  #     }
  #     EOF
  #     rule_description = "EventBridge rule to trigger tagging newly created EKS nodes on EC2 instance state change"
  #     target_key       = "${local.vpc_name_abr}-eks_node_tagger"
  #     tags = {
  #       Used_for = "eks-node-tagging"
  #     }
  #   }
  # ]

  rds_instances = [
    {
      create_rds_instance   = local.create_mysql_rds
      key                   = "ecsmysql"
      name                  = "${local.vpc_name_abr}-eks-mysql-db"
      engine                = "mysql"
      engine_version        = "8.0.43"
      instance_class        = "db.t3.micro"
      vpc_name              = local.vpc_name_abr
      allocated_storage     = 20
      max_allocated_storage = 20
      storage_type          = "gp3"
      database_name         = "ecsdb"
      port                  = 3306
      subnet_keys = [
        include.env.locals.subnet_prefix.primary
      ]
      vpc_security_group_keys = ["db"]
      publicly_accessible     = true
    },
    {
      create_rds_instance   = local.create_postgres_rds
      key                   = "${local.vpc_name_abr}-postgres"
      name                  = "${local.vpc_name_abr}-postgres-db"
      engine                = "postgres"
      engine_version        = "15.16"
      instance_class        = "db.t3.micro"
      vpc_name              = local.vpc_name_abr
      allocated_storage     = 20
      max_allocated_storage = 40
      storage_type          = "gp3"
      database_name         = "ecsdb"
      port                  = 5432
      subnet_keys = [
        include.env.locals.subnet_prefix.primary
      ]
      vpc_security_group_keys = ["db"]
      publicly_accessible     = true
    }
  ]

  ecs_clusters = [
    {
      key                        = "primary"
      create_ecs_cluster         = local.create_ecs_cluster
      cluster_name               = "${local.vpc_name_abr}-${include.env.locals.ecs_cluster_keys.primary_cluster}"
      vpc_name                   = local.vpc_name_abr
      container_insights_enabled = true
      capacity_providers = {
        capacity_provider_names = ["${local.aws_account_name}-${local.region_prefix}-${local.vpc_name_abr}-ecs-cp", "FARGATE", "FARGATE_SPOT"]
        default_capacity_provider_strategy = [
          {
            capacity_provider = "${local.aws_account_name}-${local.region_prefix}-${local.vpc_name_abr}-ecs-cp"
            base              = 2
            weight            = 1
          },
          # {
          #   capacity_provider = "FARGATE"
          #   base              = 0
          #   weight            = 1
          # },
          # {
          #   capacity_provider = "FARGATE_SPOT"
          #   base              = 0
          #   weight            = 3
          # }
        ]
      }
      cloud_map_namespaces = [
        {
          name     = "${local.vpc_name_abr}.local"
          type     = "DNS_PRIVATE"
          vpc_name = local.vpc_name_abr
          services = [
            {
              name = "backend"
              dns_config = {
                routing_policy = "MULTIVALUE"
                dns_records = [
                  { ttl = 10, type = "A" }
                ]
              }
              health_check_custom_config = {
                failure_threshold = 1
              }
            }
          ]
        }
      ]
      task_definitions = [
        {
          family                     = "${local.vpc_name_abr}-frontend"
          task_role_key              = "${local.vpc_name_abr}-ecs-task"
          execution_role_key         = "${local.vpc_name_abr}-ecs-execution"
          network_mode               = "awsvpc"
          requires_compatibilities   = ["EC2"]
          cpu                        = "512"
          memory                     = "1024"
          cloud_map_key              = "${local.vpc_name_abr}.local/backend"
          cloud_map_port             = 3000
          container_definitions_file = "${include.cloud.locals.repo.root}/ecs_containers_definitions/frontend.json",
        },
        {
          family                     = "${local.vpc_name_abr}-backend"
          network_mode               = "awsvpc"
          requires_compatibilities   = ["EC2"]
          cpu                        = "1280"
          memory                     = "2560"
          execution_role_key         = "${local.vpc_name_abr}-ecs-execution"
          task_role_key              = "${local.vpc_name_abr}-ecs-task"
          rds_key                    = "${local.vpc_name_abr}-postgres"
          frontend_url_lb_key        = "ecs-web"
          smtp_secret_key            = "smtp"
          container_definitions_file = "${include.cloud.locals.repo.root}/ecs_containers_definitions/backend.json"
        }
      ]
      services = [
        {
          name                               = "${local.vpc_name_abr}-frontend-service"
          task_definition_family             = "${local.vpc_name_abr}-frontend"
          desired_count                      = 2
          launch_type                        = "EC2"
          enable_execute_command             = true
          scheduling_strategy                = "REPLICA"
          deployment_maximum_percent         = 200
          deployment_minimum_healthy_percent = 100
          enable_ecs_managed_tags            = true
          deployment_circuit_breaker = {
            enable   = true
            rollback = true
          }
          load_balancers = [
            {
              target_group_key = "ecs-frontend"
              container_name   = "frontend"
              container_port   = 80
            }
          ]
          network_configuration = {
            subnet_keys = [
              include.env.locals.subnet_prefix.primary,
              include.env.locals.subnet_prefix.secondary
            ]
            security_group_keys = ["ecs-frontend"]
          }
        },
        {
          name                               = "${local.vpc_name_abr}-backend-service"
          task_definition_family             = "${local.vpc_name_abr}-backend"
          desired_count                      = 2
          launch_type                        = "EC2"
          enable_execute_command             = true
          scheduling_strategy                = "REPLICA"
          deployment_maximum_percent         = 200
          deployment_minimum_healthy_percent = 100
          enable_ecs_managed_tags            = true
          service_registries = {
            cloud_map_service_key = "${local.vpc_name_abr}.local/backend"
            # container_name        = "backend" # Not needed when using awsvpc network mode since the port is defined at the task level, but if using bridge or host network mode then you would need to specify the container and port here
            # container_port        = 3000 # Not needed when using awsvpc network mode since the port is defined at the task level, but if using bridge or host network mode then you would need to specify the container and port here
          }
          deployment_circuit_breaker = {
            enable   = true
            rollback = true
          }
          # load_balancers = [
          #   {
          #     target_group_key = "ecs-backend"
          #     container_name   = "backend"
          #     container_port   = 3000
          #   }
          # ]
          network_configuration = {
            subnet_keys = [
              include.env.locals.subnet_prefix.primary,
              include.env.locals.subnet_prefix.secondary
            ]
            security_group_keys = ["ecs-backend"]
          }
        }
      ]
      ec2_autoscaling = {
        launch_templates = [
          {
            key                      = "${local.vpc_name_abr}-ecs-lt"
            name                     = "${local.vpc_name_abr}-ecs-lt"
            iam_instance_profile_key = "${local.vpc_name_abr}-ecs"
            ami_config = {
              os_release_date = "ECSAL2023"
            }
            instance_type               = "t3.large"
            key_name                    = "${local.vpc_name_abr}-key-pair"
            associate_public_ip_address = true
            vpc_security_group_keys     = ["ecs-instance"]
            user_data = base64encode(<<-EOF
                #!/bin/bash
                echo ECS_CLUSTER=${local.aws_account_name}-${local.region_prefix}-${local.vpc_name_abr}-${include.env.locals.ecs_cluster_keys.primary_cluster} >> /etc/ecs/ecs.config
                echo ECS_ENABLE_CONTAINER_METADATA=true >> /etc/ecs/ecs.config
            EOF
            )
          }
        ]
        autoscaling_group = {
          name                      = "${local.vpc_name_abr}-ecs-asg"
          max_size                  = 6
          min_size                  = 3
          desired_capacity          = 3
          health_check_grace_period = 300
          subnet_keys = [
            include.env.locals.subnet_prefix.primary,
            include.env.locals.subnet_prefix.secondary
          ]
          launch_template_key = "${local.vpc_name_abr}-ecs-lt"
        }
        capacity_provider = {
          name                           = "${local.vpc_name_abr}-ecs-cp"
          managed_termination_protection = "DISABLED"
          managed_scaling = {
            maximum_scaling_step_size = 3
            minimum_scaling_step_size = 1
            status                    = "ENABLED"
            target_capacity           = 80
            instance_warmup_period    = 300
          }
        }
        scaling_policies = {
          scale_up = {
            scaling_adjustment = 1
            adjustment_type    = "ChangeInCapacity"
            cooldown           = 300
          }
          scale_down = {
            scaling_adjustment = -1
            adjustment_type    = "ChangeInCapacity"
            cooldown           = 300
          }
        }
      }
    }
  ]

  # lambdas = [
  #   {
  #     function_name       = "${local.vpc_name_abr}-eks_node_tagger"
  #     description         = "Lambda function to tag EKS nodes"
  #     runtime             = include.cloud.locals.lambda[include.env.locals.name_abr].eks_node_tagger.runtime
  #     handler             = include.cloud.locals.lambda[include.env.locals.name_abr].eks_node_tagger.handler
  #     timeout             = include.cloud.locals.lambda[include.env.locals.name_abr].eks_node_tagger.timeout
  #     private_bucket_name = include.cloud.locals.lambda[include.env.locals.name_abr].eks_node_tagger.private_bucket_name
  #     lambda_s3_key       = include.cloud.locals.lambda[include.env.locals.name_abr].eks_node_tagger.lambda_s3_key
  #     layer_description   = "Lambda Layer for shared libraries for all functions"
  #     layer_s3_key        = include.cloud.locals.lambda[include.env.locals.name_abr].eks_node_tagger.layer_s3_key
  #     env_variables = {
  #       VPC_NAME_ABR = local.vpc_name_abr
  #     }
  #   }
  # ]

  # lambda-invocations = [
  #   {
  #     key          = "eventbridge-eks-node-tagger-invocation"
  #     function_key = "${local.vpc_name_abr}-eks_node_tagger"
  #     statement_id = "AllowEventBridgeInvoke"
  #     principal    = "events.amazonaws.com"
  #     source_key   = "${local.vpc_name_abr}-eks-node-tagger-rule"
  #   }
  # ]
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

generate "k8s-providers" {
  path      = "k8s-provider.tf"
  if_exists = "overwrite"
  contents  = <<-EOF
  %{if local.create_eks_cluster}
  provider "helm" {
    kubernetes = {
      host                   = module.eks["${include.env.locals.eks_cluster_keys.primary_cluster}"].eks_cluster_endpoint
      cluster_ca_certificate = base64decode(module.eks["${include.env.locals.eks_cluster_keys.primary_cluster}"].eks_cluster_certificate_authority_data)
      
      exec = {
        api_version = "client.authentication.k8s.io/v1beta1"
        command     = "aws"
        args = [
          "eks",
          "get-token",
          "--cluster-name",
          module.eks["${include.env.locals.eks_cluster_keys.primary_cluster}"].eks_cluster_name,
          "--region",
          "${local.region}"
        ]
      }
    }
  }

  provider "kubernetes" {
    host                   = module.eks["${include.env.locals.eks_cluster_keys.primary_cluster}"].eks_cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks["${include.env.locals.eks_cluster_keys.primary_cluster}"].eks_cluster_certificate_authority_data)
    
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args = [
        "eks",
        "get-token",
        "--cluster-name",
        module.eks["${include.env.locals.eks_cluster_keys.primary_cluster}"].eks_cluster_name,
        "--region",
        "${local.region}"
      ]
    }
  }
  %{endif}
  EOF
}