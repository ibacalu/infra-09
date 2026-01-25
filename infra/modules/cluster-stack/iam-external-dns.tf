
# Pod Identity IAM Role for external-dns
# Manages Route53 DNS records for Kubernetes ingress/service resources

data "aws_iam_policy_document" "external_dns_assume" {
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

data "aws_iam_policy_document" "external_dns" {
  statement {
    sid    = "ChangeRecordSets"
    effect = "Allow"
    actions = [
      "route53:ChangeResourceRecordSets"
    ]
    resources = [
      "arn:aws:route53:::hostedzone/${var.root_route53_zone_id}",
      "arn:aws:route53:::hostedzone/${aws_route53_zone.cluster.zone_id}"
    ]
  }

  statement {
    sid    = "ListRecords"
    effect = "Allow"
    actions = [
      "route53:ListHostedZones",
      "route53:ListResourceRecordSets"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role" "external_dns" {
  name               = "${local.name}-external-dns"
  assume_role_policy = data.aws_iam_policy_document.external_dns_assume.json

  tags = local.tags
}

resource "aws_iam_policy" "external_dns" {
  name   = "${local.name}-external-dns"
  policy = data.aws_iam_policy_document.external_dns.json

  tags = local.tags
}

resource "aws_iam_role_policy_attachment" "external_dns" {
  role       = aws_iam_role.external_dns.name
  policy_arn = aws_iam_policy.external_dns.arn
}
