# Account Baseline Module
# Provides basic security and compliance configurations for all AWS accounts

# Data source to get current account information
data "aws_caller_identity" "current" {}

# Cross-account role for Terraform operations
resource "aws_iam_role" "terraform_execution_role" {
  name = "${var.project_name}-terraform-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          AWS = var.management_account_id != null ? "arn:aws:iam::${var.management_account_id}:root" : "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Condition = {
          StringEquals = {
            "sts:ExternalId" = var.project_name
          }
        }
      }
    ]
  })

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-terraform-execution-role"
    Role = "CrossAccountAccess"
  })
}

# Attach policy to Terraform execution role
resource "aws_iam_role_policy_attachment" "terraform_execution_policy" {
  role       = aws_iam_role.terraform_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

# CloudTrail for audit logging (if enabled)
resource "aws_cloudtrail" "account_trail" {
  count = var.enable_cloudtrail ? 1 : 0

  name           = "${var.project_name}-${var.account_name}-trail"
  s3_bucket_name = aws_s3_bucket.cloudtrail_bucket[0].id

  include_global_service_events = true
  is_multi_region_trail         = true
  enable_logging                = true

  event_selector {
    read_write_type           = "All"
    include_management_events = true

    data_resource {
      type   = "AWS::S3::Object"
      values = ["arn:aws:s3:::*/*"]
    }
  }

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-${var.account_name}-trail"
  })
}

# S3 bucket for CloudTrail logs
resource "aws_s3_bucket" "cloudtrail_bucket" {
  count = var.enable_cloudtrail ? 1 : 0

  bucket        = "${var.project_name}-${var.account_name}-cloudtrail-${random_id.bucket_suffix[0].hex}"
  force_destroy = true

  tags = merge(var.common_tags, {
    Name    = "${var.project_name}-${var.account_name}-cloudtrail"
    Purpose = "AuditLogs"
  })
}

# Random suffix for unique bucket naming
resource "random_id" "bucket_suffix" {
  count = var.enable_cloudtrail ? 1 : 0

  byte_length = 4
}

# S3 bucket public access block
resource "aws_s3_bucket_public_access_block" "cloudtrail_bucket" {
  count = var.enable_cloudtrail ? 1 : 0

  bucket = aws_s3_bucket.cloudtrail_bucket[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# S3 bucket server-side encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "cloudtrail_bucket" {
  count = var.enable_cloudtrail ? 1 : 0

  bucket = aws_s3_bucket.cloudtrail_bucket[0].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# CloudTrail bucket policy
resource "aws_s3_bucket_policy" "cloudtrail_bucket_policy" {
  count = var.enable_cloudtrail ? 1 : 0

  bucket = aws_s3_bucket.cloudtrail_bucket[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AWSCloudTrailAclCheck"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action   = "s3:GetBucketAcl"
        Resource = aws_s3_bucket.cloudtrail_bucket[0].arn
      },
      {
        Sid    = "AWSCloudTrailWrite"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.cloudtrail_bucket[0].arn}/*"
        Condition = {
          StringEquals = {
            "s3:x-amz-acl" = "bucket-owner-full-control"
          }
        }
      }
    ]
  })
}

# S3 bucket lifecycle configuration for cost optimization
resource "aws_s3_bucket_lifecycle_configuration" "cloudtrail_bucket" {
  count = var.enable_cloudtrail ? 1 : 0

  bucket = aws_s3_bucket.cloudtrail_bucket[0].id

  rule {
    id     = "abort-incomplete-multipart-uploads"
    status = "Enabled"

    filter {}

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }

  rule {
    id     = "transition-to-cost-optimized-storage"
    status = "Enabled"

    filter {}

    transition {
      days          = 90
      storage_class = "STANDARD_IA"
    }

    transition {
      days          = 365
      storage_class = "GLACIER"
    }

    transition {
      days          = 2555
      storage_class = "DEEP_ARCHIVE"
    }
  }
}