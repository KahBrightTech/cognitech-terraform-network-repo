locals {
  cidr_blocks = {
    mdpp = {
      segments = {
        Account_cidr = "10.20.0.0/16"
        shared-services = {
          tgw_attachment = "tgw-attach-06ee7a7614bec2ced" # Update this after account creation
          vpc            = "10.20.2.0/24"
          public_subnets = {
            sbnt1 = {
              primary   = "10.20.2.0/27"
              secondary = "10.20.2.32/27"
            }
            sbnt2 = {
              primary   = "10.20.2.64/27"
              secondary = "10.20.2.96/27"
            }
          }
          private_subnets = {
            sbnt1 = {
              primary   = "10.20.2.128/27"
              secondary = "10.20.2.160/27"
            }
            sbnt2 = {
              primary   = "10.20.2.192/27"
              secondary = "10.20.2.224/27"
            }
          }
        }
        app_vpc = {
          development = {
            vpc = "10.20.1.0/24"
            public_subnets = {
              sbnt1 = {
                primary   = "10.20.1.0/27"
                secondary = "10.20.1.32/27"
              }
              sbnt2 = {
                primary   = "10.20.1.64/27"
                secondary = "10.20.1.96/27"
              }
            }
            private_subnets = {
              sbnt1 = {
                primary   = "10.20.1.128/27"
                secondary = "10.20.1.160/27"
              }
              sbnt2 = {
                primary   = "10.20.1.192/27"
                secondary = "10.20.1.224/27"
              }
            }
          }
          training = {
            vpc = "10.20.4.0/24"
            public_subnets = {
              sbnt1 = {
                primary   = "10.20.4.0/27"
                secondary = "10.20.4.32/27"
              }
              sbnt2 = {
                primary   = "10.20.4.64/27"
                secondary = "10.20.4.96/27"
              }
            }
            private_subnets = {
              sbnt1 = {
                primary   = "10.20.4.128/27"
                secondary = "10.20.4.160/27"
              }
              sbnt2 = {
                primary   = "10.20.4.192/27"
                secondary = "10.20.4.224/27"
              }
            }
          }
        }
      }
    }
    mdp = {
      segments = {
        Account_cidr = "10.30.0.0/16"
        shared-services = {
          tgw_attachment = "tgw-attach-0bea4ec77d6fc4424" # Update this after account creation
          vpc            = "10.30.2.0/24"
          public_subnets = {
            sbnt1 = {
              primary   = "10.30.2.0/27"
              secondary = "10.30.2.32/27"
            }
            sbnt2 = {
              primary   = "10.30.2.64/27"
              secondary = "10.30.2.96/27"
            }
          }
          private_subnets = {
            sbnt1 = {
              primary   = "10.30.2.128/27"
              secondary = "10.30.2.160/27"
            }
            sbnt2 = {
              primary   = "10.30.2.192/27"
              secondary = "10.30.2.224/27"
            }
          }
        }
        app_vpc = {
          development = {
            vpc = "10.30.1.0/24"
            public_subnets = {
              sbnt1 = {
                primary   = "10.30.1.0/27"
                secondary = "10.30.1.32/27"
              }
              sbnt2 = {
                primary   = "10.30.1.64/27"
                secondary = "10.30.1.96/27"
              }
            }
            private_subnets = {
              sbnt1 = {
                primary   = "10.30.1.128/27"
                secondary = "10.30.1.160/27"
              }
              sbnt2 = {
                primary   = "10.30.1.192/27"
                secondary = "10.30.1.224/27"
              }
            }
          }
          training = {
            vpc = "10.30.4.0/24"
            public_subnets = {
              sbnt1 = {
                primary   = "10.30.4.0/27"
                secondary = "10.30.4.32/27"
              }
              sbnt2 = {
                primary   = "10.30.4.64/27"
                secondary = "10.30.4.96/27"
              }
            }
            private_subnets = {
              sbnt1 = {
                primary   = "10.30.4.128/27"
                secondary = "10.30.4.160/27"
              }
              sbnt2 = {
                primary   = "10.30.4.192/27"
                secondary = "10.30.4.224/27"
              }
            }
          }
          system-int-testing = {
            vpc = "10.30.5.0/24"
            public_subnets = {
              sbnt1 = {
                primary   = "10.30.5.0/27"
                secondary = "10.30.5.32/27"
              }
              sbnt2 = {
                primary   = "10.30.5.64/27"
                secondary = "10.30.5.96/27"
              }
            }
            private_subnets = {
              sbnt1 = {
                primary   = "10.30.5.128/27"
                secondary = "10.30.5.160/27"
              }
              sbnt2 = {
                primary   = "10.30.5.192/27"
                secondary = "10.30.5.224/27"
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
    intp = {
      segments = {
        Account_cidr = "10.40.0.0/16"
        shared-services = {
          vpc = "10.40.2.0/24"
          public_subnets = {
            sbnt1 = {
              primary   = "10.40.2.0/27"
              secondary = "10.40.2.32/27"
            }
            sbnt2 = {
              primary   = "10.40.2.64/27"
              secondary = "10.40.2.96/27"
            }
          }
          private_subnets = {
            sbnt1 = {
              primary   = "10.40.2.128/27"
              secondary = "10.40.2.160/27"
            }
            sbnt2 = {
              primary   = "10.40.2.192/27"
              secondary = "10.40.2.224/27"
            }
          }
        }
        app_vpc = {
          user_acceptance_test = {
            vpc = "10.40.64.0/19"
            public_subnets = {
              sbnt1 = {
                primary   = "10.40.64.0/22"
                secondary = "10.40.68.0/22"
              }
              sbnt2 = {
                primary   = "10.40.72.0/22"
                secondary = "10.40.76.0/22"
              }
            }
            private_subnets = {
              sbnt1 = {
                primary   = "10.40.80.0/22"
                secondary = "10.40.84.0/22"
              }
              sbnt2 = {
                primary   = "10.40.88.0/22"
                secondary = "10.40.92.0/22"
              }
            }
          }
          production = {
            vpc = "10.40.32.0/19"
            public_subnets = {
              sbnt1 = {
                primary   = "10.40.32.0/22"
                secondary = "10.40.36.0/22"
              }
              sbnt2 = {
                primary   = "10.40.40.0/22"
                secondary = "10.40.44.0/22"
              }
            }
            private_subnets = {
              sbnt1 = {
                primary   = "10.40.48.0/22"
                secondary = "10.40.52.0/22"
              }
              sbnt2 = {
                primary   = "10.40.56.0/22"
                secondary = "10.40.60.0/22"
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
          system-int = {
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
