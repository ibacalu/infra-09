# Local values for consistent tagging
locals {
  common_tags = {
    Project     = var.project_name
    Environment = "Production"
    Service     = "Infrastructure"
    Owner       = var.owner_team
    CostCenter  = var.cost_center
    Backup      = "required"
    Compliance  = "required"
    ManagedBy   = "terraform"
  }

  # Common secrets (shared across all clusters)
  common_secrets = {
    "github-org-credentials" = {
      type                    = "github"
      url                     = "https://github.com/${var.github_organisation}"
      organisation            = var.github_organisation
      githubAppID             = var.github_app_id
      githubAppInstallationID = var.github_app_installation_id
      githubAppPrivateKey     = var.github_app_private_key
      # Labels encoded as JSON for the EKS module to decode
      _labels = jsonencode({
        "argocd.argoproj.io/secret-type" = "repo-creds"
        "app.kubernetes.io/name"         = "github-org-credentials"
      })
    }
  }

  # EKS Access Entries for SSO Roles
  # We construct this dynamically from the fetched IAM roles
  sso_access_entries = {
    # AdministratorAccess -> ClusterAdmin
    admin = {
      principal_arn = tolist(data.aws_iam_roles.sso_admin.arns)[0]
      policy_associations = {
        admin = {
          policy_arn   = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
          access_scope = { type = "cluster" }
        }
      }
    }

    # DeveloperAccess -> Admin (Namespace full access, but can't manage cluster)
    developer = {
      principal_arn = tolist(data.aws_iam_roles.sso_developer.arns)[0]
      policy_associations = {
        admin = {
          policy_arn   = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSAdminPolicy"
          access_scope = { type = "cluster" }
        }
      }
    }

    # ReadOnlyAccess -> View (Read-only access)
    readonly = {
      principal_arn = tolist(data.aws_iam_roles.sso_readonly.arns)[0]
      policy_associations = {
        view = {
          policy_arn   = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSViewPolicy"
          access_scope = { type = "cluster" }
        }
      }
    }
  }


  # Define Cluster Configs
  clusters = {
    # Define overrides here (subnet sizing, region, etc.)
    "main-01" = {}
  }

  # Enrich clusters with computed values (single source of truth)
  cluster_configs = {
    for key, cluster in local.clusters : key => merge(cluster, {
      name            = "${var.project_name}-${key}"
      project_name    = try(cluster.project_name, var.project_name)
      environment     = lower(try(cluster.environment, local.common_tags.Environment))
      region          = try(cluster.region, var.aws_region)
      secrets_prefix  = try(cluster.secrets_prefix, "eks/${var.project_name}-${key}/argocd/")
      cluster_version = try(cluster.cluster_version, "1.31")
      argocd_config = try(cluster.argocd_config, {
        repo_url    = "https://github.com/ibacalu/infra-09.git"
        repo_path   = "gitops/org"
        branch      = "main"
        environment = local.common_tags.Environment
      })
      access_entries         = try(cluster.access_entries, local.sso_access_entries)
      tags                   = try(cluster.tags, local.common_tags)
      root_route53_zone_name = try(cluster.root_route53_zone_name, aws_route53_zone.root.name)
      root_route53_zone_id   = try(cluster.root_route53_zone_id, aws_route53_zone.root.zone_id)
      letsencrypt_email      = try(cluster.letsencrypt_email, var.letsencrypt_email)
    })
  }

  # Flat map for secret resources (keys are non-sensitive strings)
  secret_resources = {
    for pair in flatten([
      for cluster_key, config in local.cluster_configs : [
        for secret_key in keys(merge(local.common_secrets, try(config.secrets, {}))) : {
          key         = "${cluster_key}/${secret_key}"
          cluster_key = cluster_key
          secret_key  = secret_key
          secret_name = "${config.secrets_prefix}${secret_key}"
        }
      ]
    ]) : pair.key => pair
  }
}
