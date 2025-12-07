#--------------------------------------------------------------------
# Data
#--------------------------------------------------------------------
data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

data "aws_iam_roles" "admin_role" {
  name_regex  = "AWSReservedSSO_AdministratorAccess_.*"
  path_prefix = "/aws-reserved/sso.amazonaws.com/"
}

data "aws_iam_roles" "network_role" {
  name_regex  = "AWSReservedSSO_NetworkAdministrator_.*"
  path_prefix = "/aws-reserved/sso.amazonaws.com/"
}

module "shared_vpc" {
  source   = "../Create-Network"
  for_each = var.vpcs != null ? { for vpc in var.vpcs : vpc.name => vpc } : {}
  vpc      = each.value
  common   = var.common
}

#--------------------------------------------------------------------
# Transit Gateway - Creates Transit Gateway
#--------------------------------------------------------------------
module "transit_gateway" {
  count           = var.transit_gateway != null ? 1 : 0
  source          = "git::https://github.com/njibrigthain100/Cognitech-terraform-iac-modules.git//terraform/modules/Transit-gateway?ref=v1.3.78"
  transit_gateway = var.transit_gateway
  common          = var.common
}

#--------------------------------------------------------------------
# Transit Gateway attacments - Creates Transit Gateway attachments
#--------------------------------------------------------------------
module "transit_gateway_attachment" {
  count  = var.tgw_attachments != null ? 1 : 0
  source = "git::https://github.com/njibrigthain100/Cognitech-terraform-iac-modules.git//terraform/modules/Transit-gateway-attachments?ref=v1.3.81"
  common = var.common
  vpc_id = var.vpcs != null ? module.shared_vpc[var.tgw_attachments.name].vpc_id : null
  depends_on = [
    module.shared_vpc,
    module.transit_gateway
  ]
  tgw_attachments = merge(
    var.tgw_attachments,
    {
      transit_gateway_id = var.tgw_attachments.transit_gateway_id != null ? var.tgw_attachments.transit_gateway_id : module.transit_gateway[0].transit_gateway_id
      subnet_ids = compact([
        module.shared_vpc[var.tgw_attachments.name].private_subnet.sbnt1.primary_subnet_id, # FYI you can only have one subnet per az for transit gateway attachments. So only using primary subnets here
        module.shared_vpc[var.tgw_attachments.name].private_subnet.sbnt1.secondary_subnet_id
      ])
      name = var.tgw_attachments.name
    }
  )
}
#--------------------------------------------------------------------
# Transit Gateway route table - Creates Transit Gateway route tables
#--------------------------------------------------------------------
module "transit_gateway_route_table" {
  source   = "git::https://github.com/njibrigthain100/Cognitech-terraform-iac-modules.git//terraform/modules/Transit-gateway-route-table?ref=v1.1.17"
  for_each = var.tgw_route_table != null ? { for rt in var.tgw_route_table : rt.key => rt } : {}
  common   = var.common
  depends_on = [
    module.shared_vpc,
    module.transit_gateway
  ]
  tgw_route_table = {
    name   = each.value.name
    tgw_id = each.value.tgw_id != null ? each.value.tgw_id : module.transit_gateway[0].transit_gateway_id
  }
}

#--------------------------------------------------------------------
# Transit Gateway Association - Creates Transit Gateway associations
#--------------------------------------------------------------------
module "transit_gateway_association" {
  source   = "git::https://github.com/njibrigthain100/Cognitech-terraform-iac-modules.git//terraform/modules/Transit-gateway-association?ref=v1.1.18"
  for_each = var.tgw_associations != null ? { for assoc in var.tgw_associations : assoc.key => assoc } : {}
  common   = var.common
  depends_on = [
    module.shared_vpc,
    module.transit_gateway,
    module.transit_gateway_route_table
  ]
  tgw_association = {
    name = each.value.name
    attachment_id = each.value.attachment_id != null ? each.value.attachment_id : (
      each.value.attachment_name != null ?
      module.transit_gateway_attachment[0].tgw_attachment_id :
      module.transit_gateway_attachment[0].tgw_attachment_id
    )
    route_table_id = each.value.route_table_id != null ? each.value.route_table_id : (
      each.value.route_table_key != null ?
      module.transit_gateway_route_table[each.value.route_table_key].tgw_rtb_id :
      each.value.route_table_name != null ?
      module.transit_gateway_route_table[each.value.route_table_name].tgw_rtb_id :
      values(module.transit_gateway_route_table)[0].tgw_rtb_id
    )
  }
}

#--------------------------------------------------------------------
# Transit Gateway Propagation - Creates Transit Gateway propagations
#--------------------------------------------------------------------
module "transit_gateway_propagation" {
  source   = "git::https://github.com/njibrigthain100/Cognitech-terraform-iac-modules.git//terraform/modules/Transit-gateway-propagation?ref=v1.3.82"
  for_each = var.tgw_propagations != null ? { for prop in var.tgw_propagations : prop.key => prop } : {}
  common   = var.common
  depends_on = [
    module.shared_vpc,
    module.transit_gateway,
    module.transit_gateway_route_table
  ]
  tgw_propagation = merge(
    each.value,
    {
      route_table_id = each.value.route_table_id != null ? each.value.route_table_id : (
        each.value.route_table_key != null ?
        module.transit_gateway_route_table[each.value.route_table_key].tgw_rtb_id :
        each.value.route_table_name != null ?
        module.transit_gateway_route_table[each.value.route_table_name].tgw_rtb_id :
        values(module.transit_gateway_route_table)[0].tgw_rtb_id
      )
    }
  )
}

#--------------------------------------------------------------------
# Transit Gateway routes - Creates Transit Gateway routes for shared services
#--------------------------------------------------------------------
module "transit_gateway_route" {
  source   = "git::https://github.com/njibrigthain100/Cognitech-terraform-iac-modules.git//terraform/modules/Transit-gateway-routes?ref=v1.1.17"
  for_each = var.tgw_routes != null ? { for route in var.tgw_routes : route.key => route } : {}
  common   = var.common
  depends_on = [
    module.shared_vpc,
  ]
  tgw_routes = {
    name                   = each.value.name
    blackhole              = each.value.blackhole
    destination_cidr_block = each.value.destination_cidr_block
    attachment_id          = each.value.blackhole == false ? (each.value.attachment_id != null ? each.value.attachment_id : module.transit_gateway_attachment[0].tgw_attachment_id) : null
    route_table_id = each.value.route_table_id != null ? each.value.route_table_id : (
      each.value.route_table_key != null ?
      module.transit_gateway_route_table[each.value.route_table_key].tgw_rtb_id :
      each.value.route_table_name != null ?
      module.transit_gateway_route_table[each.value.route_table_name].tgw_rtb_id :
      values(module.transit_gateway_route_table)[0].tgw_rtb_id
    )
  }
}

# #--------------------------------------------------------------------
# # Transit Gateway subnet routes - Creates Transit Gateway subnet routes for subnets
# #--------------------------------------------------------------------
module "transit_gateway_subnet_route" {
  source   = "git::https://github.com/njibrigthain100/Cognitech-terraform-iac-modules.git//terraform/modules/Transit-gateway-subnet-route?ref=v1.1.18"
  for_each = var.tgw_subnet_route != null ? { for route in var.tgw_subnet_route : route.name => route } : {}
  common   = var.common
  depends_on = [
    module.shared_vpc,
    module.transit_gateway
  ]
  tgw_subnet_route = {
    route_table_id     = each.value.create_public_route ? module.shared_vpc[each.value.vpc_name].public_routes[each.value.subnet_name].public_route_table_id : module.shared_vpc[each.value.vpc_name].private_routes[each.value.subnet_name].private_route_table_id
    transit_gateway_id = each.value.transit_gateway_id != null ? each.value.transit_gateway_id : module.transit_gateway[0].transit_gateway_id
    cidr_block         = each.value.cidr_block
    subnet_name        = each.value.subnet_name
  }
}


# #--------------------------------------------------------------------
# # Creates ram resources
# #--------------------------------------------------------------------
# module "ram" {
#   source = "git::https://github.com/njibrigthain100/Cognitech-terraform-iac-modules.git//terraform/modules/RAM?ref=v1.3.69"
#   count  = var.transit_gateway != null && try(var.transit_gateway.ram != null && var.transit_gateway.ram.enabled == true, false) && length(module.transit_gateway) > 0 ? 1 : 0
#   common = var.common
#   depends_on = [
#     module.transit_gateway
#   ]
#   ram = {
#     key                       = try(var.transit_gateway.ram.key, "")
#     enabled                   = try(var.transit_gateway.ram.enabled, false)
#     share_name                = try(var.transit_gateway.ram.share_name, "")
#     allow_external_principals = try(var.transit_gateway.ram.allow_external_principals, true)
#     resource_arns             = [module.transit_gateway[0].tgw_arn]
#     principals                = try(var.transit_gateway.ram.principals, [])
#   }
# }

#--------------------------------------------------------------------
# S3 Private app bucket
#--------------------------------------------------------------------
module "s3_app_bucket" {
  source   = "git::https://github.com/njibrigthain100/Cognitech-terraform-iac-modules.git//terraform/modules/S3-Private-bucket?ref=v1.3.75"
  for_each = (var.s3_private_buckets != null) ? { for item in var.s3_private_buckets : item.name => item } : {}
  common   = var.common
  s3 = merge(
    {
      name              = each.value.name
      description       = each.value.description
      enable_versioning = each.value.enable_versioning
      replication       = each.value.replication != null ? each.value.replication : null
      encryption        = each.value.encryption != null ? each.value.encryption : null
      objects           = each.value.objects != null ? each.value.objects : null
    },
    (each.value.enable_bucket_policy != false && each.value.policy != null) ? { policy = each.value.policy } : {}
  )
}



#--------------------------------------------------------------------
# IAM Roles and Policies
#--------------------------------------------------------------------
module "iam_roles" {
  source   = "git::https://github.com/njibrigthain100/Cognitech-terraform-iac-modules.git//terraform/modules/IAM-Roles?ref=v1.4.18"
  for_each = (var.iam_roles != null) ? { for item in var.iam_roles : item.name => item } : {}
  common   = var.common
  iam_role = merge(
    each.value,
    {
      policy = each.value.policy != null ? each.value.policy : null
    }
  )
}

#--------------------------------------------------------------------
# EC2 instance profiles
#--------------------------------------------------------------------
module "ec2_profiles" {
  source       = "git::https://github.com/njibrigthain100/Cognitech-terraform-iac-modules.git//terraform/modules/EC2-profiles?ref=v1.1.77"
  for_each     = (var.ec2_profiles != null) ? { for item in var.ec2_profiles : item.name => item } : {}
  common       = var.common
  ec2_profiles = each.value
}

#--------------------------------------------------------------------
# IAM policies
#--------------------------------------------------------------------
module "iam_policies" {
  source     = "git::https://github.com/njibrigthain100/Cognitech-terraform-iac-modules.git//terraform/modules/IAM-Policies?ref=v1.1.77"
  for_each   = (var.iam_policies != null) ? { for item in var.iam_policies : item.name => item } : {}
  common     = var.common
  iam_policy = each.value
}

#--------------------------------------------------------------------
# Creates key pairs for EC2 instances
#--------------------------------------------------------------------
module "ec2_key_pairs" {
  source   = "git::https://github.com/njibrigthain100/Cognitech-terraform-iac-modules.git//terraform/modules/EC2-key-pair?ref=v1.3.73"
  for_each = (var.key_pairs != null) ? { for item in var.key_pairs : item.name => item } : {}
  common   = var.common
  key_pair = each.value
}

#--------------------------------------------------------------------
# Creates Certificates
#--------------------------------------------------------------------
module "certificates" {
  source   = "git::https://github.com/njibrigthain100/Cognitech-terraform-iac-modules.git//terraform/modules/ACM-Public-Certs?ref=v1.2.29"
  for_each = var.certificates != null ? { for item in var.certificates : item.name => item } : {}
  common   = var.common
  certificate = {
    name              = each.value.name
    domain_name       = each.value.domain_name
    validation_method = each.value.validation_method
    zone_name         = each.value.zone_name
  }
}

#--------------------------------------------------------------------
# Creates AWS Backup 
#--------------------------------------------------------------------
module "backups" {
  source   = "git::https://github.com/njibrigthain100/Cognitech-terraform-iac-modules.git//terraform/modules/AWSBackup?ref=v1.2.97"
  for_each = var.backups != null ? { for item in var.backups : item.name => item } : {}
  common   = var.common
  backup   = each.value
}

#--------------------------------------------------------------------
# Createss load balancers
#--------------------------------------------------------------------
module "load_balancers" {
  source   = "git::https://github.com/njibrigthain100/Cognitech-terraform-iac-modules.git//terraform/modules/Load-Balancers?ref=v1.2.98"
  for_each = (var.load_balancers != null) ? { for item in var.load_balancers : item.key => item } : {}
  common   = var.common
  load_balancer = merge(
    each.value,
    {
      security_groups = [
        for sg_key in each.value.security_groups :
        module.shared_vpc[each.value.vpc_name].security_group[sg_key].id
      ]
      subnets = flatten([
        for subnet_key in each.value.subnets :
        (each.value.use_private_subnets == true) ?
        module.shared_vpc[each.value.vpc_name].private_subnet[subnet_key].subnet_ids :
        module.shared_vpc[each.value.vpc_name].public_subnet[subnet_key].subnet_ids
      ])
      subnet_mappings = (each.value.subnet_mappings != null) ? [
        for mapping in each.value.subnet_mappings : {
          subnet_id = lookup(
            module.shared_vpc[each.value.vpc_name].private_subnet[mapping.subnet_key],
            "${mapping.az_subnet_selector}_subnet_id",
            null
          )
          private_ipv4_address = mapping.private_ipv4_address
        }
      ] : []
      # Set default certificate from shared VPC module when create_default_listener is true
      default_listener = (each.value.create_default_listener == true) ? merge(
        {
          port        = 443
          protocol    = "HTTPS"
          action_type = "fixed-response"
          ssl_policy  = "ELBSecurityPolicy-2016-08"
          fixed_response = {
            content_type = "text/plain"
            message_body = "Oops! The page you are looking for does not exist."
            status_code  = "200"
          }
        },
        lookup(each.value, "default_listener", {}),
        {
          certificate_arn = try(lookup(each.value, "default_listener", {}).certificate_arn, null) != null ? lookup(each.value, "default_listener", {}).certificate_arn : try(module.certificates[each.value.vpc_name].arn, null)
        }
      ) : null
    }
  )
}


#--------------------------------------------------------------------
# Creates secrets
#--------------------------------------------------------------------
module "secrets" {
  source          = "git::https://github.com/njibrigthain100/Cognitech-terraform-iac-modules.git//terraform/modules/Secrets-manager?ref=v1.3.74"
  for_each        = (var.secrets != null) ? { for item in var.secrets : item.key => item } : {}
  common          = var.common
  secrets_manager = each.value
}


#--------------------------------------------------------------------
# Creates SSM Parameters
#--------------------------------------------------------------------
module "ssm_parameters" {
  source   = "git::https://github.com/njibrigthain100/Cognitech-terraform-iac-modules.git//terraform/modules/SSM-Parameter-store?ref=v1.2.45"
  for_each = (var.ssm_parameters != null) ? { for item in var.ssm_parameters : item.name => item } : {}
  common   = var.common
  ssm_parameter = merge(
    each.value,
    {
      value = each.value.secret_key != null ? module.secrets[each.value.secret_key].name : each.value.value
    }
  )
}

#--------------------------------------------------------------------
# Target groups
#--------------------------------------------------------------------
module "target_groups" {
  source   = "git::https://github.com/njibrigthain100/Cognitech-terraform-iac-modules.git//terraform/modules/Target-groups?ref=v1.2.98"
  for_each = (var.target_groups != null) ? { for item in var.target_groups : item.key => item } : {}
  common   = var.common
  target_group = merge(
    each.value,
    {
      vpc_id = each.value.vpc_name != null ? module.shared_vpc[each.value.vpc_name].vpc_id : each.value.vpc_id
    }
  )
}

#--------------------------------------------------------------------
# ALB listeners
#--------------------------------------------------------------------
module "alb_listeners" {
  source   = "git::https://github.com/njibrigthain100/Cognitech-terraform-iac-modules.git//terraform/modules/alb-listeners?ref=v1.2.98"
  for_each = (var.alb_listeners != null) ? { for item in var.alb_listeners : item.key => item } : {}
  common   = var.common
  alb_listener = merge(
    each.value,
    {
      # Resolve load balancer ARN from the load balancer key
      alb_arn = try(
        module.load_balancers[each.value.alb_key].arn,
        each.value.alb_arn
      )
      certificate_arn = each.value.protocol == "HTTPS" ? try(
        module.certificates[each.value.vpc_name].arn,
        each.value.certificate_arn
      ) : null
      vpc_id = each.value.vpc_name != null ? module.shared_vpc[each.value.vpc_name].vpc_id : each.value.vpc_id
      target_group = each.value.target_group != null ? merge(
        each.value.target_group,
        {
          attachments = each.value.target_group.attachments != null ? each.value.target_group.attachments : []
        }
      ) : null
    }
  )
}

#--------------------------------------------------------------------
# ALB listener rules
#--------------------------------------------------------------------
module "alb_listener_rules" {
  source   = "git::https://github.com/njibrigthain100/Cognitech-terraform-iac-modules.git//terraform/modules/alb-listener-rule?ref=v1.2.98"
  for_each = (var.alb_listener_rules != null) ? { for item in var.alb_listener_rules : item.index_key => item } : {}
  common   = var.common
  rule = [
    for item in each.value.rules : merge(
      item,
      {
        listener_arn = each.value.listener_key != null ? module.alb_listeners[each.value.listener_key].alb_listener_arn : each.value.listener_arn
        target_groups = [
          for tg in item.target_groups :
          {
            arn    = tg.tg_name != null ? module.target_groups[tg.tg_name].target_group_arn : tg.arn
            weight = tg.weight
          }
        ]
      }
    )
  ]
}

#--------------------------------------------------------------------
# NLB listeners
#--------------------------------------------------------------------
module "nlb_listeners" {
  source   = "git::https://github.com/njibrigthain100/Cognitech-terraform-iac-modules.git//terraform/modules/nlb-listener?ref=v1.2.98"
  for_each = (var.nlb_listeners != null) ? { for item in var.nlb_listeners : item.key => item } : {}
  common   = var.common
  nlb_listener = merge(
    each.value,
    {
      nlb_arn = try(
        module.load_balancers[each.value.nlb_key].arn,
        each.value.nlb_arn
      )
      certificate_arn = each.value.protocol == "TLS" ? try(
        module.certificates[each.value.vpc_name].arn,
        each.value.certificate_arn
      ) : null
      vpc_id = each.value.vpc_name != null ? module.shared_vpc[each.value.vpc_name].vpc_id : each.value.vpc_id
      target_group = each.value.target_group != null ? merge(
        each.value.target_group,
        {
          attachments = each.value.target_group.attachments != null ? each.value.target_group.attachments : []
        }
      ) : null
    }
  )
}

#--------------------------------------------------------------------
# Creates SSM Document and Association
# #--------------------------------------------------------------------
module "ssm_documents" {
  source       = "git::https://github.com/njibrigthain100/Cognitech-terraform-iac-modules.git//terraform/modules/SSM-Documents?ref=v1.3.5"
  for_each     = (var.ssm_documents != null) ? { for item in var.ssm_documents : item.name => item } : {}
  common       = var.common
  ssm_document = each.value
}

#--------------------------------------------------------------------
# Creates lIAM users
#--------------------------------------------------------------------
module "iam_users" {
  source   = "git::https://github.com/njibrigthain100/Cognitech-terraform-iac-modules.git//terraform/modules/IAM-User?ref=v1.3.76"
  for_each = (var.iam_users != null) ? { for item in var.iam_users : item.name => item } : {}
  common   = var.common
  iam_user = each.value
}

#--------------------------------------------------------------------
# IP SET
#--------------------------------------------------------------------
module "ip_sets" {
  source = "git::https://github.com/njibrigthain100/Cognitech-terraform-iac-modules.git//terraform/modules/Waf-ipsets?ref=v1.4.9"
  for_each = var.wafs != null ? {
    for item in flatten([
      for waf in var.wafs : waf.ip_sets != null ? waf.ip_sets : []
    ]) : item.key => item
  } : {}
  common = var.common
  ip_set = each.value
}

#--------------------------------------------------------------------
# Rule Groups
#--------------------------------------------------------------------
module "rule_groups" {
  source = "git::https://github.com/njibrigthain100/Cognitech-terraform-iac-modules.git//terraform/modules/WAF-rulegroup?ref=v1.4.9"
  for_each = var.wafs != null ? {
    for item in flatten([
      for waf in var.wafs : waf.rule_groups != null ? waf.rule_groups : []
    ]) : item.key => item
  } : {}
  common = var.common
  rule_group = merge(
    each.value,
    {
      rules = each.value.rules != null ? [
        for rule in each.value.rules : merge(
          rule,
          {
            ip_set_arn = rule.ip_set_key != null ? module.ip_sets[rule.ip_set_key].ip_set_arn : rule.ip_set_arn
          }
        )
      ] : []
    }
  )
}

#--------------------------------------------------------------------
# WAF
#--------------------------------------------------------------------
module "waf" {
  source   = "git::https://github.com/njibrigthain100/Cognitech-terraform-iac-modules.git//terraform/modules/WAF?ref=v1.4.11"
  for_each = (var.wafs != null) ? { for item in var.wafs : item.key => item } : {}
  common   = var.common
  waf = merge(
    each.value,
    {
      custom_rules = each.value.custom_rules != null ? [
        for rule in each.value.custom_rules : merge(
          rule,
          {
            ip_set_arn = rule.ip_set_key != null ? module.ip_sets[rule.ip_set_key].ip_set_arn : (rule.ip_set_arn != null ? rule.ip_set_arn : null)
          }
        )
      ] : []
    },
    {
      rule_group_references = each.value.rule_group_references != null ? [
        for rg in each.value.rule_group_references : merge(
          rg, {
            arn = rg.rule_group_key != null ? module.rule_groups[rg.rule_group_key].rule_group_arn : rg.arn
          }
        )
      ] : []
    },
    {
      association = each.value.association != null ? (
        each.value.association.associate_alb == true ? merge(
          each.value.association,
          {
            alb_arns = each.value.association.alb_arns != null ? each.value.association.alb_arns : (
              each.value.association.alb_keys != null ? [
                for alb_key in each.value.association.alb_keys :
                module.load_balancers[alb_key].arn
              ] : []
            )
          }
        ) : null
      ) : null
    }
  )
}

#--------------------------------------------------------------------
# Creates EKS clusters
#--------------------------------------------------------------------
module "eks_clusters" {
  source   = "git::https://github.com/njibrigthain100/Cognitech-terraform-iac-modules.git//terraform/modules/EKS-Cluster?ref=v1.4.31"
  for_each = (var.eks_clusters != null) ? { for item in var.eks_clusters : item.create_eks_cluster ? item.key : null => item if item.create_eks_cluster } : {}
  common   = var.common
  eks_cluster = merge(
    each.value,
    {
      role_arn = each.value.role_key != null ? module.iam_roles[each.value.role_key].iam_role_arn : each.value.role_arn
    },
    {
      subnet_ids = each.value.subnet_keys != null ? flatten([
        for subnet_key in each.value.subnet_keys :
        (each.value.use_private_subnets == true) ?
        module.shared_vpc[each.value.vpc_name].private_subnet[subnet_key].subnet_ids :
        module.shared_vpc[each.value.vpc_name].public_subnet[subnet_key].subnet_ids
      ]) : each.value.subnet_ids
    }
  )
}


