# Provider configuration for production account
# Authentication: Local uses SSO profile, TFC uses OIDC via TFC_AWS_RUN_ROLE_ARN
provider "aws" {
  region = var.aws_region

  # Cross-account role assumption for production account
  # TFC authenticates to management (520687296415) via OIDC, then assumes this role
  # Using OrganizationAccountAccessRole which was automatically created by AWS Organizations
  # Local development uses AWS_PROFILE=hydrosat-prod which already targets the correct account
  assume_role {
    role_arn = "arn:aws:iam::${data.terraform_remote_state.management.outputs.production_account_id}:role/OrganizationAccountAccessRole"
  }

  default_tags {
    tags = local.common_tags
  }
}

# Kustomization provider for build-time manifest rendering
# Note: We only use kustomization_overlay data source for rendering manifests
# at plan time. The actual apply is done by the Lambda (not this provider).
# We use kubeconfig_raw with a minimal valid config to satisfy the provider,
# but it's never used for actual cluster communication.
provider "kustomization" {
  kubeconfig_raw = yamlencode({
    apiVersion = "v1"
    kind       = "Config"
    clusters = [{
      name = "unused"
      cluster = {
        server = "https://unused"
      }
    }]
    contexts = [{
      name = "unused"
      context = {
        cluster = "unused"
        user    = "unused"
      }
    }]
    current-context = "unused"
    users = [{
      name = "unused"
      user = {}
    }]
  })
}
