output "account_name" {
  description = "Name of the production account"
  value       = "production"
}

output "account_tags" {
  description = "Common tags applied to all resources"
  value       = local.common_tags
}

output "vpc_ids" {
  description = "IDs of the production VPCs keyed by cluster name"
  value       = { for k, v in module.clusters : k => v.vpc_id }
}

output "public_subnets" {
  description = "IDs of the public subnets keyed by cluster name"
  value       = { for k, v in module.clusters : k => v.public_subnets }
}

output "private_subnets" {
  description = "IDs of the private subnets keyed by cluster name"
  value       = { for k, v in module.clusters : k => v.private_subnets }
}

output "cluster_names" {
  description = "EKS cluster names"
  value       = { for k, v in module.clusters : k => v.cluster_name }
}

output "cluster_endpoints" {
  description = "EKS cluster API endpoints"
  value       = { for k, v in module.clusters : k => v.cluster_endpoint }
}

output "cluster_certificate_authorities" {
  description = "Base64 encoded CA certificates for EKS"
  value       = { for k, v in module.clusters : k => v.cluster_certificate_authority_data }
  sensitive   = true
}

output "route53_zone_id" {
  description = "Route53 hosted zone ID"
  value       = aws_route53_zone.root.zone_id
}

output "route53_nameservers" {
  description = "Route53 nameservers - add these as NS records in Cloudflare"
  value       = aws_route53_zone.root.name_servers
}
