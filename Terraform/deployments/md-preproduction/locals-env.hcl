locals {
  cloud = read_terragrunt_config(find_in_parent_folders("locals-cloud.hcl"))

  # Simple variables 
  name_abr = "mdpp"

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
  tags = {
    Environment  = local.environment
    Owner        = local.owner
    Build-method = local.build
    Compliance   = local.compliance
  }
}
