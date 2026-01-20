data "aws_iam_policy_document" "cert_manager" {
  statement {
    effect = "Allow"
    actions = [
      "route53:GetChange"
    ]
    resources = ["arn:aws:route53:::change/*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "route53:ChangeResourceRecordSets",
      "route53:ListResourceRecordSets"
    ]
    resources = tolist(toset([for zone in var.config.route53_zone_ids : format("arn:aws:route53:::hostedzone/%s", zone)]))
  }

  statement {
    effect = "Allow"
    actions = [
      "route53:ListHostedZonesByName"
    ]
    resources = ["*"]
  }
}

data "aws_iam_policy_document" "cert_manager_assume" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [var.config.oidc_provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${trimprefix(var.config.cluster_oidc_issuer_url, "https://")}:sub"
      values   = ["system:serviceaccount:cert-manager:cert-manager"]
    }

    condition {
      test     = "StringEquals"
      variable = "${trimprefix(var.config.cluster_oidc_issuer_url, "https://")}:aud"
      values   = ["sts.amazonaws.com"]
    }

  }
}

resource "aws_iam_policy" "cert_manager" {
  # count       = var.config.enable_cert_manager ? 1 : 0
  name   = "${var.config.cluster_name}-cert-manager"
  policy = data.aws_iam_policy_document.cert_manager.json
}

resource "aws_iam_role" "cert_manager" {
  # count              = var.config.enable_cert_manager ? 1 : 0
  name               = "${var.config.cluster_name}-cert-manager"
  assume_role_policy = data.aws_iam_policy_document.cert_manager_assume.json

  tags = {
    "alpha.eksctl.io/cluster-name"                = var.config.cluster_name
    "eksctl.cluster.k8s.io/v1alpha1/cluster-name" = var.config.cluster_name
    "alpha.eksctl.io/iamserviceaccount-name"      = "cert-manager/cert-manager"
  }
}

resource "aws_iam_role_policy_attachment" "cert_manager" {
  # count      = var.config.enable_cert_manager ? 1 : 0
  role       = aws_iam_role.cert_manager.name
  policy_arn = aws_iam_policy.cert_manager.arn
}
