locals {
  cloud = read_terragrunt_config(find_in_parent_folders("locals-cloud.hcl"))

  # Simple variables 
  name_abr = "intp"
  # Environment tags 
  build       = "terraform"
  compliance  = "hippaa"
  environment = "int-production"
  owner       = "kbrigthain@gmail.com"

  remote_state_bucket = {
    primary   = "int-prod-us-east-1-network-config-state"
    secondary = "int-prod-us-west-2-network-config-state"
  }

  subnet_prefix = {
    primary    = "sbnt1"
    secondary  = "sbnt2"
    tertiary   = "sbnt3"
    quaternary = "sbnt4"
  }
  public_domain = "novutechnologies.net"
  kms_key_id = {
    primary   = "arn:aws:kms:us-east-1:271457809232:key/a3f60d5d-8e1c-4af8-a1c8-66057e94bfca"
    secondary = "arn:aws:kms:us-west-2:271457809232:key/358fc172-cd8d-405e-b6b1-be43654fbb39"
  }
  remote_dynamodb_table = "terragrunt-lock-table"
  tags = {
    Environment  = local.environment
    Owner        = local.owner
    Build-method = local.build
    Compliance   = local.compliance
  }

  # secret_names = {
  #   ansible = "ansible-authentication"
  #   user    = "user-login"
  #   docker  = "docker-auth"
  #   keys    = "ec2-private-key-pairs"
  #   iam_user = "user"
  # }

  eks_roles = {
    admin    = "arn:aws:iam::271457809232:role/aws-reserved/sso.amazonaws.com/AWSReservedSSO_AdministratorAccess_7f215b32fef26e47"
    network  = "arn:aws:iam::271457809232:role/aws-reserved/sso.amazonaws.com/AWSReservedSSO_NetworkAdministrator_b9b78eb5953b12dd"
    system   = "arn:aws:iam::271457809232:role/aws-reserved/sso.amazonaws.com/AWSReservedSSO_SystemAdministrator_7845d1ed8dcf680a"
    readonly = "arn:aws:iam::271457809232:role/aws-reserved/sso.amazonaws.com/AWSReservedSSO_ReadOnlyAccess_d2947b3732f4ad12"
  }

  eks_cluster_keys = {
    primary_cluster = "novutech"
  }

  ecs_cluster_keys = {
    primary_cluster = "novutech"
  }
}
