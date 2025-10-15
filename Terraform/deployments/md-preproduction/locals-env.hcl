locals {
  cloud = read_terragrunt_config(find_in_parent_folders("locals-cloud.hcl"))

  # Simple variables 
  name_abr = "mdpp"
  # Environment tags 
  build       = "terraform"
  compliance  = "hippaa"
  environment = "md-preprod"
  owner       = "kbrigthain@gmail.com"
  repo_name   = "cognitech-terraform-network-repo"

  remote_state_bucket = {
    primary   = "md-preprod-us-east-1-network-config-state"
    secondary = "md-preprod-us-west-2-network-config-state"
  }

  subnet_prefix = {
    primary    = "sbnt1"
    secondary  = "sbnt2"
    tertiary   = "sbnt3"
    quaternary = "sbnt4"
  }
  public_domain         = "kahbrigthllc.com"
  remote_dynamodb_table = "terragrunt-lock-table"
  tags = {
    Environment  = local.environment
    Owner        = local.owner
    Build-method = local.build
    Compliance   = local.compliance
  }

  secret_names = {
    ansible = "ansible-auth"
    user    = "user-auth"
    docker  = "docker-auth"
    keys    = "ec2-private-key-pair"
  }

  # RAM principals as a list of strings (AWS account IDs)
  ram_principals = [
    "730335294148"  # intpp account
    # "123456789012",  # dev account
    # "987654321098",  # staging account
    # "555666777888"   # prod account
  ]
}

