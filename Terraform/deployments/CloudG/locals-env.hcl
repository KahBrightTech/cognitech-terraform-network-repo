locals {
  cloud = read_terragrunt_config(find_in_parent_folders("locals-cloud.hcl"))

  # Simple variables 
  name_abr = "intpp"
  # Environment tags 
  build       = "terraform"
  compliance  = "hippaa"
  environment = "shared"
  owner       = "emeldinelimbu@gmial.com"

  remote_state_bucket = {
    primary   = "cloudguru-us-east-1-network-config-state"
    secondary = "cloudguru-us-west-2-network-config-state"
  }

  subnet_prefix = {
    primary    = "sbnt1"
    secondary  = "sbnt2"
    tertiary   = "sbnt3"
    quaternary = "sbnt4"
  }
  public_domain = "triumphanthands.com"
  kms_key_id = {
    primary   = "arn:aws:kms:us-east-1:586794444719:key/ec6a9f42-22a4-4d0b-ab07-acef099bb747"
    secondary = "arn:aws:kms:us-west-2:586794444719:key/ec9fd8ad-e65e-4223-83e3-c2c5bc7e511f"
  }
  remote_dynamodb_table = "cloudguru-us-east-1-state-lock"
  tags = {
    Environment  = local.environment
    Owner        = local.owner
    Build-method = local.build
    Compliance   = local.compliance
  }
}
