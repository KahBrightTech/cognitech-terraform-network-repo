locals {
  cidr_blocks = {
    mdpp = {
      segments = {
        shared_services = {
          vpc = "10.1.2.0/24"
          public_subnets = {
            primary   = "10.1.2.128/26"
            secondary = "10.1.2.192/26"
          }
          private_subnets = {
            primary   = "10.1.2.0/26"
            secondary = "10.1.2.64/26"
          }
        }
        dev = {
          vpc = "10.1.1.0/24"
          public_subnets = {
            primary   = "10.1.1.128/26"
            secondary = "10.1.1.192/26"
          }
          private_subnets = {
            primary   = "10.1.1.0/26"
            secondary = "10.1.1.64/26"
          }
        }
        trn = {
          vpc = "10.1.3.0/24"
          public_subnets = {
            primary   = "10.1.3.128/26"
            secondary = "10.1.3.192/26"
          }
          private_subnets = {
            primary   = "10.1.3.0/26"
            secondary = "10.1.3.64/26"
          }
        }
      }
    }
    dcp = {
      segments = {
        shared_services = {
          vpc = "10.1.2.0/24"
          public_subnets = {
            primary   = "10.1.2.128/26"
            secondary = "10.1.2.192/26"
          }
          private_subnets = {
            primary   = "10.1.2.0/26"
            secondary = "10.1.2.64/26"
          }
        }
        mdpp = {
          vpc = "10.1.1.0/24"
          public_subnets = {
            primary   = "10.1.1.128/26"
            secondary = "10.1.1.192/26"
          }
          private_subnets = {
            primary   = "10.1.1.0/26"
            secondary = "10.1.1.64/26"
          }
        }
        trn = {
          vpc = "10.1.3.0/24"
          public_subnets = {
            primary   = "10.1.3.128/26"
            secondary = "10.1.3.192/26"
          }
          private_subnets = {
            primary   = "10.1.3.0/26"
            secondary = "10.1.3.64/26"
          }
        }
      }
    }
  }
}

