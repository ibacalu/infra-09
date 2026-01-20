# AWS Organizations Module Outputs

output "organization_id" {
  description = "The ID of the AWS Organization"
  value       = aws_organizations_organization.main.id
}

output "management_account_id" {
  description = "The ID of the management account (current account)"
  value       = aws_organizations_organization.main.master_account_id
}

output "organization_arn" {
  description = "The ARN of the AWS Organization"
  value       = aws_organizations_organization.main.arn
}

output "organization_root_id" {
  description = "The root ID of the AWS Organization"
  value       = aws_organizations_organization.main.roots[0].id
}

output "core_ou_id" {
  description = "The ID of the Core Organizational Unit"
  value       = aws_organizations_organizational_unit.core.id
}

output "workloads_ou_id" {
  description = "The ID of the Workloads Organizational Unit"
  value       = aws_organizations_organizational_unit.workloads.id
}

output "security_account_id" {
  description = "The ID of the security account"
  value       = aws_organizations_account.security.id
}

output "production_account_id" {
  description = "The ID of the production account"
  value       = aws_organizations_account.production.id
}

output "security_account_arn" {
  description = "The ARN of the security account"
  value       = aws_organizations_account.security.arn
}

output "production_account_arn" {
  description = "The ARN of the production account"
  value       = aws_organizations_account.production.arn
}