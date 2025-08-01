locals {
  cloud = read_terragrunt_config(find_in_parent_folders("locals-cloud.hcl"))

  # Simple variables 
  name_abr = "intpp"
  # Environment tags 
  build       = "terraform"
  compliance  = "hippaa"
  environment = "sit"
  owner       = "kbrigthain@gmail.com"

  remote_state_bucket = {
    primary   = "terragruntint"
    secondary = "terragruntintusw2"
  }

  subnet_prefix = {
    primary    = "sbnt1"
    secondary  = "sbnt2"
    tertiary   = "sbnt3"
    quaternary = "sbnt4"
  }
  public_domain = "cognitechllc.org"
  kms_key_id = {
    primary   = "arn:aws:kms:us-east-1:730335294148:key/784d68ea-880c-4755-ae12-beb3037aefc2"
    secondary = "arn:aws:kms:us-west-2:730335294148:key/357a0937-678f-4c56-b125-66cc3938e29a"
  }
  remote_dynamodb_table = "Terragrunt"
  tags = {
    Environment  = local.environment
    Owner        = local.owner
    Build-method = local.build
    Compliance   = local.compliance
  }
}
