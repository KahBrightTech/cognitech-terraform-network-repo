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
    ansible = "ansible-auths"
    user    = "user-auths"
    docker  = "docker-auths"
    keys    = "ec2-private-key-pairs"
  }

  # RAM principals as a list of strings (AWS account IDs)
  ram_principals = [
    "730335294148"  # intpp account
  ]
}

