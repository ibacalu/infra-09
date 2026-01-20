# Account Baseline Module Outputs

output "cross_account_role_arn" {
  description = "ARN of the cross-account role for Terraform operations"
  value       = aws_iam_role.terraform_execution_role.arn
}

output "cross_account_role_name" {
  description = "Name of the cross-account role for Terraform operations"
  value       = aws_iam_role.terraform_execution_role.name
}

output "cloudtrail_arn" {
  description = "ARN of the CloudTrail"
  value       = var.enable_cloudtrail ? aws_cloudtrail.account_trail[0].arn : null
}

output "cloudtrail_bucket_name" {
  description = "Name of the CloudTrail S3 bucket"
  value       = var.enable_cloudtrail ? aws_s3_bucket.cloudtrail_bucket[0].id : null
}

output "cloudtrail_bucket_arn" {
  description = "ARN of the CloudTrail S3 bucket"
  value       = var.enable_cloudtrail ? aws_s3_bucket.cloudtrail_bucket[0].arn : null
}