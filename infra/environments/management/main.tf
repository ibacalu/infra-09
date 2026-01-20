# Management Account Configuration
# This account serves as the AWS Organizations root and handles billing, governance, and cross-account roles

# Data source to get current account information
data "aws_caller_identity" "current" {}

# Local values for consistent tagging
locals {
  common_tags = {
    Project     = var.project_name
    Environment = "management"
    Owner       = var.owner_team
    CostCenter  = var.cost_center
    Compliance  = "required"
    ManagedBy   = "terraform"
  }
}

# AWS Organizations setup
module "aws_organization" {
  source = "../../modules/aws-organization"

  organization_name        = var.organization_name
  project_name             = var.project_name
  security_account_email   = var.security_account_email
  production_account_email = var.production_account_email
  common_tags              = local.common_tags
}

# Account baseline configuration
module "account_baseline" {
  source = "../../modules/account-baseline"

  account_name          = "management"
  environment           = "management"
  project_name          = var.project_name
  management_account_id = data.aws_caller_identity.current.account_id
  common_tags           = local.common_tags
  enable_cloudtrail     = var.enable_cloudtrail
  enable_config         = var.enable_config
  enable_guardduty      = var.enable_guardduty
}

# IAM Identity Center (SSO)
# Note: IAM Identity Center must be manually enabled in AWS Console first
module "identity_center" {
  source = "../../modules/security/identity-center"

  project_name           = var.project_name
  management_account_id  = module.aws_organization.management_account_id
  security_account_id    = module.aws_organization.security_account_id
  production_account_id  = module.aws_organization.production_account_id
  admin_user_email       = var.admin_user_email
  enable_mfa             = var.enable_identity_center_mfa
  session_duration_admin = var.identity_center_session_duration_admin
  users                  = var.users
  common_tags            = local.common_tags

  depends_on = [module.aws_organization]
}

# Terraform Cloud OIDC Authentication
module "tfc_oidc" {
  source = "../../modules/security/tfc-oidc"

  project_name     = var.project_name
  tfc_organization = var.tfc_organization
  common_tags      = local.common_tags
}
