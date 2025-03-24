
#--------------------------------------------------------------------
# Data block to fetch values from the console 
#--------------------------------------------------------------------
data "aws_ec2_transit_gateway" "tgw" {
  filter {
    name   = "tag:Name"
    values = ["${var.common.account_name}-${var.common.region_prefix}-${var.tgw_attachments.transit_gateway_name}"]
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
  vpc_id = module.customer_vpc[var.tgw_attachments.customer_vpc_name].vpc_id
  tgw_attachments = {
    transit_gateway_id = data.aws_ec2_transit_gateway.tgw.id
    subnet_ids = [
      data.aws_subnet.primary-public.id,
      data.aws_subnet.secondary-public.id
    ]
    transit_gateway_name = var.tgw_attachments.transit_gateway_name
    shared_vpc_name      = var.tgw_attachments.shared_vpc_name
    customer_vpc_name    = var.tgw_attachments.customer_vpc_name
  }
}
