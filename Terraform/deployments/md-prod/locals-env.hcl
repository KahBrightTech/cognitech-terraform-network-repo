locals {
  cloud = read_terragrunt_config(find_in_parent_folders("locals-cloud.hcl"))

  # Simple variables 
  name_abr = "mdp"
  # Environment tags 
  build       = "terraform"
  compliance  = "hippaa"
  environment = "uat"
  owner       = "kbrigthain@gmail.com"

  remote_state_bucket = {
    primary   = "prod-us-east-1-network-config-state"
    secondary = "prod-us-west-2-network-config-state"
  }

  subnet_prefix = {
    primary    = "sbnt1"
    secondary  = "sbnt2"
    tertiary   = "sbnt3"
    quaternary = "sbnt4"
  }

  remote_dynamodb_table = "Terragrunt"
  tags = {
    Environment  = local.environment
    Owner        = local.owner
    Build-method = local.build
    Compliance   = local.compliance
  }
}
