# Root Route53 zone (Shared resource)
resource "aws_route53_zone" "root" {
  name    = var.root_route53_zone
  comment = "Root zone for production clusters"

  tags = merge(local.common_tags, {
    Name = var.root_route53_zone
  })
}

module "clusters" {
  source   = "../../modules/cluster-stack"
  for_each = local.cluster_configs

  providers = {
    kustomization = kustomization
  }

  # Context
  project_name       = each.value.project_name
  environment        = each.value.environment
  cluster_identifier = each.key
  region             = each.value.region

  # Configuration
  vpc_cidr        = each.value.vpc_cidr
  cluster_version = each.value.cluster_version

  # ArgoCD Config
  argocd_config = each.value.argocd_config

  # Setup user access to the cluster
  access_entries = each.value.access_entries
  tags           = each.value.tags

  # Shared Resources
  root_route53_zone_name = each.value.root_route53_zone_name
  root_route53_zone_id   = each.value.root_route53_zone_id
  letsencrypt_email      = each.value.letsencrypt_email

  # Explicit secrets (ARN + name for direct loading)
  secrets = [
    for k, v in aws_secretsmanager_secret.bootstrap_secrets : {
      arn  = v.arn
      name = split("/", v.name)[length(split("/", v.name)) - 1]
    } if startswith(k, each.key)
  ]
}
