variable "project_name" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "cluster_identifier" {
  description = "Unique identifier for the cluster (e.g. 'main', 'canary'). Used in suffixes."
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "region" {
  description = "AWS Region"
  type        = string
}

variable "cluster_version" {
  description = "Kubernetes version"
  type        = string
  default     = "1.31"
}

variable "argocd_config" {
  description = "Configuration for ArgoCD bootstrapping (repo url, branch, etc)"
  type = object({
    repo_url    = string
    repo_path   = string
    branch      = string
    environment = string
  })
}

variable "access_entries" {
  description = "Access entries for EKS (SSO roles)"
  type        = any
  default     = {}
}

variable "tags" {
  description = "Common tags"
  type        = map(string)
  default     = {}
}

variable "root_route53_zone_name" {
  description = "Root Route53 zone name"
  type        = string
}

variable "root_route53_zone_id" {
  description = "Root Route53 zone ID"
  type        = string
}

variable "letsencrypt_email" {
  description = "Email for ACME registration"
  type        = string
}

variable "argocd_base_url" {
  description = "Kustomize URL for ArgoCD base installation (e.g. https://github.com/org/repo//path?ref=main)"
  type        = string
  default     = "https://github.com/ibacalu/infra-09//gitops/services/argocd/base?ref=main"
}

variable "secrets_prefix" {
  description = "Prefix for secrets in AWS Secrets Manager (e.g. eks/platform-main-01/argocd/)"
  type        = string
}
