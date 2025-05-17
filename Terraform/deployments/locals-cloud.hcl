#-------------------------------------------------------
# Cloud variables 
#-------------------------------------------------------
locals {
  cidr_block_imp_use1  = read_terragrunt_config("${path_relative_from_include()}/locals-cidr-range-use1.hcl")
  cidr_block_imp_usw2  = read_terragrunt_config("${path_relative_from_include()}/locals-cidr-range-usw2.hcl")
  security_group_rules = read_terragrunt_config("${path_relative_from_include()}/locals-security-group-rules.hcl")
  cidr_block_use1      = local.cidr_block_imp_use1.locals.cidr_blocks
  cidr_block_usw2      = local.cidr_block_imp_usw2.locals.cidr_blocks

  account_name = {
    MD = {
      Preprod = {
        name   = "mdpreproduction"
        number = "485147667400"
      }
      Prod = {
        name   = "mdproduction"
        number = "730335294148"
      }
      name   = "MDPreproduction"
      number = "485147667400"
    }
  }
  billing_code_number = {
    kah = "90471"
    int = "TBD"
    dev = "TBD"
    qa  = "TBD"
  }
  region_prefix = {
    primary   = "use1"
    secondary = "usw2"
  }
  regions = {
    use1 = {
      availability_zones = {
        primary   = "us-east-1a"
        secondary = "us-east-1b"
        tertiary  = "us-east-1c"
      }
      name     = "us-east-1"
      name_abr = "use1"
    }

    usw2 = {
      availability_zones = {
        primary   = "us-west-2a"
        secondary = "us-west-2b"
        tertiary  = "us-west-2c"
      }
      name     = "us-west-2"
      name_abr = "usw2"
    }

    elastic_ips = {
      primary   = ["peipa", "peipb"]
      secondary = ["seipa", "seipb"]
    }

    nat_gateway = {
      primary   = ["pnata", "pnatb"]
      secondary = ["snata", "snatb"]
    }
  }
  repo = {
    root = get_parent_terragrunt_dir()
  }

  lambda = {
    start_instance = {
      runtime              = "python3.9"
      handler              = "index.lambda_handler"
      private_bucklet_name = "cognitech-lambdas-bucket"
      lamda_s3_key         = "start-ec2/index.zip"
      timeout              = "120"
      layer_s3_key         = "layers/layers.zip"
    }
    stop_instance = {
      runtime              = "python3.9"
      handler              = "index.lambda_handler"
      private_bucklet_name = "cognitech-lambdas-bucket"
      lamda_s3_key         = "stop-ec2/index.zip"
      timeout              = "120"
      layer_s3_key         = "layers/layers.zip"
    }
    user_credentials = {
      runtime              = "python3.9"
      handler              = "lambda_handler.lambda_handler"
      private_bucklet_name = "cognitech-lambdas-bucket"
      lamda_s3_key         = "IAM-Credentials/codes/generate_iam_report.zip"
      timeout              = "120"
      layer_s3_key         = "IAM-Credentials/layers/python.zip"
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
