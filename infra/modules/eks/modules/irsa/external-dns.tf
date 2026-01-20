data "aws_iam_policy_document" "external_dns" {
  statement {
    sid    = "AmazonEKSClusterExternalDNSChange"
    effect = "Allow"
    actions = [
      "route53:ChangeResourceRecordSets"
    ]
    resources = tolist(toset([for zone in var.config.route53_zone_ids : format("arn:aws:route53:::hostedzone/%s", zone)]))
  }

  statement {
    sid    = "AmazonEKSClusterExternalDNSList"
    effect = "Allow"
    actions = [
      "route53:ListHostedZones",
      "route53:ListResourceRecordSets"
    ]
    resources = ["*"]
  }
}

data "aws_iam_policy_document" "external_dns_assume" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [var.config.oidc_provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${trimprefix(var.config.cluster_oidc_issuer_url, "https://")}:sub"
      values   = ["system:serviceaccount:external-dns:external-dns"]
    }

    condition {
      test     = "StringEquals"
      variable = "${trimprefix(var.config.cluster_oidc_issuer_url, "https://")}:aud"
      values   = ["sts.amazonaws.com"]
    }

  }
}

resource "aws_iam_policy" "external_dns" {
  # count       = var.config.enable_external_dns ? 1 : 0
  name   = "${var.config.cluster_name}-external-dns"
  policy = data.aws_iam_policy_document.external_dns.json
}

resource "aws_iam_role" "external_dns" {
  # count              = var.config.enable_external_dns ? 1 : 0
  name               = "${var.config.cluster_name}-external-dns"
  assume_role_policy = data.aws_iam_policy_document.external_dns_assume.json

  tags = {
    "alpha.eksctl.io/cluster-name"                = var.config.cluster_name
    "eksctl.cluster.k8s.io/v1alpha1/cluster-name" = var.config.cluster_name
    "alpha.eksctl.io/iamserviceaccount-name"      = "external-dns/external-dns"
  }
}

resource "aws_iam_role_policy_attachment" "external_dns" {
  # count      = var.config.enable_external_dns ? 1 : 0
  role       = aws_iam_role.external_dns.name
  policy_arn = aws_iam_policy.external_dns.arn
}
