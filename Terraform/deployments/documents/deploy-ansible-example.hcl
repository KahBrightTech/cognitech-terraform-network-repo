#-------------------------------------------------------
# Example: deploy_ansible input using key-based lookups
# 
# This shows how to reference security groups and subnets
# by their keys (defined in vpcs[].security_groups) instead
# of hardcoded IDs.
#
# Place this block inside your terragrunt.hcl inputs = { ... }
#-------------------------------------------------------

deploy_ansible = {
  deploy_awx          = true
  attach_to_elb       = true
  vpc_name            = local.vpc_name_abr # e.g. "dev" — used for SG/subnet lookups in launch_template and asg
  use_private_subnets = false              # top-level default for asg subnet resolution

  launch_template = {
    name = "awx-launch-template"
    ami_config = {
      os_release_date  = "2025-01-01"
      os_base_packages = "ubuntu-22.04"
    }
    instance_type               = "t3.medium"
    key_name                    = "my-key-pair"
    associate_public_ip_address = true
    volume_size                 = 30
    root_device_name            = "/dev/xvda"

    # Reference security groups by their key instead of hardcoded IDs
    # These keys must match the "key" field in vpcs[].security_groups
    vpc_security_group_keys = ["app", "alb"]
    # vpc_security_group_ids = ["sg-0123456789abcdef0"]  # use this instead if you have raw IDs

    user_data = "docker.sh"
    tags = {
      Role = "awx"
    }
  }

  alb = {
    name     = "awx-alb"
    internal = false
    type     = "application"
    vpc_name = local.vpc_name_abr # e.g. "dev" — used for SG/subnet lookups in the ALB

    # Reference security groups by their key
    security_group_keys = ["alb"]
    # security_groups = ["sg-0123456789abcdef0"]  # use this instead if you have raw IDs

    # Reference subnets by their key (e.g. "sbnt1", "sbnt2")
    # These keys must match the "key" field in vpcs[].public_subnets or vpcs[].private_subnets
    use_private_subnets = false
    subnet_keys         = [include.env.locals.subnet_prefix.primary, include.env.locals.subnet_prefix.secondary]
    # subnets = ["subnet-abc123", "subnet-def456"]  # use this instead if you have raw IDs

    enable_deletion_protection = false
    enable_access_logs         = false
    create_default_listener    = true
    default_listener = {
      port        = 443
      protocol    = "HTTPS"
      action_type = "fixed-response"
      ssl_policy  = "ELBSecurityPolicy-2016-08"
      fixed_response = {
        content_type = "text/plain"
        message_body = "Oops! The page you are looking for does not exist."
        status_code  = "200"
      }
    }
  }

  target_group = {
    name        = "awx-tg"
    port        = 80
    protocol    = "HTTP"
    target_type = "instance"
    vpc_id      = "vpc-xxxxxxxx" # or reference from dependency output
    health_check = {
      protocol = "HTTP"
      port     = 80
      path     = "/"
      matcher  = "200"
    }
  }

  alb_listener = {
    action   = "forward"
    port     = 443
    protocol = "HTTPS"
    vpc_id   = "vpc-xxxxxxxx" # or reference from dependency output
    target_group = {
      name     = "awx-tg"
      port     = 80
      protocol = "HTTP"
      health_check = {
        protocol = "HTTP"
        port     = 80
        path     = "/"
        matcher  = "200"
      }
    }
  }

  asg = {
    name                      = "awx-asg"
    min_size                  = 1
    max_size                  = 3
    desired_capacity          = 2
    health_check_type         = "EC2"
    health_check_grace_period = 300
    force_delete              = false

    # Reference subnets by their key
    # These keys must match the "key" field in vpcs[].public_subnets or vpcs[].private_subnets
    use_private_subnets = false
    subnet_keys         = [include.env.locals.subnet_prefix.primary, include.env.locals.subnet_prefix.secondary]
    # subnet_ids = ["subnet-abc123", "subnet-def456"]  # use this instead if you have raw IDs

    tags = {
      Name = "awx-asg"
    }
  }
}
