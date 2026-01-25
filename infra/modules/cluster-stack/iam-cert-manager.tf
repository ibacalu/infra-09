
# Pod Identity IAM Role for cert-manager
# Manages Route53 DNS records for ACME DNS-01 challenges

data "aws_iam_policy_document" "cert_manager_assume" {
  statement {
    actions = ["sts:AssumeRole", "sts:TagSession"]

    principals {
      type        = "Service"
      identifiers = ["pods.eks.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }
  }
}

data "aws_iam_policy_document" "cert_manager" {
  statement {
    effect    = "Allow"
    actions   = ["route53:GetChange"]
    resources = ["arn:aws:route53:::change/*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "route53:ChangeResourceRecordSets",
      "route53:ListResourceRecordSets"
    ]
    resources = [
      "arn:aws:route53:::hostedzone/${var.root_route53_zone_id}",
      "arn:aws:route53:::hostedzone/${aws_route53_zone.cluster.zone_id}"
    ]
  }

  statement {
    effect    = "Allow"
    actions   = ["route53:ListHostedZonesByName"]
    resources = ["*"]
  }
}

resource "aws_iam_role" "cert_manager" {
  name               = "${local.name}-cert-manager"
  assume_role_policy = data.aws_iam_policy_document.cert_manager_assume.json

  tags = local.tags
}

resource "aws_iam_policy" "cert_manager" {
  name   = "${local.name}-cert-manager"
  policy = data.aws_iam_policy_document.cert_manager.json

  tags = local.tags
}

resource "aws_iam_role_policy_attachment" "cert_manager" {
  role       = aws_iam_role.cert_manager.name
  policy_arn = aws_iam_policy.cert_manager.arn
}
