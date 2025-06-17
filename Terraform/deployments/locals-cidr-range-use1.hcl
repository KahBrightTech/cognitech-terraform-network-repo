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
          dev = {
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
          trn = {
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
    mdp = {
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
          dev = {
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
          trn = {
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
    vapp = {
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
          dev = {
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
          trn = {
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
    vap = {
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
          dev = {
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
          trn = {
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
          dev = {
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
          trn = {
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
  }
}
