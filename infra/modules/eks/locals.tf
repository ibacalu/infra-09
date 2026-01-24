locals {
  # Do we use InternalIngress?
  internalIngressEnabled = var.config.internal_route53_zone_id != null ? true : false
  externalIngressEnabled = var.config.external_route53_zone_id != null ? true : false

  # Helper locals - use passed values directly for plan-time resolution
  root_route53_zone_id   = var.config.root_route53_zone_id
  root_route53_zone_name = var.config.root_route53_zone_name

  # EKS managed node groups (direct passthrough)
  eks_managed_node_groups = var.eks.eks_managed_node_groups

  tags = merge(
    var.config.tags,
    {
      ManagedBy   = "Terraform"
      Environment = var.config.environment
    }
  )

  irsa = merge(
    var.irsa,
    {
      cluster_name            = module.eks.cluster_name
      oidc_provider_arn       = module.eks.oidc_provider_arn
      cluster_oidc_issuer_url = module.eks.cluster_oidc_issuer_url
      # TODO: define if we really need both root and cluster zones here
      route53_zone_ids = compact([
        local.internalIngressEnabled ? data.aws_route53_zone.internal[0].zone_id : "",
        local.externalIngressEnabled ? data.aws_route53_zone.external[0].zone_id : "",
        local.root_route53_zone_id,
        aws_route53_zone.cluster.zone_id
      ])
    }
  )

}

