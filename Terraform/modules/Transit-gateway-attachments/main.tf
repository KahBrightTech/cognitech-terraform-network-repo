#--------------------------------------------------------------------
# Transit Gateway - Creates Transit Gateway
#--------------------------------------------------------------------
module "transit_gateway_attachments" {
  source          = "git::https://github.com/njibrigthain100/Cognitech-terraform-iac-modules.git//terraform/modules/Transit-gateway-attachments?ref=v1.1.1"
  common          = var.common
  tgw_attachments = var.tgw_attachments
  vpc_id          = var.vpc_id
}
