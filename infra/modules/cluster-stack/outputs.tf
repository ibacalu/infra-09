output "vpc_id" {
  description = "VPC ID"
  value       = var.vpc_config.vpc_id
}

output "private_subnets" {
  description = "Private Subnets"
  value       = var.vpc_config.private_subnets
}

output "public_subnets" {
  description = "Public Subnets"
  value       = var.vpc_config.public_subnets
}

output "cluster_name" {
  description = "EKS Cluster Name"
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "EKS Cluster Endpoint"
  value       = module.eks.cluster_endpoint
}

output "cluster_certificate_authority_data" {
  description = "EKS Cluster CA Data"
  value       = module.eks.cluster_certificate_authority_data
}

output "cluster_arn" {
  description = "EKS Cluster ARN"
  value       = module.eks.cluster_arn
}
