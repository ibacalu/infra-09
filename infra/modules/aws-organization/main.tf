# AWS Organizations Management Module
# Creates and manages AWS Organizations with streamlined 3-account structure

# Create the AWS Organization
resource "aws_organizations_organization" "main" {
  feature_set = "ALL"

  enabled_policy_types = [
    "SERVICE_CONTROL_POLICY",
    "TAG_POLICY"
  ]

  aws_service_access_principals = [
    "account.amazonaws.com", # Required for AWS Account Management
    "cloudtrail.amazonaws.com",
    "config.amazonaws.com",
    "guardduty.amazonaws.com",
    "securityhub.amazonaws.com",
    "sso.amazonaws.com" # Required for IAM Identity Center (SSO) integration
  ]
}

# Organizational Units
resource "aws_organizations_organizational_unit" "core" {
  name      = "Core"
  parent_id = aws_organizations_organization.main.roots[0].id
}

resource "aws_organizations_organizational_unit" "workloads" {
  name      = "Workloads"
  parent_id = aws_organizations_organization.main.roots[0].id
}

# Security & Platform Account
resource "aws_organizations_account" "security" {
  name      = "${var.project_name}-security"
  email     = var.security_account_email
  parent_id = aws_organizations_organizational_unit.core.id

  tags = merge(var.common_tags, {
    AccountType = "Security"
    Services    = "Security-Logging-Platform"
  })

  # Ensure account management service access is enabled before renaming
  depends_on = [aws_organizations_organization.main]
}

# Production Account
resource "aws_organizations_account" "production" {
  name      = "${var.project_name}-production"
  email     = var.production_account_email
  parent_id = aws_organizations_organizational_unit.workloads.id

  tags = merge(var.common_tags, {
    AccountType = "Production"
    Services    = "Workloads"
  })

  # Ensure account management service access is enabled before renaming
  depends_on = [aws_organizations_organization.main]
}

# Service Control Policy for security
resource "aws_organizations_policy" "deny_root_access" {
  name        = "DenyRootAccess"
  description = "Deny root user access except in emergency"
  type        = "SERVICE_CONTROL_POLICY"

  content = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "DenyHighRiskActionsForRoot"
        Effect = "Deny"
        Action = [
          "organizations:LeaveOrganization",
          "organizations:CloseAccount"
        ]
        Resource = "*"
        Condition = {
          StringLike = {
            "aws:userid" = "AIDA*"
          }
        }
      }
    ]
  })
}

# Attach SCP to accounts
resource "aws_organizations_policy_attachment" "security_deny_root" {
  policy_id = aws_organizations_policy.deny_root_access.id
  target_id = aws_organizations_account.security.id
}

resource "aws_organizations_policy_attachment" "production_deny_root" {
  policy_id = aws_organizations_policy.deny_root_access.id
  target_id = aws_organizations_account.production.id
}