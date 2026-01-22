data "aws_caller_identity" "current" {}
data "aws_partition" "current" {}
data "aws_region" "current" {}

data "aws_route53_zone" "root" {
  zone_id = var.root_route53_zone_id
}

data "kustomization_overlay" "argocd" {
  resources = [var.argocd_base_url]
}
