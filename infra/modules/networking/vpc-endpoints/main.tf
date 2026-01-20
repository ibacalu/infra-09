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

# Security group for VPC Interface Endpoints
resource "aws_security_group" "vpc_endpoints" {
  name_prefix = "${var.name}-vpce-"
  description = "Security group for VPC Interface Endpoints"
  vpc_id      = var.vpc_id

  ingress {
    description = "HTTPS from VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.tags, { Name = "${var.name}-vpce-sg" })

  lifecycle {
    create_before_destroy = true
  }
}

# VPC Endpoints using the AWS VPC module
module "endpoints" {
  source  = "terraform-aws-modules/vpc/aws//modules/vpc-endpoints"
  version = "6.6.0"

  vpc_id = var.vpc_id

  endpoints = {
    # Gateway endpoint for S3 (FREE)
    s3 = {
      service         = "s3"
      service_type    = "Gateway"
      route_table_ids = var.route_table_ids
      tags            = { Name = "${var.name}-s3" }
    }

    # Interface endpoints for AWS services
    ecr_api = {
      service             = "ecr.api"
      private_dns_enabled = true
      subnet_ids          = var.subnet_ids
      security_group_ids  = [aws_security_group.vpc_endpoints.id]
      tags                = { Name = "${var.name}-ecr-api" }
    }

    ecr_dkr = {
      service             = "ecr.dkr"
      private_dns_enabled = true
      subnet_ids          = var.subnet_ids
      security_group_ids  = [aws_security_group.vpc_endpoints.id]
      tags                = { Name = "${var.name}-ecr-dkr" }
    }

    ec2 = {
      service             = "ec2"
      private_dns_enabled = true
      subnet_ids          = var.subnet_ids
      security_group_ids  = [aws_security_group.vpc_endpoints.id]
      tags                = { Name = "${var.name}-ec2" }
    }

    sts = {
      service             = "sts"
      private_dns_enabled = true
      subnet_ids          = var.subnet_ids
      security_group_ids  = [aws_security_group.vpc_endpoints.id]
      tags                = { Name = "${var.name}-sts" }
    }

    logs = {
      service             = "logs"
      private_dns_enabled = true
      subnet_ids          = var.subnet_ids
      security_group_ids  = [aws_security_group.vpc_endpoints.id]
      tags                = { Name = "${var.name}-logs" }
    }

    # SSM endpoints for Systems Manager (optional but useful for debugging)
    ssm = {
      service             = "ssm"
      private_dns_enabled = true
      subnet_ids          = var.subnet_ids
      security_group_ids  = [aws_security_group.vpc_endpoints.id]
      tags                = { Name = "${var.name}-ssm" }
    }

    ssmmessages = {
      service             = "ssmmessages"
      private_dns_enabled = true
      subnet_ids          = var.subnet_ids
      security_group_ids  = [aws_security_group.vpc_endpoints.id]
      tags                = { Name = "${var.name}-ssmmessages" }
    }

    ec2messages = {
      service             = "ec2messages"
      private_dns_enabled = true
      subnet_ids          = var.subnet_ids
      security_group_ids  = [aws_security_group.vpc_endpoints.id]
      tags                = { Name = "${var.name}-ec2messages" }
    }
  }

  tags = local.tags
}
