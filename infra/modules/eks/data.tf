data "aws_caller_identity" "this" {}

data "aws_availability_zones" "this" {
  state = "available"
}

data "aws_region" "this" {}

data "aws_vpc" "this" {
  id = var.config.vpc_id
}

data "aws_route53_zone" "internal" {
  count = local.internalIngressEnabled ? 1 : 0
  name  = var.config.internal_route53_zone
}

data "aws_acm_certificate" "internal" {
  count       = local.internalIngressEnabled ? 1 : 0
  domain      = data.aws_route53_zone.internal.0.name
  statuses    = ["ISSUED"]
  most_recent = true
}

data "aws_route53_zone" "external" {
  count = local.externalIngressEnabled ? 1 : 0
  name  = var.config.external_route53_zone
}

data "aws_acm_certificate" "external" {
  count       = local.externalIngressEnabled ? 1 : 0
  domain      = data.aws_route53_zone.external.0.name
  statuses    = ["ISSUED"]
  most_recent = true
}

data "aws_route53_zone" "root" {
  name = var.config.root_route53_zone
}

# GitHub App private key from Secrets Manager (for ArgoCD)
data "aws_secretsmanager_secret_version" "github_app_private_key" {
  secret_id = local.github_app.private_key_secret_manager_id
}

