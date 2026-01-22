# Cluster DNS Zone (Delegated)
resource "aws_route53_zone" "cluster" {
  name = "${var.cluster_identifier}.${var.root_route53_zone_name}"

  tags = local.tags
}

resource "aws_route53_record" "cluster_ns" {
  zone_id = var.root_route53_zone_id
  name    = aws_route53_zone.cluster.name
  type    = "NS"
  ttl     = "30"
  records = aws_route53_zone.cluster.name_servers
}

# ACM Certificate for Cluster
resource "aws_acm_certificate" "cluster" {
  domain_name       = "*.${aws_route53_zone.cluster.name}"
  validation_method = "DNS"
  tags              = local.tags

  lifecycle {
    create_before_destroy = true
  }
}
