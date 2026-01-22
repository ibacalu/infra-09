################################################################################
# Bootstrap Secrets (AWS Secrets Manager)
#
# These secrets are created per-cluster and read by the Bootstrap Lambda.
# We use a flattened map for keys and reference values separately to avoid
# the sensitive for_each limitation.
################################################################################

resource "aws_secretsmanager_secret" "bootstrap_secrets" {
  for_each = local.secret_resources

  name        = each.value.secret_name
  description = "Bootstrap secret for ${local.cluster_configs[each.value.cluster_key].name} cluster"

  tags = merge(local.common_tags, {
    ManagedBy   = "terraform" # Required for Lambda IAM policy
    Application = "ArgoCD"
    Cluster     = local.cluster_configs[each.value.cluster_key].name
  })
}

resource "aws_secretsmanager_secret_version" "bootstrap_secrets" {
  for_each = local.secret_resources

  secret_id = aws_secretsmanager_secret.bootstrap_secrets[each.key].id
  # Look up value: check cluster-specific first, fallback to common
  secret_string = jsonencode(
    try(
      local.cluster_configs[each.value.cluster_key].secrets[each.value.secret_key],
      local.common_secrets[each.value.secret_key]
    )
  )
}
