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
  vpc_name           = "shared-services"
  vpc_name_abr       = "shared"
  create_eks_cluster = false
  vpn_ip             = "69.143.134.56/32"

  # Composite variables 
  tags = merge(
    include.env.locals.tags,
    {
      Environment = local.vpc_name
      ManagedBy   = "${local.deployment_name}"
    }
  )
}
# #-------------------------------------------------------
# # Dependencies 
# #-------------------------------------------------------
# dependency "network" {
#   config_path = "../../../network/Shared-account/${local.region_context}"
# }
#-------------------------------------------------------
# Source  
#-------------------------------------------------------
terraform {
  source = "../../../..//formations/Shared-account"
}
# #-------------------------------------------------------
# # Source  
# #-------------------------------------------------------
# terraform {
#   source = "../../../..//formations/Simple-Network-Shared-Account"
# }

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
              key         = "ingress-3306-shared-vp"
              cidr_ipv4   = local.cidr_blocks[include.env.locals.name_abr].segments[local.vpc_name].vpc
              description = "BASE - Inbound NFS traffic from the internet on tcp port 3306"
              from_port   = 3306
              to_port     = 3306
              ip_protocol = "tcp"
            },
            {
              key         = "ingress-3306-vpn_ip"
              cidr_ipv4   = local.vpn_ip
              description = "BASE - Inbound MySQL traffic from the VPN on tcp port 3306"
              from_port   = 3306
              to_port     = 3306
              ip_protocol = "tcp"
            },
          ]
          egress = []
        }
      ]
      s3 = {
        name        = "${local.vpc_name_abr}-data-xfer"
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
      name              = "${local.vpc_name_abr}-config-bucket"
      description       = "The configuration bucket for different apps"
      enable_versioning = true
      policy            = "${include.cloud.locals.repo.root}/iam_policies/s3_config_state_policy.json"
    },
    {
      name                 = "${local.vpc_name_abr}-src-replication-bucket"
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
      name              = "${local.vpc_name_abr}-audit-bucket"
      description       = "The audit bucket for different apps"
      enable_versioning = true
      policy            = "${include.cloud.locals.repo.root}/iam_policies/s3_audit_policy.json"
    },
    # {
    #   key               = "report-bucket"
    #   name              = "${local.vpc_name_abr}-report-bucket"
    #   description       = "The report bucket for different apps"
    #   enable_versioning = true
    #   policy            = "${include.cloud.locals.repo.root}/iam_policies/s3_batch_report_bucket.json"
    # },
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
    },
    {
      key                  = "datasync-bucket"
      name                 = "${local.vpc_name_abr}-datasync-bucket"
      description          = "The data sync bucket for different apps"
      enable_versioning    = false
      enable_bucket_policy = false
      objects = [
        {
          key = "Data/"
        },
        {
          key = "SMB/"
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
    },
    {
      name               = "${local.vpc_name_abr}-eks"
      description        = "IAM Role for ${local.vpc_name_abr} EKS Nodes"
      path               = "/"
      assume_role_policy = "${include.cloud.locals.repo.root}/iam_policies/eks_trust_policy.json"
      managed_policy_arns = [
        "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy",
        "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
      ]
      create_custom_policy = false
    },
    {
      name               = "${local.vpc_name_abr}-ec2-nodes"
      description        = "IAM Role for ${local.vpc_name_abr} EC2 Nodes"
      path               = "/"
      assume_role_policy = "${include.cloud.locals.repo.root}/iam_policies/ec2_trust_policy.json"
      managed_policy_arns = [
        "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPowerUser",
        "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPullOnly",
        "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy",
        "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
        "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
        "arn:aws:iam::aws:policy/AmazonEC2ReadOnlyAccess",
        "arn:aws:iam::aws:policy/ElasticLoadBalancingReadOnly",
        "arn:aws:iam::aws:policy/AutoScalingReadOnlyAccess",
        "arn:aws:iam::aws:policy/AmazonRoute53ReadOnlyAccess",
        "arn:aws:iam::aws:policy/AWSCertificateManagerReadOnly",
        "arn:aws:iam::aws:policy/AWSAppMeshFullAccess",
        "arn:aws:iam::aws:policy/AWSCloudMapFullAccess",
        "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
      ]
      policy = {
        name        = "${local.vpc_name_abr}-ec2-nodes"
        description = "IAM policy for ${local.vpc_name_abr} EC2 Nodes"
        policy      = "${include.cloud.locals.repo.root}/iam_policies/iam_role_for_ec2_nodes.json"
      }
    },
    {
      name               = "${local.vpc_name_abr}-cw-observability"
      description        = "IAM Role for ${local.vpc_name_abr} CloudWatch Observability"
      path               = "/"
      assume_role_policy = "${include.cloud.locals.repo.root}/iam_policies/eks-cloudwatch-observability-trust-policy.json"
      policy = {
        name        = "${local.vpc_name_abr}-cw-observability"
        description = "IAM policy for ${local.vpc_name_abr} CloudWatch Observability"
        policy      = "${include.cloud.locals.repo.root}/iam_policies/eks-cloudwatch-observability-policy.json"
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
    {
      name              = "${local.vpc_name_abr}"
      domain_name       = "*.${local.vpc_name_abr}.${include.env.locals.public_domain}"
      validation_method = "DNS"
      zone_name         = include.env.locals.public_domain
    }
  ]

  secrets = [
    {
      key                     = "ansible"
      name_prefix             = include.cloud.locals.secret_names.ansible
      description             = "Ansible tower credentials."
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
    },
    {
      name               = "Putty-Install"
      content            = file("${include.cloud.locals.repo.root}/documents/Putty.yaml")
      document_type      = "Command"
      document_format    = "YAML"
      create_association = true
      targets = {
        key    = "tag:PuttyInstall"
        values = ["True"]
      }
      schedule_expression = "cron(0 9 ? * SUN *)" # Every Sunday at 9 AM
    }
  ]
  load_balancers = [
    #   {
    #     key             = "app"
    #     name            = "app"
    #     vpc_name_abr    = "${local.vpc_name_abr}"
    #     type            = "application"
    #     security_groups = ["alb"]
    #     subnets = [
    #       include.env.locals.subnet_prefix.primary
    #     ]
    #     enable_deletion_protection = false
    #     enable_access_logs         = true
    #     access_logs_bucket         = "${local.aws_account_name}-${local.region_prefix}-${local.vpc_name_abr}-audit-bucket"
    #     vpc_name                   = local.vpc_name_abr
    #     create_default_listener    = true
    #   },
    #   #   # {
    #   #   #   key             = "etl"
    #   #   #   name            = "etl"
    #   #   #   vpc_name_abr    = " ${ local.vpc_name_abr } "
    #   #   #   type            = "application"
    #   #   #   security_groups = ["alb"]
    #   #   #   subnets = [
    #   #   #     include.env.locals.subnet_prefix.primary
    #   #   #   ]
    #   #   #   enable_deletion_protection = true
    #   #   #   enable_access_logs         = true
    #   #   #   access_logs_bucket         = "${local.aws_account_name}-${local.region_prefix}-${local.vpc_name_abr}-audit-bucket"
    #   #   #   vpc_name                   = local.vpc_name
    #   #   # },
    #   #   # {
    #   #   #   key             = "ssrs"
    #   #   #   name            = "ssrs"
    #   #   #   vpc_name_abr    = " ${local.vpc_name_abr} "
    #   #   #   type            = "network"
    #   #   #   security_groups = [" nlb "]
    #   #   #   subnets = [
    #   #   #     include.env.locals.subnet_prefix.primary
    #   #   #   ]
    #   #   #   enable_deletion_protection = false
    #   #   #   enable_access_logs         = true
    #   #   #   access_logs_bucket         = " $ { local.aws_account_name } - $ { local.region_prefix } - $ { local.vpc_name } - audit-bucket "
    #   #   #   vpc_name                   = local.vpc_name
    #   #   # }
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
      create_node_group       = false
      create_service_accounts = false
      enable_eks_pia          = false
      key                     = include.env.locals.eks_cluster_keys.primary_cluster
      name                    = "${local.vpc_name_abr}-${include.env.locals.eks_cluster_keys.primary_cluster}"
      role_key                = "${local.vpc_name_abr}-eks"
      oidc_thumbprint         = "${get_env("TF_VAR_EKS_CLUSTER_THUMPRINT")}"
      access_entries = {
        admin = {
          principal_arns = [
            include.env.locals.eks_roles.admin,
            include.env.locals.eks_roles.system
          ]
          policy_arn        = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
          kubernetes_groups = ["system:masters"] #This automatically gives rbac admin access to the cluster. Its a k8s built in group that has superuser access to the cluster, so use with caution and only assign trusted IAM roles to this group.
        },
        readonly = {
          principal_arns = [
            include.env.locals.eks_roles.network,
            include.env.locals.eks_roles.readonly
          ]
          policy_arn        = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSViewPolicy"
          kubernetes_groups = ["viewers"] # Allows binding of the IAM role to Kubernetes RBAC groups for read-only access
        }
      }
      auth = {
        cluster_roles = [
          {
            key  = "view"
            name = "view"
            rules = [
              {
                api_groups = ["apps"]
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
            cluster_role_key = "view" # above cluster role key
            subjects = [
              {
                kind      = "Group"
                name      = "viewers"
                api_group = "rbac.authorization.k8s.io"
              }
            ]
          }
        ]
      }
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
          node_role_key   = "${local.vpc_name_abr}-ec2-nodes"
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
        enable_cloudwatch_observability       = true
        enable_secrets_manager_csi_driver     = true
        enable_metrics_server                 = true
        enableSecretRotation                  = true
        enable_pod_identity_agent             = true
        enable_external_dns                   = true
        enable_ebs_csi_driver                 = true
        rotationPollInterval                  = "2m"
        cloudwatch_observability_role_key     = "${local.vpc_name_abr}-cw-observability"
        ebs_csi_driver_role_key               = "${include.env.locals.eks_cluster_keys.primary_cluster}-ebs-csi-driver"
        enable_aws_load_balancer_controller   = true
        aws_load_balancer_controller_role_key = "${include.env.locals.eks_cluster_keys.primary_cluster}-elb-controller"
        external_dns_role_key                 = "${include.env.locals.eks_cluster_keys.primary_cluster}-external-dns-role"
        external_dns_policy                   = "sync"                                  # This determines if external-dns creates/deletes DNS records or just syncs existing ones. Another option is "upsert-only"
        external_dns_domain_filters           = ["${include.env.locals.public_domain}"] # Add your Route53 hosted zone domain
        external_dns_version                  = "1.14.3"
      }
    }
  ]

  rds_instances = [
    {
      create_rds_instance   = false
      key                   = "eksmysql"
      name                  = "${local.vpc_name_abr}-eks-mysql-db"
      engine                = "mysql"
      engine_version        = "8.0.43"
      instance_class        = "db.t3.micro"
      vpc_name              = local.vpc_name_abr
      allocated_storage     = 20
      max_allocated_storage = 20
      storage_type          = "gp3"
      database_name         = "eksdb"
      port                  = 3306
      subnet_keys = [
        include.env.locals.subnet_prefix.primary
      ]
      vpc_security_group_keys = ["db"]
      publicly_accessible     = true
    }
  ]

  ecr_repos = [
    {
      key                      = "ecs"
      name                     = "ecs"
      image_tag_mutability     = "MUTABLE"
      scan_on_push             = true
      custom_lifecycle_policy  = true
      custom_repository_policy = true
      lifecycle_policy_file    = "${include.cloud.locals.repo.root}/iam_policies/ecr/ecs_repo_lifecycle_policy.json"
      repository_policy_file   = "${include.cloud.locals.repo.root}/iam_policies/ecr/ecs_repo_repository_policy.json"
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

