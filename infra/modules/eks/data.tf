data "aws_caller_identity" "this" {}

data "aws_availability_zones" "this" {
  state = "available"
}

data "aws_region" "this" {}

data "aws_vpc" "this" {
  id = var.config.vpc_id
}

data "aws_route53_zone" "internal" {
  count   = local.internalIngressEnabled ? 1 : 0
  zone_id = var.config.internal_route53_zone_id
}

data "aws_acm_certificate" "internal" {
  count       = local.internalIngressEnabled ? 1 : 0
  domain      = data.aws_route53_zone.internal[0].name
  statuses    = ["ISSUED"]
  most_recent = true
}

data "aws_route53_zone" "external" {
  count   = local.externalIngressEnabled ? 1 : 0
  zone_id = var.config.external_route53_zone_id
}

data "aws_acm_certificate" "external" {
  count       = local.externalIngressEnabled ? 1 : 0
  domain      = data.aws_route53_zone.external[0].name
  statuses    = ["ISSUED"]
  most_recent = true
}
