# AWS IAM Identity Center Module Outputs

output "identity_store_id" {
  description = "The ID of the Identity Store"
  value       = local.identity_store_id
}

output "instance_arn" {
  description = "The ARN of the SSO Instance"
  value       = local.instance_arn
}

output "admin_permission_set_arn" {
  description = "The ARN of the Admin permission set"
  value       = aws_ssoadmin_permission_set.admin_access.arn
}

output "developer_permission_set_arn" {
  description = "The ARN of the Developer permission set"
  value       = aws_ssoadmin_permission_set.developer_access.arn
}

output "readonly_permission_set_arn" {
  description = "The ARN of the ReadOnly permission set"
  value       = aws_ssoadmin_permission_set.readonly_access.arn
}

output "administrators_group_id" {
  description = "The ID of the Administrators group"
  value       = aws_identitystore_group.administrators.group_id
}

output "developers_group_id" {
  description = "The ID of the Developers group"
  value       = aws_identitystore_group.developers.group_id
}

output "viewers_group_id" {
  description = "The ID of the Viewers group"
  value       = aws_identitystore_group.viewers.group_id
}

output "sso_portal_url" {
  description = "The AWS SSO portal URL for user login"
  value       = "https://${local.identity_store_id}.awsapps.com/start"
}
