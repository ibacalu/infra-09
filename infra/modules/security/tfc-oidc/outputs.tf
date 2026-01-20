# TFC OIDC Module - outputs.tf

output "oidc_provider_arn" {
  description = "ARN of the OIDC Identity Provider"
  value       = aws_iam_openid_connect_provider.tfc.arn
}

output "tfc_role_arn" {
  description = "ARN of the TFC IAM Role - use this in TFC Variable Sets"
  value       = aws_iam_role.tfc.arn
}

output "tfc_role_name" {
  description = "Name of the TFC IAM Role"
  value       = aws_iam_role.tfc.name
}
