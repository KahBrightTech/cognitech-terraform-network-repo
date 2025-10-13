locals {
  cidr_blocks = {
    mdpp = {
      segments = {
        Account_cidr = "10.2.0.0/16"
        shared-services = {
          vpc = "10.2.2.0/24"
          public_subnets = {
            sbnt1 = {
              primary   = "10.2.2.0/27"
              secondary = "10.2.2.32/27"
            }
            sbnt2 = {
              primary   = "10.2.2.64/27"
              secondary = "10.2.2.96/27"
            }
          }
          private_subnets = {
            sbnt1 = {
              primary   = "10.2.2.128/27"
              secondary = "10.2.2.160/27"
            }
            sbnt2 = {
              primary   = "10.2.2.192/27"
              secondary = "10.2.2.224/27"
            }
          }
        }
        app_vpc = {
          development = {
            vpc = "10.2.1.0/24"
            public_subnets = {
              sbnt1 = {
                primary   = "10.2.1.0/27"
                secondary = "10.2.1.32/27"
              }
              sbnt2 = {
                primary   = "10.2.1.64/27"
                secondary = "10.2.1.96/27"
              }
            }
            private_subnets = {
              sbnt1 = {
                primary   = "10.2.1.128/27"
                secondary = "10.2.1.160/27"
              }
              sbnt2 = {
                primary   = "10.2.1.192/27"
                secondary = "10.2.1.224/27"
              }
            }
          }
          training = {
            vpc = "10.2.4.0/24"
            public_subnets = {
              sbnt1 = {
                primary   = "10.2.4.0/27"
                secondary = "10.2.4.32/27"
              }
              sbnt2 = {
                primary   = "10.2.4.64/27"
                secondary = "10.2.4.96/27"
              }
            }
            private_subnets = {
              sbnt1 = {
                primary   = "10.2.4.128/27"
                secondary = "10.2.4.160/27"
              }
              sbnt2 = {
                primary   = "10.2.4.192/27"
                secondary = "10.2.4.224/27"
              }
            }
          }
        }
      }
    }
    intpp = {
      segments = {
        Account_cidr = "10.2.0.0/16"
        shared-services = {
          vpc = "10.2.2.0/24"
          public_subnets = {
            sbnt1 = {
              primary   = "10.2.2.0/27"
              secondary = "10.2.2.32/27"
            }
            sbnt2 = {
              primary   = "10.2.2.64/27"
              secondary = "10.2.2.96/27"
            }
          }
          private_subnets = {
            sbnt1 = {
              primary   = "10.2.2.128/27"
              secondary = "10.2.2.160/27"
            }
            sbnt2 = {
              primary   = "10.2.2.192/27"
              secondary = "10.2.2.224/27"
            }
          }
        }
        app_vpc = {
          development = {
            vpc = "10.2.1.0/24"
            public_subnets = {
              sbnt1 = {
                primary   = "10.2.1.0/27"
                secondary = "10.2.1.32/27"
              }
              sbnt2 = {
                primary   = "10.2.1.64/27"
                secondary = "10.2.1.96/27"
              }
            }
            private_subnets = {
              sbnt1 = {
                primary   = "10.2.1.128/27"
                secondary = "10.2.1.160/27"
              }
              sbnt2 = {
                primary   = "10.2.1.192/27"
                secondary = "10.2.1.224/27"
              }
            }
          }
          training = {
            vpc = "10.2.4.0/24"
            public_subnets = {
              sbnt1 = {
                primary   = "10.2.4.0/27"
                secondary = "10.2.4.32/27"
              }
              sbnt2 = {
                primary   = "10.2.4.64/27"
                secondary = "10.2.4.96/27"
              }
            }
            private_subnets = {
              sbnt1 = {
                primary   = "10.2.4.128/27"
                secondary = "10.2.4.160/27"
              }
              sbnt2 = {
                primary   = "10.2.4.192/27"
                secondary = "10.2.4.224/27"
              }
            }
          }
          system-integration = {
            vpc = "10.2.5.0/24"
            public_subnets = {
              sbnt1 = {
                primary   = "10.2.5.0/27"
                secondary = "10.2.5.32/27"
              }
              sbnt2 = {
                primary   = "10.2.5.64/27"
                secondary = "10.2.5.96/27"
              }
            }
            private_subnets = {
              sbnt1 = {
                primary   = "10.2.5.128/27"
                secondary = "10.2.5.160/27"
              }
              sbnt2 = {
                primary   = "10.2.5.192/27"
                secondary = "10.2.5.224/27"
              }
            }
          }
        }
      }
    }
    ntw = {
      segments = {
        Account_cidr = "10.6.0.0/16"
        shared-services = {
          vpc = "10.6.2.0/24"
          public_subnets = {
            sbnt1 = {
              primary   = "10.6.2.0/27"
              secondary = "10.6.2.32/27"
            }
            sbnt2 = {
              primary   = "10.6.2.64/27"
              secondary = "10.6.2.96/27"
            }
          }
          private_subnets = {
            sbnt1 = {
              primary   = "10.6.2.128/27"
              secondary = "10.6.2.160/27"
            }
            sbnt2 = {
              primary   = "10.6.2.192/27"
              secondary = "10.6.2.224/27"
            }
          }
        }
        app_vpc = {
          development = {
            vpc = "10.6.1.0/24"
            public_subnets = {
              sbnt1 = {
                primary   = "10.6.1.0/27"
                secondary = "10.6.1.32/27"
              }
              sbnt2 = {
                primary   = "10.6.1.64/27"
                secondary = "10.6.1.96/27"
              }
            }
            private_subnets = {
              sbnt1 = {
                primary   = "10.6.1.128/27"
                secondary = "10.6.1.160/27"
              }
              sbnt2 = {
                primary   = "10.6.1.192/27"
                secondary = "10.6.1.224/27"
              }
            }
          }
          training = {
            vpc = "10.6.4.0/24"
            public_subnets = {
              sbnt1 = {
                primary   = "10.6.4.0/27"
                secondary = "10.6.4.32/27"
              }
              sbnt2 = {
                primary   = "10.6.4.64/27"
                secondary = "10.6.4.96/27"
              }
            }
            private_subnets = {
              sbnt1 = {
                primary   = "10.6.4.128/27"
                secondary = "10.6.4.160/27"
              }
              sbnt2 = {
                primary   = "10.6.4.192/27"
                secondary = "10.6.4.224/27"
              }
            }
          }
          system-integration = {
            vpc = "10.6.5.0/24"
            public_subnets = {
              sbnt1 = {
                primary   = "10.6.5.0/27"
                secondary = "10.6.5.32/27"
              }
              sbnt2 = {
                primary   = "10.6.5.64/27"
                secondary = "10.6.5.96/27"
              }
            }
            private_subnets = {
              sbnt1 = {
                primary   = "10.6.5.128/27"
                secondary = "10.6.5.160/27"
              }
              sbnt2 = {
                primary   = "10.6.5.192/27"
                secondary = "10.6.5.224/27"
              }
            }
          }
        }
      }
    }
  }
}
