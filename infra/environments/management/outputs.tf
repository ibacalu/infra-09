# Management Account Outputs
# Outputs for cross-account references and state sharing

output "organization_id" {
  description = "AWS Organization ID"
  value       = module.aws_organization.organization_id
}

output "organization_arn" {
  description = "AWS Organization ARN"
  value       = module.aws_organization.organization_arn
}

output "security_account_id" {
  description = "Security account ID"
  value       = module.aws_organization.security_account_id
  sensitive   = true
}

output "production_account_id" {
  description = "Production account ID"
  value       = module.aws_organization.production_account_id
  sensitive   = true
}

# Note: State is managed by Terraform Cloud, no S3 outputs needed

output "cross_account_role_arn" {
  description = "Cross-account role ARN for Terraform operations"
  value       = module.account_baseline.cross_account_role_arn
}

# IAM Identity Center Outputs
output "sso_portal_url" {
  description = "AWS SSO portal URL for user login"
  value       = module.identity_center.sso_portal_url
}

output "identity_center_instance_arn" {
  description = "The ARN of the Identity Center instance"
  value       = module.identity_center.instance_arn
  sensitive   = true
}

output "identity_store_id" {
  description = "The ID of the Identity Store"
  value       = module.identity_center.identity_store_id
  sensitive   = true
}

output "admin_permission_set_arn" {
  description = "The ARN of the Admin permission set"
  value       = module.identity_center.admin_permission_set_arn
  sensitive   = true
}

output "administrators_group_id" {
  description = "The ID of the Administrators group in Identity Center"
  value       = module.identity_center.administrators_group_id
  sensitive   = true
}

# TFC OIDC Outputs - Use these to configure TFC Variable Sets
output "tfc_oidc_role_arn" {
  description = "IAM Role ARN for TFC OIDC authentication - use this in TFC_AWS_RUN_ROLE_ARN"
  value       = module.tfc_oidc.tfc_role_arn
}

output "tfc_oidc_provider_arn" {
  description = "OIDC Provider ARN for TFC"
  value       = module.tfc_oidc.oidc_provider_arn
}
