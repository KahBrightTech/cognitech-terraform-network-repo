locals {
  internet = "0.0.0.0/0"


  ###################################################################
  ### EGRESS RULES 
  ###################################################################

  egress = {
    alb_base = [
      {
        key           = "egress-443-alb-sg"
        target_sg_key = "alb"
        description   = "BASE - Outbound HTTPS traffic to ALB SG (self) on tcp port 443(HTTPS)"
        from_port     = 443
        to_port       = 443
        ip_protocol   = "tcp"
      },
      {
        key "egress-80-alb-sg"
        target_sg_key = "alb"
        description   = "BASE - Outbound HTTP traffic to ALB SG(self) on tcp port 80 (HTTP)"
        from_port     = 80
        to_port       = 80
        ip_protocol   = "tcp"
      },
      {
        key           = "egrees-443-app-sg"
        target_sg_key = "app"
        description   = "BASE - Outbound HTTPS traffic to App SG on tcp port 443 (HTTPS)"
        from_port     = 443
        to_port       = 443
        ip_protocol   = "tcp"
      }
    ]
    nlb_base = [
      {
        key           = "egress-443-nlb-sg"
        target_sg_key = "nlb"
        description   = "BASE - Outbound HTTPS traffic to NLB SG on tcp port 443 (HTTPS)"
        from_port     = 443
        to_port       = 443
        ip_protocol   = "tcp"
      },
      {
        key           = "egress-80-nlb-sg"
        target_sg_key = "nlb"
        description   = "BASE - Outbound HTTP traffic to NLB SG on tcp port 80 (HTTP)"
        from_port     = 80
        to_port       = 80
        ip_protocol   = "tcp"
      },
      {
        key           = "egress-443-app-sg"
        target_sg_key = "app"
        description   = "BASE - Outbound HTTPS traffic to App SG on tcp port 443 (HTTPS)"
        from_port     = 443
        to_port       = 443
        ip_protocol   = "tcp"
      }
    ]
    windows_bastion_base = [
      {
        key           = "egress-3389-bastion-sg"
        target_sg_key = "bastion"
        description   = "BASE - Outbound RDP traffic to Bastion SG on tcp port 3389 (RDP)"
        from_port     = 3389
        to_port       = 3389
        ip_protocol   = "tcp"
      },
      {
        key           = "egress-3389-app-sg"
        target_sg_key = "app"
        description   = "BASE - Outbound RDP traffic to App SG on tcp port 3389 (RDP)"
        from_port     = 3389
        to_port       = 3389
        ip_protocol   = "tcp"
      }
    ]
    linux_bastion_base = [
      {
        key           = "egress-22-bastion-sg"
        target_sg_key = "bastion"
        description   = "BASE - Outbound SSH traffic to Bastion SG on tcp port 22 (SSH)"
        from_port     = 22
        to_port       = 22
        ip_protocol   = "tcp"
      },
      {
        key           = "egress-22-app-sg"
        target_sg_key = "app"
        description   = "BASE - Outbound SSH traffic to App SG on tcp port 22 (SSH)"
        from_port     = 22
        to_port       = 22
        ip_protocol   = "tcp"
      }
    ]
    app_base = [
      {
        key           = "egress-all-traffic-app-sg"
        target_sg_key = "app"
        description   = "BASE - Outbound all traffic to App SG"
        ip_protocol   = "-1"
      },
      {
        key           = "egress-443-alb-sg"
        target_sg_key = "alb"
        description   = "BASE - Outbound HTTPS traffic to ALB SG on tcp port 443 (HTTPS)"
        from_port     = 443
        to_port       = 443
        ip_protocol   = "tcp"
      },
      {
        key           = "egress-80-alb-sg"
        target_sg_key = "alb"
        description   = "BASE - Outbound HTTP traffic to ALB SG on tcp port 80 (HTTP)"
        from_port     = 80
        to_port       = 80
        ip_protocol   = "tcp"
      },
      {
        key           = "egress-443-nlb-sg"
        target_sg_key = "nlb"
        description   = "BASE - Outbound HTTPS traffic to NLB SG on tcp port 443 (HTTPS)"
        from_port     = 443
        to_port       = 443
        ip_protocol   = "tcp"
      },
      {
        key           = "egress-80-nlb-sg"
        target_sg_key = "nlb"
        description   = "BASE - Outbound HTTP traffic to NLB SG on tcp port 80 (HTTP)"
        from_port     = 80
        to_port       = 80
        ip_protocol   = "tcp"
      }
    ]
  }

  ###################################################################
  ### INGRESS RULES 
  ###################################################################

  ingress = {
    alb_base = [
      {
        key         = "ingress-80-alb-sg"
        cidr_ipv4   = local.internet
        description = "BASE - Inbound HTTP traffic from Internet to ALB SG on tcp port 80 (HTTP)"
        from_port   = 80
        to_port     = 80
        ip_protocol = "tcp"
      },
      {
        key         = "ingress-443-alb-sg"
        cidr_ipv4   = local.internet
        description = "BASE - Inbound HTTPS traffic from Internet to ALB SG on tcp port 443 (HTTPS)"
        from_port   = 443
        to_port     = 443
        ip_protocol = "tcp"
      },
      {
        key           = "ingress-443-app-sg"
        source_sg_key = "app"
        description   = "BASE - Inbound HTTPS traffic from App SG to ALB SG on tcp port 443 (HTTPS)"
        from_port     = 443
        to_port       = 443
        ip_protocol   = "tcp"
      }
    ]
    nlb_base = [
      {
        key         = "ingress-80-nlb-sg"
        cidr_ipv4   = local.internet
        description = "BASE - Inbound HTTP traffic from Internet to NLB SG on tcp port 80 (HTTP)"
        from_port   = 80
        to_port     = 80
        ip_protocol = "tcp"
      },
      {
        key         = "ingress-443-nlb-sg"
        cidr_ipv4   = local.internet
        description = "BASE - Inbound HTTPS traffic from Internet to NLB SG on tcp port 443 (HTTPS)"
        from_port   = 443
        to_port     = 443
        ip_protocol = "tcp"
      },
      {
        key           = "ingress-443-app-sg"
        source_sg_key = "app"
        description   = "BASE - Inbound HTTPS traffic from App SG to NLB SG on tcp port 443 (HTTPS)"
        from_port     = 443
        to_port       = 443
        ip_protocol   = "tcp"
      },
      {
        key           = "ingress-443-nlb-sg"
        source_sg_key = "nlb"
        description   = "BASE - Inbound HTTPS traffic from NLB SG to App SG on tcp port 443 (HTTPS)"
        from_port     = 443
        to_port       = 443
        ip_protocol   = "tcp"
      }
    ]
    app_base = [
      {
        key           = "ingress-all-traffic-app-sg"
        source_sg_key = "app"
        description   = "BASE - Inbound all traffic from App SG to App SG"
        ip_protocol   = "-1"
      },
      {
        key           = "ingress-443-alb-sg"
        source_sg_key = "alb"
        description   = "BASE - Inbound HTTPS traffic from ALB SG to App SG on tcp port 443 (HTTPS)"
        from_port     = 443
        to_port       = 443
        ip_protocol   = "tcp"
      },
      {
        key           = "ingress-80-alb-sg"
        source_sg_key = "alb"
        description   = "BASE - Inbound HTTP traffic from ALB SG to App SG on tcp port 80 (HTTP)"
        from_port     = 80
        to_port       = 80
        ip_protocol   = "tcp"
      },
      {
        key           = "ingress-443-nlb-sg"
        source_sg_key = "nlb"
        description   = "BASE - Inbound HTTPS traffic from NLB SG to App SG on tcp port 443 (HTTPS)"
        from_port     = 443
        to_port       = 443
        ip_protocol   = "tcp"
      },
      {
        key           = "ingress-80-nlb-sg"
        source_sg_key = "nlb"
        description   = "BASE - Inbound HTTP traffic from NLB SG to App SG on tcp port 80 (HTTP)"
        from_port     = 80
        to_port       = 80
        ip_protocol   = "tcp"
      },
      {
        key           = "ingress-22-bastion-sg"
        source_sg_key = "bastion"
        description   = "BASE - Inbound all traffic from Bastion SG to ALB SG"
        from_port     = 22
        to_port       = 22
        ip_protocol   = "tcp"
      },
      {
        key           = "ingress-3389-bastion-sg"
        source_sg_key = "bastion"
        description   = "BASE - Inbound all traffic from Bastion SG to ALB SG"
        from_port     = 3389
        to_port       = 3389
        ip_protocol   = "tcp"
      },
    ]
    windows_bastion_base = [
      {
        key         = "ingress-3389-bastion-sg"
        cidr_ipv4   = local.internet
        description = "BASE - Inbound RDP traffic from Internet to Bastion SG on tcp port 3389 (RDP)"
        from_port   = 3389
        to_port     = 3389
        ip_protocol = "tcp"
      }
    ]
    linux_bastion_base = [
      {
        key         = "ingress-22-bastion-sg"
        cidr_ipv4   = local.internet
        description = "BASE - Inbound SSH traffic from Internet to Bastion SG on tcp port 22 (SSH)"
        from_port   = 22
        to_port     = 22
        ip_protocol = "tcp
      }
    ]
   }
}