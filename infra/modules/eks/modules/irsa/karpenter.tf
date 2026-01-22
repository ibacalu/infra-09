data "aws_partition" "current" {}
data "aws_caller_identity" "current" {}

locals {
  account_id              = data.aws_caller_identity.current.account_id
  partition               = data.aws_partition.current.partition
  dns_suffix              = data.aws_partition.current.dns_suffix
  irsa_name               = "${var.config.cluster_name}-karpenter"
  cluster_oidc_issuer_url = trimprefix(var.config.cluster_oidc_issuer_url, "https://")
  iam_role_policy_prefix  = "arn:aws:iam::aws:policy"
  cni_policy              = "${local.iam_role_policy_prefix}/AmazonEKS_CNI_Policy"

  #? Cloudwatch events
  events = {
    health_event = {
      name        = "HealthEvent"
      description = "Karpenter interrupt - AWS health event"
      event_pattern = {
        source      = ["aws.health"]
        detail-type = ["AWS Health Event"]
      }
    }
    spot_interupt = {
      name        = "SpotInterrupt"
      description = "Karpenter interrupt - EC2 spot instance interruption warning"
      event_pattern = {
        source      = ["aws.ec2"]
        detail-type = ["EC2 Spot Instance Interruption Warning"]
      }
    }
    instance_rebalance = {
      name        = "InstanceRebalance"
      description = "Karpenter interrupt - EC2 instance rebalance recommendation"
      event_pattern = {
        source      = ["aws.ec2"]
        detail-type = ["EC2 Instance Rebalance Recommendation"]
      }
    }
    instance_state_change = {
      name        = "InstanceStateChange"
      description = "Karpenter interrupt - EC2 instance state-change notification"
      event_pattern = {
        source      = ["aws.ec2"]
        detail-type = ["EC2 Instance State-change Notification"]
      }
    }
  }

  tags = {
    "ClusterName" = var.config.cluster_name
  }
}
data "aws_iam_policy_document" "karpenter_assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [var.config.oidc_provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${local.cluster_oidc_issuer_url}:sub"
      values   = ["system:serviceaccount:karpenter:karpenter"]
    }

    condition {
      test     = "StringEquals"
      variable = "${local.cluster_oidc_issuer_url}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "irsa" {
  name        = local.irsa_name
  path        = "/"
  description = "Karpenter IRSA role"

  assume_role_policy = data.aws_iam_policy_document.karpenter_assume.json
  tags               = local.tags
}

data "aws_iam_policy_document" "irsa" {
  statement {
    actions = [
      "ec2:CreateLaunchTemplate",
      "ec2:CreateFleet",
      "ec2:CreateTags",
      "ec2:DescribeLaunchTemplates",
      "ec2:DescribeImages",
      "ec2:DescribeInstances",
      "ec2:DescribeSecurityGroups",
      "ec2:DescribeSubnets",
      "ec2:DescribeInstanceTypes",
      "ec2:DescribeInstanceTypeOfferings",
      "ec2:DescribeAvailabilityZones",
      "ec2:DescribeSpotPriceHistory",
      "pricing:GetProducts",
    ]

    resources = ["*"]
  }

  statement {
    actions = [
      "ec2:TerminateInstances",
      "ec2:DeleteLaunchTemplate",
    ]

    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "ec2:ResourceTag/karpenter.sh/discovery"
      values   = [var.config.cluster_name]
    }
  }

  statement {
    actions = ["ec2:RunInstances"]
    resources = [
      "arn:aws:ec2:*:${local.account_id}:launch-template/*",
    ]

    condition {
      test     = "StringEquals"
      variable = "ec2:ResourceTag/karpenter.sh/discovery"
      values   = [var.config.cluster_name]
    }
  }

  statement {
    actions = ["ec2:RunInstances"]
    resources = [
      "arn:aws:ec2:*::image/*",
      "arn:aws:ec2:*:${local.account_id}:instance/*",
      "arn:aws:ec2:*:${local.account_id}:spot-instances-request/*",
      "arn:aws:ec2:*:${local.account_id}:security-group/*",
      "arn:aws:ec2:*:${local.account_id}:volume/*",
      "arn:aws:ec2:*:${local.account_id}:network-interface/*",
      "arn:aws:ec2:*:${local.account_id}:subnet/*",
    ]
  }

  statement {
    actions   = ["ssm:GetParameter"]
    resources = ["arn:aws:ssm:*:*:parameter/aws/service/*"]
  }

  statement {
    actions   = ["eks:DescribeCluster"]
    resources = ["arn:aws:eks:*:${local.account_id}:cluster/${var.config.cluster_name}"]
  }

  statement {
    actions   = ["iam:PassRole"]
    resources = [aws_iam_role.this.arn]
  }

  statement {
    actions = [
      "sqs:DeleteMessage",
      "sqs:GetQueueUrl",
      "sqs:GetQueueAttributes",
      "sqs:ReceiveMessage",
    ]
    resources = [aws_sqs_queue.this.arn]
  }
}

resource "aws_iam_policy" "irsa" {
  name        = local.irsa_name
  path        = "/"
  description = "Karpenter IRSA Policy"
  policy      = data.aws_iam_policy_document.irsa.json

  tags = local.tags
}

resource "aws_iam_role_policy_attachment" "irsa" {
  role       = aws_iam_role.irsa.name
  policy_arn = aws_iam_policy.irsa.arn
}

resource "aws_sqs_queue" "this" {
  name                      = local.irsa_name
  message_retention_seconds = 300
  sqs_managed_sse_enabled   = true

  tags = local.tags
}

data "aws_iam_policy_document" "queue" {
  statement {
    sid       = "SqsWrite"
    actions   = ["sqs:SendMessage"]
    resources = [aws_sqs_queue.this.arn]

    principals {
      type = "Service"
      identifiers = [
        "events.${local.dns_suffix}",
        "sqs.${local.dns_suffix}",
      ]
    }

  }
}

resource "aws_sqs_queue_policy" "this" {
  queue_url = aws_sqs_queue.this.url
  policy    = data.aws_iam_policy_document.queue.json
}

resource "aws_cloudwatch_event_rule" "this" {
  for_each = local.events

  name          = "${local.irsa_name}-${replace(each.key, "_", "-")}"
  description   = "${local.irsa_name} Karpenter rule - ${each.value.name}"
  event_pattern = jsonencode(each.value.event_pattern)

  tags = local.tags
}

resource "aws_cloudwatch_event_target" "this" {
  for_each = local.events

  rule      = aws_cloudwatch_event_rule.this[each.key].name
  target_id = "KarpenterInterruptionQueueTarget"
  arn       = aws_sqs_queue.this.arn
}

################################################################################
# Node IAM Role
# This is used by the nodes launched by Karpenter
################################################################################

data "aws_iam_policy_document" "assume_role" {
  statement {
    sid     = "EKSNodeAssumeRole"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.${local.dns_suffix}"]
    }
  }
}

resource "aws_iam_role" "this" {
  name        = "${local.irsa_name}-node"
  path        = "/"
  description = "${local.irsa_name} Nodes managed by Karpenter"

  assume_role_policy = data.aws_iam_policy_document.assume_role.json
  tags               = local.tags
}

resource "aws_iam_role_policy_attachment" "this" {
  for_each = { for k, v in toset(compact([
    "${local.iam_role_policy_prefix}/AmazonEKSWorkerNodePolicy",
    "${local.iam_role_policy_prefix}/AmazonEC2ContainerRegistryReadOnly",
    local.cni_policy,
  ])) : k => v }

  policy_arn = each.value
  role       = aws_iam_role.this.name
}

resource "aws_iam_instance_profile" "this" {
  name = "${local.irsa_name}-node-profile"
  path = "/"
  role = aws_iam_role.this.name

  tags = local.tags
}
