output "function_name" {
  description = "Name of the bootstrap Lambda function"
  value       = aws_lambda_function.bootstrap.function_name
}

output "function_arn" {
  description = "ARN of the bootstrap Lambda function"
  value       = aws_lambda_function.bootstrap.arn
}

output "invoke_arn" {
  description = "Invoke ARN of the bootstrap Lambda function"
  value       = aws_lambda_function.bootstrap.invoke_arn
}

output "role_arn" {
  description = "ARN of the Lambda execution role (add to EKS access entries)"
  value       = aws_iam_role.lambda.arn
}

output "role_name" {
  description = "Name of the Lambda execution role"
  value       = aws_iam_role.lambda.name
}

output "security_group_id" {
  description = "Security group ID of the Lambda function"
  value       = aws_security_group.lambda.id
}
