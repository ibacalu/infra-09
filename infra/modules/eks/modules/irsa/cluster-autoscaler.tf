data "aws_iam_policy_document" "autoscaler" {
  statement {
    sid    = "AmazonEKSClusterAutoscalerPolicy"
    effect = "Allow"
    actions = [
      "autoscaling:DescribeAutoScalingGroups",
      "autoscaling:DescribeAutoScalingInstances",
      "autoscaling:DescribeLaunchConfigurations",
      "autoscaling:DescribeTags",
      "autoscaling:SetDesiredCapacity",
      "autoscaling:TerminateInstanceInAutoScalingGroup",
      "ec2:DescribeLaunchTemplateVersions"
    ]
    resources = ["*"]
  }
}

data "aws_iam_policy_document" "autoscaler_assume" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [var.config.oidc_provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${trimprefix(var.config.cluster_oidc_issuer_url, "https://")}:sub"
      values   = ["system:serviceaccount:kube-system:cluster-autoscaler"]
    }

    condition {
      test     = "StringEquals"
      variable = "${trimprefix(var.config.cluster_oidc_issuer_url, "https://")}:aud"
      values   = ["sts.amazonaws.com"]
    }

  }
}

resource "aws_iam_policy" "autoscaler" {
  # count       = var.config.enable_cluster_autoscaler ? 1 : 0
  name   = "${var.config.cluster_name}-autoscaler"
  policy = data.aws_iam_policy_document.autoscaler.json
}

resource "aws_iam_role" "autoscaler" {
  # count              = var.config.enable_cluster_autoscaler ? 1 : 0
  name               = "${var.config.cluster_name}-autoscaler"
  assume_role_policy = data.aws_iam_policy_document.autoscaler_assume.json

  tags = {
    "alpha.eksctl.io/cluster-name"                = var.config.cluster_name
    "eksctl.cluster.k8s.io/v1alpha1/cluster-name" = var.config.cluster_name
    "alpha.eksctl.io/iamserviceaccount-name"      = "kube-system/cluster-autoscaler"
  }
}

resource "aws_iam_role_policy_attachment" "autoscaler" {
  # count      = var.config.enable_cluster_autoscaler ? 1 : 0
  role       = aws_iam_role.autoscaler.name
  policy_arn = aws_iam_policy.autoscaler.arn
}
