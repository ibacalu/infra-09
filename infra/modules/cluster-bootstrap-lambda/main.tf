################################################################################
# Lambda Bootstrap Module
# 
# This module creates a Lambda function that can bootstrap EKS clusters.
# It uses IAM authentication and Secrets Manager for sensitive data.
#
# IMPORTANT: Before applying, you must build the Lambda package:
#   cd modules/cluster-bootstrap-lambda && ./build.sh
################################################################################

locals {
  function_name = "${var.name_prefix}-eks-bootstrap"
}

data "archive_file" "lambda" {
  type        = "zip"
  source_dir  = "${path.module}/package"
  output_path = "${path.module}/.build/bootstrap.zip"
}


resource "aws_lambda_function" "bootstrap" {
  function_name = local.function_name
  description   = "Bootstrap EKS clusters with ArgoCD and initial configuration"

  filename         = data.archive_file.lambda.output_path
  source_code_hash = data.archive_file.lambda.output_base64sha256

  handler     = "handler.handler"
  runtime     = "python3.12"
  timeout     = 600 # 10 minutes
  memory_size = 512

  role = aws_iam_role.lambda.arn

  # VPC configuration for private EKS access
  vpc_config {
    subnet_ids         = var.subnet_ids
    security_group_ids = [aws_security_group.lambda.id]
  }

  # Environment
  environment {
    variables = {
      LOG_LEVEL = "INFO"
    }
  }

  tags = var.tags
}

################################################################################
# IAM Role for Lambda
################################################################################

data "aws_iam_policy_document" "lambda_assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "lambda" {
  name               = "${local.function_name}-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume.json
  tags               = var.tags
}

# Basic Lambda execution (CloudWatch Logs)
resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# VPC access for Lambda
resource "aws_iam_role_policy_attachment" "lambda_vpc" {
  role       = aws_iam_role.lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

# EKS and Secrets Manager access
data "aws_iam_policy_document" "lambda_eks" {
  # Describe EKS clusters
  statement {
    effect    = "Allow"
    actions   = ["eks:DescribeCluster"]
    resources = ["*"]
  }

  # List secrets from Secrets Manager (no condition - ListSecrets doesn't support resource-level permissions)
  statement {
    effect    = "Allow"
    actions   = ["secretsmanager:ListSecrets"]
    resources = ["*"]
  }

  # Read secret values (scoped by tag)
  statement {
    effect    = "Allow"
    actions   = ["secretsmanager:GetSecretValue"]
    resources = ["*"]
    condition {
      test     = "StringLike"
      variable = "secretsmanager:ResourceTag/ManagedBy"
      values   = ["terraform"]
    }
  }

  # STS for EKS authentication
  statement {
    effect    = "Allow"
    actions   = ["sts:GetCallerIdentity"]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "lambda_eks" {
  name   = "eks-access"
  role   = aws_iam_role.lambda.id
  policy = data.aws_iam_policy_document.lambda_eks.json
}

resource "aws_security_group" "lambda" {
  name        = "${local.function_name}-sg"
  description = "Security group for EKS bootstrap Lambda"
  vpc_id      = var.vpc_id

  # Egress to EKS API (HTTPS)
  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTPS to EKS API and AWS services"
  }

  tags = var.tags
}

resource "aws_cloudwatch_log_group" "lambda" {
  name              = "/aws/lambda/${local.function_name}"
  retention_in_days = 14
  tags              = var.tags
}
