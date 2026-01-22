# Production Account Variables
# Configuration variables for the production environment

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

# Networking Configuration
variable "vpc_cidr" {
  description = "CIDR block for the production VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "List of availability zones to use"
  type        = list(string)
  default     = ["eu-central-1a", "eu-central-1b", "eu-central-1c"]
}

variable "public_subnets" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
}

variable "private_subnets" {
  description = "CIDR blocks for private subnets"
  type        = list(string)
  default     = ["10.0.11.0/24", "10.0.12.0/24", "10.0.13.0/24"]
}

variable "database_subnets" {
  description = "CIDR blocks for database subnets"
  type        = list(string)
  default     = ["10.0.21.0/24", "10.0.22.0/24", "10.0.23.0/24"]
}

# Compute Configuration
variable "enable_ecs_cluster" {
  description = "Enable ECS cluster for containerized applications"
  type        = bool
  default     = true
}

variable "enable_lambda_functions" {
  description = "Enable Lambda functions support"
  type        = bool
  default     = true
}

variable "enable_rds" {
  description = "Enable RDS database"
  type        = bool
  default     = true
}

# Security Configuration
variable "enable_waf" {
  description = "Enable AWS WAF for web application protection"
  type        = bool
  default     = true
}

variable "enable_shield" {
  description = "Enable AWS Shield for DDoS protection"
  type        = bool
  default     = true
}

# Monitoring Configuration
variable "enable_xray" {
  description = "Enable AWS X-Ray for distributed tracing"
  type        = bool
  default     = true
}

variable "cloudwatch_log_retention" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 30
}

variable "root_route53_zone" {
  description = "Root Route53 zone for cluster DNS (e.g., platform-09.qts.one)"
  type        = string
}

variable "letsencrypt_email" {
  description = "Email for Let's Encrypt certificate notifications"
  type        = string
}

variable "eks_access_entries" {
  description = "SSO role mappings for EKS cluster access via Access Entries"
  type        = any
  default     = {}
}

################################################################################
# Secrets (from Terraform Cloud Variable Sets)
################################################################################

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
