data "aws_region" "current" {}

locals {
  tags = merge(
    {
      ManagedBy = "Terraform"
      Module    = "vpc-endpoints"
    },
    var.tags
  )
}

# VPC Endpoints - uses module's built-in `create` attribute for conditional creation
module "endpoints" {
  source  = "terraform-aws-modules/vpc/aws//modules/vpc-endpoints"
  version = "6.6.0"

  vpc_id     = var.vpc_id
  subnet_ids = var.subnet_ids

  create_security_group      = true
  security_group_name_prefix = "${var.name}-vpc-endpoints-"
  security_group_description = "VPC endpoint security group"
  security_group_rules = {
    ingress_https = {
      description = "HTTPS from VPC"
      cidr_blocks = [var.vpc_cidr]
    }
  }

  endpoints = {
    # Gateway Endpoints
    s3 = {
      service         = "s3"
      service_type    = "Gateway"
      route_table_ids = var.route_table_ids
      tags            = { Name = "${var.name}-s3" }
      create          = var.enabled_endpoints.s3
    }
    dynamodb = {
      service         = "dynamodb"
      service_type    = "Gateway"
      route_table_ids = var.route_table_ids
      tags            = { Name = "${var.name}-dynamodb" }
      create          = var.enabled_endpoints.dynamodb
    }

    # Interface Endpoints
    ecr_api = {
      service             = "ecr.api"
      private_dns_enabled = true
      tags                = { Name = "${var.name}-ecr-api" }
      create              = var.enabled_endpoints.ecr_api
    }
    ecr_dkr = {
      service             = "ecr.dkr"
      private_dns_enabled = true
      tags                = { Name = "${var.name}-ecr-dkr" }
      create              = var.enabled_endpoints.ecr_dkr
    }
    ec2 = {
      service             = "ec2"
      private_dns_enabled = true
      tags                = { Name = "${var.name}-ec2" }
      create              = var.enabled_endpoints.ec2
    }
    sts = {
      service             = "sts"
      private_dns_enabled = true
      tags                = { Name = "${var.name}-sts" }
      create              = var.enabled_endpoints.sts
    }
    logs = {
      service             = "logs"
      private_dns_enabled = true
      tags                = { Name = "${var.name}-logs" }
      create              = var.enabled_endpoints.logs
    }
    ssm = {
      service             = "ssm"
      private_dns_enabled = true
      tags                = { Name = "${var.name}-ssm" }
      create              = var.enabled_endpoints.ssm
    }
    ssmmessages = {
      service             = "ssmmessages"
      private_dns_enabled = true
      tags                = { Name = "${var.name}-ssmmessages" }
      create              = var.enabled_endpoints.ssmmessages
    }
    ec2messages = {
      service             = "ec2messages"
      private_dns_enabled = true
      tags                = { Name = "${var.name}-ec2messages" }
      create              = var.enabled_endpoints.ec2messages
    }
  }

  tags = local.tags
}
