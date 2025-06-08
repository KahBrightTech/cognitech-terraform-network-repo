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
  region_context   = "secondary"
  deploy_globally  = "true"
  internal         = "private"
  external         = "public"
  region           = local.region_context == "primary" ? include.cloud.locals.regions.use1.name : include.cloud.locals.regions.usw2.name
  region_prefix    = local.region_context == "primary" ? include.cloud.locals.region_prefix.primary : include.cloud.locals.region_prefix.secondary
  region_blk       = local.region_context == "primary" ? include.cloud.locals.regions.use1 : include.cloud.locals.regions.usw2
  deployment_name  = "${include.env.locals.name_abr}-${local.vpc_name}-${local.region_context}"
  cidr_blocks      = local.region_context == "primary" ? include.cloud.locals.cidr_block_use1 : include.cloud.locals.cidr_block_usw2
  state_bucket     = local.region_context == "primary" ? include.env.locals.remote_state_bucket.primary : include.env.locals.remote_state_bucket.secondary
  state_lock_table = include.env.locals.remote_dynamodb_table
  vpc_name         = "trn"

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
  source = "../../../../..//formations/Tenant-account"
}
#-------------------------------------------------------
# Inputs 
#-------------------------------------------------------
inputs = {
  common = {
    global        = local.deploy_globally
    account_name  = include.cloud.locals.account_name.MD.Preprod.name
    region_prefix = local.region_prefix
    tags          = local.tags
    region        = local.region
  }
  vpcs = [
    {
      name       = local.vpc_name
      cidr_block = local.cidr_blocks[include.env.locals.name_abr].segments[local.vpc_name].vpc
      public_subnets = [
        {
          name                        = include.env.locals.subnet_prefix.primary
          primary_availability_zone   = local.region_blk.availability_zones.primary
          primary_cidr_block          = local.cidr_blocks[include.env.locals.name_abr].segments[local.vpc_name].public_subnets.sbnt1.primary
          secondary_availability_zone = local.region_blk.availability_zones.secondary
          secondary_cidr_block        = local.cidr_blocks[include.env.locals.name_abr].segments[local.vpc_name].public_subnets.sbnt1.secondary
          subnet_type                 = local.external
          vpc_name                    = local.vpc_name
        },
        {
          name                        = include.env.locals.subnet_prefix.secondary
          primary_availability_zone   = local.region_blk.availability_zones.primary
          primary_cidr_block          = local.cidr_blocks[include.env.locals.name_abr].segments[local.vpc_name].public_subnets.sbnt2.primary
          secondary_availability_zone = local.region_blk.availability_zones.secondary
          secondary_cidr_block        = local.cidr_blocks[include.env.locals.name_abr].segments[local.vpc_name].public_subnets.sbnt2.secondary
          subnet_type                 = local.external
          vpc_name                    = local.vpc_name
        }
      ]
      private_subnets = [
        {
          name                        = include.env.locals.subnet_prefix.primary
          primary_availability_zone   = local.region_blk.availability_zones.primary
          primary_cidr_block          = local.cidr_blocks[include.env.locals.name_abr].segments[local.vpc_name].private_subnets.sbnt1.primary
          secondary_availability_zone = local.region_blk.availability_zones.secondary
          secondary_cidr_block        = local.cidr_blocks[include.env.locals.name_abr].segments[local.vpc_name].private_subnets.sbnt1.secondary
          subnet_type                 = local.internal
          vpc_name                    = local.vpc_name
        },
        {
          name                        = include.env.locals.subnet_prefix.secondary
          primary_availability_zone   = local.region_blk.availability_zones.primary
          primary_cidr_block          = local.cidr_blocks[include.env.locals.name_abr].segments[local.vpc_name].private_subnets.sbnt2.primary
          secondary_availability_zone = local.region_blk.availability_zones.secondary
          secondary_cidr_block        = local.cidr_blocks[include.env.locals.name_abr].segments[local.vpc_name].private_subnets.sbnt2.secondary
          subnet_type                 = local.internal
          vpc_name                    = local.vpc_name
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
        vpc_name = local.vpc_name
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
            []
          )
          egress = concat(
            include.cloud.locals.security_group_rules.locals.egress.windows_bastion_base,
            include.cloud.locals.security_group_rules.locals.egress.linux_bastion_base,
            []
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
                key         = "ingress-22-shared-services-vpc"
                cidr_ipv4   = local.cidr_blocks[include.env.locals.name_abr].segments.shared-services.vpc
                description = "BASE - Inbound SSH traffic from Shared Services Public Subnet 1 to App SG on tcp port 22"
                from_port   = 22
                to_port     = 22
                ip_protocol = "tcp"
              },
              {
                key         = "ingress-3389-shared-services-vpc"
                cidr_ipv4   = local.cidr_blocks[include.env.locals.name_abr].segments.shared-services.vpc
                description = "BASE - Inbound SSH traffic from Shared Services Public Subnet 1 to App SG on tcp port 22"
                from_port   = 3389
                to_port     = 3389
                ip_protocol = "tcp"
              }
            ]
          )
          egress = concat(
            include.cloud.locals.security_group_rules.locals.egress.app_base,
            []
          )
        }
      ]
      s3 = {
        name        = "${local.vpc_name}-data-xfer"
        description = "The bucket used for data transfers"
        policy      = "${include.cloud.locals.repo.root}/iam_policies/s3_data_policy.json"

      }
    }
  ]
  tgw_attachments = {
    name               = local.vpc_name
    transit_gateway_id = dependency.shared_services.outputs.transit_gateway.transit_gateway_id
  }

  tgw_association = {
    route_table_id = dependency.shared_services.outputs.transit_gateway_route_table.tgw_rtb_id
  }

  tgw_routes = [
    {
      name                   = "spoke-to-hub-tgw-route"
      blackhole              = true
      destination_cidr_block = local.cidr_blocks[include.env.locals.name_abr].segments.shared-services.vpc
      route_table_id         = dependency.shared_services.outputs.transit_gateway_route_table.tgw_rtb_id
    }
  ]

  tgw_shared_services_routes = [
    {
      name                   = "hub-to-spoke-tgw-route"
      blackhole              = false
      destination_cidr_block = local.cidr_blocks[include.env.locals.name_abr].segments.dev.vpc
      route_table_id         = dependency.shared_services.outputs.transit_gateway_route_table.tgw_rtb_id
    }
  ]
  tgw_shared_services_subnet_route = [
    {
      name               = "hub-to-spoke-sbnt1-subnet-rt"
      route_table_id     = dependency.shared_services.outputs.Account_products.shared-services.private_routes[include.env.locals.subnet_prefix.primary].private_route_table_id
      cidr_block         = local.cidr_blocks[include.env.locals.name_abr].segments.dev.vpc
      transit_gateway_id = dependency.shared_services.outputs.transit_gateway.transit_gateway_id
    },
    {
      name               = "hub-to-spoke-sbnt2-subnet-rt"
      route_table_id     = dependency.shared_services.outputs.Account_products.shared-services.private_routes[include.env.locals.subnet_prefix.secondary].private_route_table_id
      cidr_block         = local.cidr_blocks[include.env.locals.name_abr].segments.dev.vpc
      transit_gateway_id = dependency.shared_services.outputs.transit_gateway.transit_gateway_id
    }
  ]

  tgw_subnet_route = [
    {
      name               = "${local.vpc_name}-${include.env.locals.subnet_prefix.primary}"
      cidr_block         = local.cidr_blocks[include.env.locals.name_abr].segments.shared-services.vpc
      transit_gateway_id = dependency.shared_services.outputs.transit_gateway.transit_gateway_id
      subnet_name        = include.env.locals.subnet_prefix.primary
      vpc_name           = local.vpc_name
    },
    {
      name               = "${local.vpc_name}-${include.env.locals.subnet_prefix.secondary}"
      cidr_block         = local.cidr_blocks[include.env.locals.name_abr].segments.shared-services.vpc
      transit_gateway_id = dependency.shared_services.outputs.transit_gateway.transit_gateway_id
      subnet_name        = include.env.locals.subnet_prefix.secondary
      vpc_name           = local.vpc_name
    }
  ]
  s3_private_buckets = [
    {
      name              = "${local.vpc_name}-app-bucket"
      description       = "The application bucket for different apps"
      enable_versioning = true
      policy            = "${include.cloud.locals.repo.root}/iam_policies/s3_app_policy.json"
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
    key                  = "${local.deployment_name}/terraform.tfstate "
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
