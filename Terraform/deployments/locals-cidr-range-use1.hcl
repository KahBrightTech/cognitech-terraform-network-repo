locals {
  cidr_blocks = {
    mdpp = {
      segments = {
        Account_cidr = "10.1.0.0/16"
        shared-services = {
          vpc = "10.1.2.0/24"
          public_subnets = {
            sbnt1 = {
              primary   = "10.1.2.0/27"
              secondary = "10.1.2.32/27"
            }
            sbnt2 = {
              primary   = "10.1.2.64/27"
              secondary = "10.1.2.96/27"
            }
          }
          private_subnets = {
            sbnt1 = {
              primary   = "10.1.2.128/27"
              secondary = "10.1.2.160/27"
            }
            sbnt2 = {
              primary   = "10.1.2.192/27"
              secondary = "10.1.2.224/27"
            }
          }
        }
        app_vpc = {
          development = {
            vpc = "10.1.1.0/24"
            public_subnets = {
              sbnt1 = {
                primary   = "10.1.1.0/27"
                secondary = "10.1.1.32/27"
              }
              sbnt2 = {
                primary   = "10.1.1.64/27"
                secondary = "10.1.1.96/27"
              }
            }
            private_subnets = {
              sbnt1 = {
                primary   = "10.1.1.128/27"
                secondary = "10.1.1.160/27"
              }
              sbnt2 = {
                primary   = "10.1.1.192/27"
                secondary = "10.1.1.224/27"
              }
            }
          }
          training = {
            vpc = "10.1.4.0/24"
            public_subnets = {
              sbnt1 = {
                primary   = "10.1.4.0/27"
                secondary = "10.1.4.32/27"
              }
              sbnt2 = {
                primary   = "10.1.4.64/27"
                secondary = "10.1.4.96/27"
              }
            }
            private_subnets = {
              sbnt1 = {
                primary   = "10.1.4.128/27"
                secondary = "10.1.4.160/27"
              }
              sbnt2 = {
                primary   = "10.1.4.192/27"
                secondary = "10.1.4.224/27"
              }
            }
          }
        }
      }
    }
    intpp = {
      segments = {
        Account_cidr = "10.1.0.0/16"
        shared-services = {
          vpc = "10.1.2.0/24"
          public_subnets = {
            sbnt1 = {
              primary   = "10.1.2.0/27"
              secondary = "10.1.2.32/27"
            }
            sbnt2 = {
              primary   = "10.1.2.64/27"
              secondary = "10.1.2.96/27"
            }
          }
          private_subnets = {
            sbnt1 = {
              primary   = "10.1.2.128/27"
              secondary = "10.1.2.160/27"
            }
            sbnt2 = {
              primary   = "10.1.2.192/27"
              secondary = "10.1.2.224/27"
            }
          }
        }
        app_vpc = {
          development = {
            vpc = "10.1.1.0/24"
            public_subnets = {
              sbnt1 = {
                primary   = "10.1.1.0/27"
                secondary = "10.1.1.32/27"
              }
              sbnt2 = {
                primary   = "10.1.1.64/27"
                secondary = "10.1.1.96/27"
              }
            }
            private_subnets = {
              sbnt1 = {
                primary   = "10.1.1.128/27"
                secondary = "10.1.1.160/27"
              }
              sbnt2 = {
                primary   = "10.1.1.192/27"
                secondary = "10.1.1.224/27"
              }
            }
          }
          training = {
            vpc = "10.1.4.0/24"
            public_subnets = {
              sbnt1 = {
                primary   = "10.1.4.0/27"
                secondary = "10.1.4.32/27"
              }
              sbnt2 = {
                primary   = "10.1.4.64/27"
                secondary = "10.1.4.96/27"
              }
            }
            private_subnets = {
              sbnt1 = {
                primary   = "10.1.4.128/27"
                secondary = "10.1.4.160/27"
              }
              sbnt2 = {
                primary   = "10.1.4.192/27"
                secondary = "10.1.4.224/27"
              }
            }
          }
          system-integration = {
            vpc = "10.1.5.0/24"
            public_subnets = {
              sbnt1 = {
                primary   = "10.1.5.0/27"
                secondary = "10.1.5.32/27"
              }
              sbnt2 = {
                primary   = "10.1.5.64/27"
                secondary = "10.1.5.96/27"
              }
            }
            private_subnets = {
              sbnt1 = {
                primary   = "10.1.5.128/27"
                secondary = "10.1.5.160/27"
              }
              sbnt2 = {
                primary   = "10.1.5.192/27"
                secondary = "10.1.5.224/27"
              }
            }
          }
        }
      }
    }
    ntw = {
      segments = {
        Account_cidr = "10.5.0.0/16"
        shared-services = {
          vpc = "10.5.2.0/24"
          public_subnets = {
            sbnt1 = {
              primary   = "10.5.2.0/27"
              secondary = "10.5.2.32/27"
            }
            sbnt2 = {
              primary   = "10.5.2.64/27"
              secondary = "10.5.2.96/27"
            }
          }
          private_subnets = {
            sbnt1 = {
              primary   = "10.5.2.128/27"
              secondary = "10.5.2.160/27"
            }
            sbnt2 = {
              primary   = "10.5.2.192/27"
              secondary = "10.5.2.224/27"
            }
          }
        }
        app_vpc = {
          development = {
            vpc = "10.5.1.0/24"
            public_subnets = {
              sbnt1 = {
                primary   = "10.5.1.0/27"
                secondary = "10.5.1.32/27"
              }
              sbnt2 = {
                primary   = "10.5.1.64/27"
                secondary = "10.5.1.96/27"
              }
            }
            private_subnets = {
              sbnt1 = {
                primary   = "10.5.1.128/27"
                secondary = "10.5.1.160/27"
              }
              sbnt2 = {
                primary   = "10.5.1.192/27"
                secondary = "10.5.1.224/27"
              }
            }
          }
          training = {
            vpc = "10.5.4.0/24"
            public_subnets = {
              sbnt1 = {
                primary   = "10.5.4.0/27"
                secondary = "10.5.4.32/27"
              }
              sbnt2 = {
                primary   = "10.5.4.64/27"
                secondary = "10.5.4.96/27"
              }
            }
            private_subnets = {
              sbnt1 = {
                primary   = "10.5.4.128/27"
                secondary = "10.5.4.160/27"
              }
              sbnt2 = {
                primary   = "10.5.4.192/27"
                secondary = "10.5.4.224/27"
              }
            }
          }
          system-integration = {
            vpc = "10.5.5.0/24"
            public_subnets = {
              sbnt1 = {
                primary   = "10.5.5.0/27"
                secondary = "10.5.5.32/27"
              }
              sbnt2 = {
                primary   = "10.5.5.64/27"
                secondary = "10.5.5.96/27"
              }
            }
            private_subnets = {
              sbnt1 = {
                primary   = "10.5.5.128/27"
                secondary = "10.5.5.160/27"
              }
              sbnt2 = {
                primary   = "10.5.5.192/27"
                secondary = "10.5.5.224/27"
              }
            }
          }
        }
      }
    }
  }
}
