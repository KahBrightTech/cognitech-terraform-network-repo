
#--------------------------------------------------------------------
# Data block to fetch values from the console 
#--------------------------------------------------------------------
data "aws_ec2_transit_gateway" "tgw" {
  filter {
    name   = "tag:Name"
    values = "${var.common.account_name}-${var.common.region_prefix}-${var.tgw_attachments.transit_gateway_name}"
  }
}
data "aws_vpc" "shared_vpc" {
  filter {
    name   = "tag:Name"
    values = "${var.common.account_name}-${var.common.region_prefix}-${var.tgw_attachments.shared_vpc_name}"
  }
}

data "aws_subnet" "primary" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.shared_vpc.id]
  }

  filter {
    name   = "tag:Name"
    values = "${var.common.account_name}-${var.common.region_prefix}-${var.public_subnets.name}-primary"
  }
}

#--------------------------------------------------------------------
# Creating customer resources
#--------------------------------------------------------------------
module "customer_vpc" {
  source   = "../Create-Network"
  for_each = { for vpc in var.vpcs : vpc.name => vpc }
  vpc      = each.value
  common   = var.common
}

module "transit_gateway_attachment" {
  source                          = "../../modules/Transit-gateway-attachment"
  common                          = var.common
  transit_gateway_id              = data.aws_ec2_transit_gateway.tgw.id
  app_private_primary_subnet_id   = module.customer_vpc.private_primary_subnet_id
  app_private_secondary_subnet_id = module.customer_vpc.private_secondary_subnet_id
  app_vpc_id                      = module.customer_vpc.vpc_id
}
