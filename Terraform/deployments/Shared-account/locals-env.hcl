locals {
  cloud = read_terragrunt_config(find_in_parent_folders("locals-cloud.hcl"))

  # Simple variables 
  name_abr = "mdp"

  # Environment tags 
  build       = "terraform"
  compliance  = "hippaa"
  environment = "sit"
  owner       = "kbrigthain@gmail.com"

  remote_state_bucket = {
    primary   = "terragruntuse1"
    secondary = "terragruntusw2"
  }


  subnet = {
    private = {
      primary   = "priv"
      secondary = "priv"
    }
    public = {
      primary   = "pub"
      secondary = "pub"
    }
  }

  remote_dynamodb_table = "Terraform"

  # account_name   = local.cloud.locals.account_name.kah.name
  # account_number = local.cloud.locals.account_name.kah.number
  # billing_code   = local.cloud.locals.billing_code_number.kah
  tags = {
    Environment  = local.environment
    Owner        = local.owner
    Build-method = local.build
    Compliance   = local.compliance
  }
}
