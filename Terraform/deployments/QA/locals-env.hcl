locals {
  cloud = read_terragrunt_config(find_in_parent_folders("locals-cloud.hcl"))

  # Simple variables 
  name_abr = "qapp"
  # Environment tags 
  build       = "terraform"
  compliance  = "hippaa"
  environment = "sit"
  owner       = "kbrigthain@gmail.com"

  remote_state_bucket = {
    primary   = "qa-us-east-1-network-config-state"
    secondary = "qa-us-east-1-network-config-state"
  }

  subnet_prefix = {
    primary    = "sbnt1"
    secondary  = "sbnt2"
    tertiary   = "sbnt3"
    quaternary = "sbnt4"
  }
  public_domain = "bkuat.org"
  kms_key_id = {
    primary   = "arn:aws:kms:us-east-1:271457809232:key/0c98cbf8-e93c-4b18-9075-c5b936808096"
    secondary = "arn:aws:kms:us-west-2:271457809232:key/afe7eb34-1410-44bf-8b65-d27d19e63dad"
  }
  remote_dynamodb_table = "Terragrunt"
  tags = {
    Environment  = local.environment
    Owner        = local.owner
    Build-method = local.build
    Compliance   = local.compliance
  }
}
