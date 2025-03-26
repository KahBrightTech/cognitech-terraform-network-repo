
#--------------------------------------------------------------------
# Data block to fetch values from the console 
#--------------------------------------------------------------------
data "aws_ec2_transit_gateway" "tgw" {
  filter {
    name   = "tag:Name"
    values = ["${var.common.account_name}-${var.common.region_prefix}-${var.tgw_attachments.shared_vpc_name}"]
  }
}
data "aws_vpc" "shared_vpc" {
  filter {
    name   = "tag:Name"
    values = ["${var.common.account_name}-${var.common.region_prefix}-${var.tgw_attachments.shared_vpc_name}-vpc"]
  }
}

data "aws_subnet" "primary-public" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.shared_vpc.id]
  }

  filter {
    name   = "tag:Name"
    values = ["${var.common.account_name}-${var.common.region_prefix}-${var.tgw_attachments.shared_vpc_name}-pub-primary"]
  }
}

data "aws_subnet" "secondary-public" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.shared_vpc.id]
  }

  filter {
    name   = "tag:Name"
    values = ["${var.common.account_name}-${var.common.region_prefix}-${var.tgw_attachments.shared_vpc_name}-pub-secondary"]
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

#--------------------------------------------------------------------
# Transit Gateway attacments - Creates Transit Gateway attachments
#--------------------------------------------------------------------
module "transit_gateway_attachment" {
  source = "../../modules/Transit-gateway-attachments"
  common = var.common
  vpc_id = module.customer_vpc[var.tgw_attachments.name].vpc_id
  depends_on = [
    module.customer_vpc
  ]
  tgw_attachments = {
    transit_gateway_id = data.aws_ec2_transit_gateway.tgw.id
    subnet_ids = [
      module.customer_vpc[var.tgw_attachments.name].primary_private_subnet_id, # The output for the shared vpc comes from the create vpc formation hence has an object with all the variables
      module.customer_vpc[var.tgw_attachments.name].secondary_private_subnet_id,
    ]
    name = var.tgw_attachments.name
  }
}

#--------------------------------------------------------------------
# Transit Gateway routes - Creates Transit Gateway routes
#--------------------------------------------------------------------

module "transit_gateway_route" {
  source     = "../../modules/Transit-gateway-routes"
  common     = var.common
  depends_on = [module.customer_vpc]
  for_each   = { for idx, route in var.tgw_routes : idx => route }
  tgw_routes = {
    name               = each.value.name
    transit_gateway_id = data.aws_ec2_transit_gateway.tgw.id
    route_table_id     = module.customer_vpc[var.tgw_attachments.name].private_route_table_id
    vpc_cidr_block     = each.value.vpc_cidr_block
  }

}
