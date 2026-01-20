# Management Account Configuration
# Sensitive variables (account emails) are managed in Terraform Cloud Variable Sets

#================================================================================
# Basic Configuration
#================================================================================
aws_region        = "eu-central-1"
project_name      = "platform"
organization_name = "platform-org"
owner_team        = "platform-engineering"
cost_center       = "engineering"

# Terraform Cloud organization for OIDC authentication
tfc_organization = "infra-09"

#================================================================================
# Account Email Addresses
# NOTE: These are managed in Terraform Cloud Variable Sets (sensitive)
# Variables: security_account_email, production_account_email
#================================================================================

#================================================================================
# Security and Compliance
#================================================================================
enable_config     = true
enable_cloudtrail = false
enable_guardduty  = false

#================================================================================
# IAM Identity Center (SSO) Configuration
#================================================================================
enable_identity_center_mfa             = true
identity_center_session_duration_admin = "PT4H"

# Users to create in IAM Identity Center (GitOps-managed)
users = {
  "iulian" = {
    email      = "ibacalu@qts.one"
    first_name = "Iulian"
    last_name  = "Bacalu"
    groups     = ["administrators"]
  }
  # "developer1" = {
  #   email      = "dev1@example.com"
  #   first_name = "Dev"
  #   last_name  = "One"
  #   groups     = ["developers"]
  # }
}
