output "endpoints" {
  description = "Map of VPC endpoints created"
  value       = module.endpoints.endpoints
}

output "security_group_id" {
  description = "Security group ID for VPC endpoints"
  value       = module.endpoints.security_group_id
}
