locals {
  cloud = read_terragrunt_config(find_in_parent_folders("locals-cloud.hcl"))

  # Simple variables 
  name_abr = "devpp"
  # Environment tags 
  build       = "terraform"
  compliance  = "hippaa"
  environment = "sit"
  owner       = "kbrigthain@gmail.com"

  remote_state_bucket = {
    primary   = "dev-us-east-1-network-config-state"
    secondary = "dev-us-west-2-network-config-state"
  }

  subnet_prefix = {
    primary    = "sbnt1"
    secondary  = "sbnt2"
    tertiary   = "sbnt3"
    quaternary = "sbnt4"
  }
  public_domain = "bkuat.org"
  kms_key_id = {
    primary   = "arn:aws:kms:us-east-1:533267408704:key/4156a257-7fc8-4912-9d95-0ed7b66b2055"
    secondary = "arn:aws:kms:us-west-2:533267408704:key/d1ab279b-8065-4df5-ac03-0dce0ca0487b"
  }
  remote_dynamodb_table = "terragrunt-lock-table"
  tags = {
    Environment  = local.environment
    Owner        = local.owner
    Build-method = local.build
    Compliance   = local.compliance
  }
}
