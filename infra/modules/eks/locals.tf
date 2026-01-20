locals {
  # Do we use InternalIngress?
  internalIngressEnabled = var.config.internal_route53_zone != null ? true : false
  externalIngressEnabled = var.config.external_route53_zone != null ? true : false

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
        local.internalIngressEnabled ? data.aws_route53_zone.internal.0.zone_id : "",
        local.externalIngressEnabled ? data.aws_route53_zone.external.0.zone_id : "",
        data.aws_route53_zone.root.zone_id,
        aws_route53_zone.cluster.zone_id
      ])
    }
  )

  # GitHub App configuration for ArgoCD
  github_app = {
    id                            = try(var.argocd.github_app.id, "")
    installation_id               = try(var.argocd.github_app.installation_id, "")
    private_key_secret_manager_id = try(var.argocd.github_app.private_key_secret_manager_id, "eks/argocd/github_app_private_key")
    organisation                  = try(var.argocd.github_app.organisation, "ibacalu")
    server_url                    = try(var.argocd.github_app.server_url, "https://github.com")
  }

  # ArgoCD config for external terraform-k8s-argocd module
  argocd_config = {
    argocd_base_url = try(var.argocd.argocd_base_url, "https://github.com/ibacalu/infra-09//gitops/services/argocd/base?ref=main")

    organisation = {
      name        = try(var.argocd.organisation.name, "platform-09")
      repo_url    = try(var.argocd.organisation.repo_url, "https://github.com/ibacalu/infra-09.git")
      repo_path   = try(var.argocd.organisation.repo_path, "gitops/org")
      branch      = try(var.argocd.organisation.branch, "main")
      environment = var.config.environment
    }

    configmaps = [
      {
        name      = "cluster-config"
        namespace = "argocd"
        data = {
          # EKS cluster info
          cluster_name     = module.eks.cluster_name
          cluster_endpoint = module.eks.cluster_endpoint
          cluster_arn      = module.eks.cluster_arn
          region           = data.aws_region.this.id
          vpc_id           = var.config.vpc_id
          environment      = var.config.environment

          # IRSA role ARNs
          karpenter_iam_role_arn           = module.irsa.karpenter_iam_role_arn
          karpenter_node_iam_role_arn      = module.irsa.karpenter_node_iam_role_arn
          external_dns_iam_role_arn        = module.irsa.external_dns_iam_role_arn
          cert_manager_iam_role_arn        = module.irsa.cert_manager_iam_role_arn
          aws_ebs_csi_driver_iam_role_arn  = module.irsa.aws_ebs_csi_driver_iam_role_arn
          aws_load_balancer_controller_arn = module.irsa.aws_load_balancer_controller_arn
          autoscaler_iam_role_arn          = module.irsa.autoscaler_iam_role_arn

          # DNS zones
          rootDNSZoneName    = data.aws_route53_zone.root.name
          rootDNSZoneId      = data.aws_route53_zone.root.zone_id
          clusterDNSZoneName = aws_route53_zone.cluster.name
          clusterDNSZoneId   = aws_route53_zone.cluster.zone_id
          clusterDNSZoneCert = aws_acm_certificate.cluster.arn

          # Other config
          letsencrypt_email   = var.config.letsencrypt_email
          cluster-issuer      = "letsencrypt-prod"
          github_organisation = local.github_app.organisation
        }
      }
    ]

    secrets = [
      {
        name      = "github-org-credentials"
        namespace = "argocd"
        labels = {
          "argocd.argoproj.io/secret-type" = "repo-creds"
          "app.kubernetes.io/name"         = "github-org-credentials"
        }
        stringData = {
          type                    = "github"
          url                     = "${local.github_app.server_url}/${local.github_app.organisation}"
          organisation            = local.github_app.organisation
          githubAppID             = local.github_app.id
          githubAppInstallationID = local.github_app.installation_id
          githubAppPrivateKey     = data.aws_secretsmanager_secret_version.github_app_private_key.secret_string
        }
      }
    ]
  }
}

