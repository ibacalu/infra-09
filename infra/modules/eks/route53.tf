locals {
  sanitized_cluster_name = replace(lower(var.eks.cluster_name), "_", "-")
  route53_cluster_domain = "${local.sanitized_cluster_name}.${local.root_route53_zone_name}"
}

resource "aws_route53_zone" "cluster" {
  name          = local.route53_cluster_domain
  force_destroy = true
  tags = merge(
    var.config.tags,
    {
      name        = "${var.eks.cluster_name} EKS Cluster Zone"
      environment = var.config.environment
    }
  )
}

resource "aws_route53_record" "delegation" {
  zone_id = local.root_route53_zone_id
  name    = local.route53_cluster_domain
  type    = "NS"
  ttl     = 300
  records = aws_route53_zone.cluster.name_servers
}

resource "aws_acm_certificate" "cluster" {
  domain_name       = local.route53_cluster_domain
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags = merge(
    var.config.tags,
    {
      name        = "${var.eks.cluster_name} EKS Cluster Zone Certificate"
      environment = var.config.environment
    }
  )
}

resource "aws_route53_record" "cluster" {
  for_each = {
    for dvo in aws_acm_certificate.cluster.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = aws_route53_zone.cluster.zone_id
}

resource "aws_acm_certificate_validation" "cluster" {
  certificate_arn         = aws_acm_certificate.cluster.arn
  validation_record_fqdns = [for record in aws_route53_record.cluster : record.fqdn]
}
