# Production Account Variables
variable "aws_region" {
  description = "AWS region for production resources"
  type        = string
  default     = "eu-central-1"
}

variable "project_name" {
  description = "Name of the project for resource naming and tagging"
  type        = string
}

variable "owner_team" {
  description = "Team responsible for this infrastructure"
  type        = string
}

variable "cost_center" {
  description = "Cost center for billing allocation"
  type        = string
}

# Terraform Cloud Variable Sets
variable "root_route53_zone" {
  description = "Root Route53 zone for cluster DNS (e.g., platform-09.qts.one)"
  type        = string
}

variable "letsencrypt_email" {
  description = "Email for Let's Encrypt certificate notifications"
  type        = string
}

variable "github_app_private_key" {
  description = "GitHub App private key for ArgoCD (provided via TFC variable set)"
  type        = string
  sensitive   = true
}

variable "github_organisation" {
  description = "GitHub organisation for repository access"
  type        = string
}

variable "github_app_id" {
  description = "GitHub App ID"
  type        = string
}

variable "github_app_installation_id" {
  description = "GitHub App Installation ID"
  type        = string
}
