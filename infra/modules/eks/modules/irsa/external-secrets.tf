data "aws_iam_policy_document" "external_secrets" {
  statement {
    sid    = "ExternalSecretsUKS"
    effect = "Allow"
    actions = [
      "secretsmanager:GetSecretValue",
      "secretsmanager:DescribeSecret",
      "secretsmanager:ListSecretVersionIds",
      "secretsmanager:ListSecrets", # Optional but helpful for debugging/finding secrets
    ]
    resources = ["*"] # Ideally scoped, but often difficult to predict exact ARNs in dynamic envs.
  }
}

data "aws_iam_policy_document" "external_secrets_assume" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [var.config.oidc_provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${trimprefix(var.config.cluster_oidc_issuer_url, "https://")}:sub"
      values   = ["system:serviceaccount:external-secrets:external-secrets"]
    }

    condition {
      test     = "StringEquals"
      variable = "${trimprefix(var.config.cluster_oidc_issuer_url, "https://")}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

resource "aws_iam_policy" "external_secrets" {
  count  = try(var.config.enable_external_secrets, false) ? 1 : 0
  name   = "${var.config.cluster_name}-external-secrets"
  policy = data.aws_iam_policy_document.external_secrets.json
}

resource "aws_iam_role" "external_secrets" {
  count              = try(var.config.enable_external_secrets, false) ? 1 : 0
  name               = "${var.config.cluster_name}-external-secrets"
  assume_role_policy = data.aws_iam_policy_document.external_secrets_assume.json

  tags = {
    "alpha.eksctl.io/cluster-name"                = var.config.cluster_name
    "eksctl.cluster.k8s.io/v1alpha1/cluster-name" = var.config.cluster_name
    "alpha.eksctl.io/iamserviceaccount-name"      = "external-secrets/external-secrets"
  }
}

resource "aws_iam_role_policy_attachment" "external_secrets" {
  count      = try(var.config.enable_external_secrets, false) ? 1 : 0
  role       = aws_iam_role.external_secrets[0].name
  policy_arn = aws_iam_policy.external_secrets[0].arn
}
