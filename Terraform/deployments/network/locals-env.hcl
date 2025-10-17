locals {
  cloud = read_terragrunt_config(find_in_parent_folders("locals-cloud.hcl"))

  # Simple variables 
  name_abr = "ntw"
  # Environment tags 
  build       = "terraform"
  compliance  = "hippaa"
  environment = "md-preprod"
  owner       = "kbrigthain@gmail.com"
  repo_name   = "cognitech-terraform-network-repo"

  remote_state_bucket = {
    primary   = "network-us-east-1-network-config-state"
    secondary = "network-us-west-2-network-config-state"
  }

  subnet_prefix = {
    primary    = "sbnt1"
    secondary  = "sbnt2"
    tertiary   = "sbnt3"
    quaternary = "sbnt4"
  }
  public_domain         = "kahbrigthllc.com"
  remote_dynamodb_table = "Terragrunt"
  tags = {
    Environment  = local.environment
    Owner        = local.owner
    Build-method = local.build
    Compliance   = local.compliance
  }

  secret_names = {
    ansible = "ansible-authentication"
    user    = "user-login"
    docker  = "docker-auth"
    keys    = "ec2-private-key-pairs"
    iam_user = "user"
  }

  # RAM principals as a list of strings (Organization ARN)
  ram_principals = [
    "arn:aws:organizations::485147667400:organization/o-orvtyisdyc" # Replace with your actual Organization ARN
  ]
}

