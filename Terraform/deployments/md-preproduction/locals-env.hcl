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
  }
  remote_dynamodb_table = "Terraform"
  tags = {
    Environment  = local.environment
    Owner        = local.owner
    Build-method = local.build
    Compliance   = local.compliance
  }
}
