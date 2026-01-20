# Secure S3 Bucket Module
terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.28"
    }
  }
}

# Random suffix for unique bucket naming
resource "random_id" "bucket_suffix" {
  byte_length = 4
}

# S3 Bucket
resource "aws_s3_bucket" "this" {
  bucket        = var.bucket_name != "" ? var.bucket_name : "${var.project_name}-${var.environment}-${var.bucket_purpose}-${random_id.bucket_suffix.hex}"
  force_destroy = var.force_destroy

  tags = merge(var.common_tags, {
    Name               = "${var.project_name}-${var.environment}-${var.bucket_purpose}"
    Purpose            = var.bucket_purpose
    DataClassification = var.data_classification
  })
}

# Block all public access (private bucket with IAM authentication)
resource "aws_s3_bucket_public_access_block" "this" {
  bucket = aws_s3_bucket.this.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Server-side encryption configuration
resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  bucket = aws_s3_bucket.this.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = var.kms_key_id != "" ? "aws:kms" : "AES256"
      kms_master_key_id = var.kms_key_id != "" ? var.kms_key_id : null
    }
    bucket_key_enabled = var.kms_key_id != "" ? true : false
  }
}

# Versioning configuration
resource "aws_s3_bucket_versioning" "this" {
  bucket = aws_s3_bucket.this.id

  versioning_configuration {
    status     = var.versioning_enabled ? "Enabled" : "Suspended"
    mfa_delete = var.mfa_delete_enabled ? "Enabled" : "Disabled"
  }
}

# Access logging configuration
resource "aws_s3_bucket_logging" "this" {
  count = var.logging_enabled ? 1 : 0

  bucket = aws_s3_bucket.this.id

  target_bucket = var.logging_bucket_name
  target_prefix = "${var.project_name}/${var.environment}/${var.bucket_purpose}/"
}

# Lifecycle configuration
resource "aws_s3_bucket_lifecycle_configuration" "this" {
  count = var.lifecycle_rules_enabled ? 1 : 0

  bucket = aws_s3_bucket.this.id

  rule {
    id     = "abort-incomplete-multipart-uploads"
    status = "Enabled"

    filter {}

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }

  rule {
    id     = "expire-noncurrent-versions"
    status = "Enabled"

    filter {}

    noncurrent_version_expiration {
      noncurrent_days = var.noncurrent_version_expiration_days
    }
  }

  dynamic "rule" {
    for_each = var.transition_rules

    content {
      id     = rule.value.id
      status = rule.value.status

      filter {
        prefix = rule.value.prefix
      }

      dynamic "transition" {
        for_each = rule.value.transitions

        content {
          days          = transition.value.days
          storage_class = transition.value.storage_class
        }
      }

      dynamic "expiration" {
        for_each = rule.value.expiration_days != null ? [1] : []

        content {
          days = rule.value.expiration_days
        }
      }
    }
  }
}

# Bucket policy - Private with IAM authentication
resource "aws_s3_bucket_policy" "this" {
  bucket = aws_s3_bucket.this.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = concat(
      [
        {
          Sid       = "EnforceSSLOnly"
          Effect    = "Deny"
          Principal = "*"
          Action    = "s3:*"
          Resource = [
            aws_s3_bucket.this.arn,
            "${aws_s3_bucket.this.arn}/*"
          ]
          Condition = {
            Bool = {
              "aws:SecureTransport" = "false"
            }
          }
        }
      ],
      var.additional_policy_statements
    )
  })
}

# CORS configuration (if needed for web applications)
resource "aws_s3_bucket_cors_configuration" "this" {
  count = var.cors_enabled ? 1 : 0

  bucket = aws_s3_bucket.this.id

  dynamic "cors_rule" {
    for_each = var.cors_rules

    content {
      allowed_headers = cors_rule.value.allowed_headers
      allowed_methods = cors_rule.value.allowed_methods
      allowed_origins = cors_rule.value.allowed_origins
      expose_headers  = cors_rule.value.expose_headers
      max_age_seconds = cors_rule.value.max_age_seconds
    }
  }
}

# Object ownership - Disable ACLs (AWS best practice)
resource "aws_s3_bucket_ownership_controls" "this" {
  bucket = aws_s3_bucket.this.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}
