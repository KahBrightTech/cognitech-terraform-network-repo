#-------------------------------------------------------
# Cloud variables 
#-------------------------------------------------------
locals {
  cidr_block_imp_use1  = read_terragrunt_config("${path_relative_from_include()}/locals-cidr-range-use1.hcl")
  cidr_block_imp_usw2  = read_terragrunt_config("${path_relative_from_include()}/locals-cidr-range-usw2.hcl")
  security_group_rules = read_terragrunt_config("${path_relative_from_include()}/locals-security-group-rules.hcl")
  cidr_block_use1      = local.cidr_block_imp_use1.locals.cidr_blocks
  cidr_block_usw2      = local.cidr_block_imp_usw2.locals.cidr_blocks

  repo = {
    root = get_parent_terragrunt_dir()
  }

  account_info = {
    intpp = {
      name   = "int-preproduction"
      number = "730335294148"
    }
    intp = {
      name   = "int-production"
      number = "271457809232"
    }
    mdpp = {
      name   = "md-preproduction"
      number = "533267408704"
    }
    mdp = {
      name   = "md-production"
      number = "388927731914"
    }
    vapp = {
      name   = "va-preproduction"
      number = "526645041140"
    }
    vap = {
      name   = "va-production"
      number = "882680178335"
    }
    mgmnt = {
      name   = "management"
      number = "485147667400"
    }
    ntw = {
      name   = "network"
      number = "637423478842"
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
        primary    = "us-east-1a"
        secondary  = "us-east-1b"
        tertiary   = "us-east-1c"
        quaternary = "us-east-1d"
        quinary    = "us-east-1e"
        senary     = "us-east-1f"

      }
      name     = "us-east-1"
      name_abr = "use1"
    }
    usw2 = {
      availability_zones = {
        primary    = "us-west-2a"
        secondary  = "us-west-2b"
        tertiary   = "us-west-2c"
        quaternary = "us-west-2d"
        quinary    = "us-west-2e"
        senary     = "us-west-2f"
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
  external_cidrs = {
    internet = "0.0.0.0/0"
    org_ip   = "69.143.134.56/32"
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
  secret_names = {
    ansible  = "ansible-authentication"
    user     = "user-login"
    docker   = "docker-auth"
    keys     = "ec2-private-key-pairs"
    iam_user = "user"
    eks_node = "eks-node-private-key"
  }
  # RAM principals as a list of strings (Organization ARN)
  ram_principals = [
    "arn:aws:organizations::485147667400:organization/o-orvtyisdyc" # Replace with your actual Organization ARN
  ]
  ntw_principals = [
    "637423478842" # Replace with your actual Organization ARN
  ]
  repo_name = "cognitech-terraform-network-repo"
  Service_catalog = {
    Training = {
      InstanceStatus = {
        name          = "InstanceStatus"
        description   = "Service Catalog portfolio for all Instance status"
        provider_name = "Brigthain"
        products = [
          {
            name        = "start_instances" # Has to be the same as the provisioning_artifact_parameters keys 
            description = "Start an EC2 instance"
            type        = "CLOUD_FORMATION_TEMPLATE"
            owner       = "Brigthain"
          },
          {
            name        = "stop_instances" # Has to be the same as the provisioning_artifact_parameters keys
            description = "Stop an EC2 instance"
            type        = "CLOUD_FORMATION_TEMPLATE"
            owner       = "Brigthain"
          }
        ]
        provisioning_artifact_parameters = [
          {
            name         = "StartInstanceTemplate"
            description  = "Template to start EC2 instances"
            type         = "CLOUD_FORMATION_TEMPLATE"
            template_url = "https://cognitech-lambdas-bucket.s3.us-east-1.amazonaws.com/Service-Catalog-cfn-templates/LambdaInstanceStart.yaml"
          },
          {
            name         = "StopInstanceTemplate"
            description  = "Template to stop EC2 instances"
            type         = "CLOUD_FORMATION_TEMPLATE"
            template_url = "https://cognitech-lambdas-bucket.s3.us-east-1.amazonaws.com/Service-Catalog-cfn-templates/LambdaInstanceStop.yaml"
          }
        ]
        associate_admin_role   = true
        associate_iam_group    = true
        associate_network_role = true
      }
    }
  }
}
