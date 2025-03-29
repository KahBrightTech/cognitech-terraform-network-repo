#--------------------------------------------------------------------
# VPC - Creates a VPC  to the target account
#--------------------------------------------------------------------
module "vpc" {
  source = "git::https://github.com/njibrigthain100/Cognitech-terraform-iac-modules.git//terraform/modules/vpc?ref=v1.38"
  # source = "git@github.com:njibrigthain100/Cognitech-terraform-iac-modules.git//terraform/modules/vpc?ref=v1.35"
  vpc    = var.vpc
  common = var.common
}

#--------------------------------------------------------------------
# Subnets - Creates private subnets
#--------------------------------------------------------------------
module "private_subnets" {
  source = "git::https://github.com/njibrigthain100/Cognitech-terraform-iac-modules.git//terraform/modules/subnets/private_subnets?ref=v1.38"
  # for_each        = { for private_subnet in var.vpc.private_subnets : private_subnet.name => private_subnet }
  vpc_id          = module.vpc.vpc_id
  private_subnets = var.vpc.private_subnets
  common          = var.common
}

#--------------------------------------------------------------------
# Subnets - Creates public subnets
#--------------------------------------------------------------------

module "public_subnets" {
  source         = "git::https://github.com/njibrigthain100/Cognitech-terraform-iac-modules.git//terraform/modules/subnets/public_subnets?ref=v1.38"
  vpc_id         = module.vpc.vpc_id
  public_subnets = var.vpc.public_subnets
  common         = var.common
}

#--------------------------------------------------------------------
# Natgateway - Creates natgateways
#--------------------------------------------------------------------
module "ngw" {
  source = "git::https://github.com/njibrigthain100/Cognitech-terraform-iac-modules.git//terraform/modules/natgateway?ref=v1.38"
  bypass = (var.vpc.nat_gateway == null)
  common = var.common
  nat_gateway = {
    name                = var.vpc.nat_gateway != null ? var.vpc.nat_gateway.name : "unknown"
    subnet_id_primary   = module.public_subnets.primary_subnet_id
    subnet_id_secondary = module.public_subnets.secondary_subnet_id
    subnet_id_tertiary  = module.public_subnets.tertiary_subnet_id
    type                = var.vpc.nat_gateway != null ? var.vpc.nat_gateway.type : "unknown"
  }
}

#--------------------------------------------------------------------
# Subnet Route - Creates Public routes
#--------------------------------------------------------------------
module "public_route" {
  source = "git::https://github.com/njibrigthain100/Cognitech-terraform-iac-modules.git//terraform/modules/Routes/public_routes?ref=v1.35"
  vpc_id = module.vpc.vpc_id
  public_routes = {
    public_gateway_id      = module.vpc.igw_id
    destination_cidr_block = var.vpc.public_routes.destination_cidr_block
    primary_subnet_id      = module.public_subnets.primary_subnet_id
    secondary_subnet_id    = module.public_subnets.secondary_subnet_id
    tertiary_subnet_id     = module.public_subnets.tertiary_subnet_id
  }
  common = var.common
}

#--------------------------------------------------------------------
# Subnet Route - Creates Private routes
#--------------------------------------------------------------------
module "private_route" {
  source = "git::https://github.com/njibrigthain100/Cognitech-terraform-iac-modules.git//terraform/modules/Routes/private_routes?ref=v1.63"
  vpc_id = module.vpc.vpc_id
  private_routes = {
    nat_gateway_id         = module.ngw.ngw_gateway_primary_id
    primary_subnet_id      = module.private_subnets.primary_subnet_id
    secondary_subnet_id    = module.private_subnets.secondary_subnet_id
    tertiary_subnet_id     = module.private_subnets.tertiary_subnet_id
    destination_cidr_block = var.vpc.private_routes.destination_cidr_block
  }
  common = var.common
}

module "security_groups" {
  source   = "git::https://github.com/njibrigthain100/Cognitech-terraform-iac-modules.git//terraform/modules/Security-group?ref=v1.69"
  common   = var.common
  for_each = var.vpc != null ? var.vpc.security_groups != null ? { for item in var.vpc.security_groups : item.key => item } : {} : {}
  security_group = {
    name                   = each.value.name
    vpc_id                 = module.vpc.vpc_id
    name_prefix            = each.value.name_prefix
    description            = each.value.description
    security_group_egress  = each.value.egress
    security_group_ingress = each.value.ingress
  }

}

module "security_group_rules" {
  source   = "git::https://github.com/njibrigthain100/Cognitech-terraform-iac-modules.git//terraform/modules/Security-group-rules?ref=v1.69"
  common   = var.common
  for_each = var.vpc != null ? var.vpc.security_group_rules != null ? { for item in var.vpc.security_groups_rules : item.sg_key => item } : {} : {}
  security_group = {
    security_group_id = module.security_groups[each.value.sg_key].security_group_id
    egress_rules      = each.value.egress
    ingress_rules     = each.value.ingress
  }
}









