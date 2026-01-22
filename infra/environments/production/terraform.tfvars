# Production Account Configuration
# Live customer-facing applications with integrated development and testing capabilities

#================================================================================
# Basic Configuration
#================================================================================

# AWS region for all resources
aws_region = "eu-central-1"

# Project name used for resource naming and tagging (lowercase, hyphens only)
project_name = "platform"

# Team responsible for infrastructure management
owner_team = "platform-engineering"

# Cost center for billing allocation
cost_center = "engineering"

#================================================================================
# Networking Configuration
#================================================================================

# VPC CIDR block for production environment
vpc_cidr = "10.0.0.0/16"

# Availability zones to use (3 AZs for high availability)
availability_zones = ["eu-central-1a", "eu-central-1b", "eu-central-1c"]
# Public subnets (for load balancers, NAT gateways)
public_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]

# Private subnets (for application servers)
private_subnets = ["10.0.11.0/24", "10.0.12.0/24", "10.0.13.0/24"]

# Database subnets (isolated from application tier)
database_subnets = ["10.0.21.0/24", "10.0.22.0/24", "10.0.23.0/24"]

#================================================================================
# Compute Configuration
#================================================================================

# Enable ECS cluster for containerized applications
enable_ecs_cluster = true

# Enable Lambda functions support
enable_lambda_functions = true

# Enable RDS database
enable_rds = true

#================================================================================
# Security Configuration
#================================================================================

# Enable AWS WAF for web application protection
enable_waf = true

# Enable AWS Shield for DDoS protection
enable_shield = false # Shield Advanced requires subscription

#================================================================================
# Monitoring Configuration
#================================================================================

# Enable AWS X-Ray for distributed tracing
enable_xray = false

# CloudWatch log retention in days
cloudwatch_log_retention = 14

#================================================================================
# EKS Configuration
#================================================================================

# Root DNS zone for cluster services (delegated from Cloudflare)
root_route53_zone = "platform-09.qts.one"

# Email for Let's Encrypt certificate notifications
# letsencrypt_email = "devops@qtsone.com"

# SSO Access Entries for cluster administration
# Find your SSO role: aws iam list-roles --query "Roles[?contains(RoleName, 'AWSReservedSSO')]"
eks_access_entries = {
  # admin = {
  #   principal_arn = "arn:aws:iam::654735440633:role/AWSReservedSSO_AdministratorAccess_XXXX"
  #   policy_associations = {
  #     admin = {
  #       policy_arn   = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
  #       access_scope = { type = "cluster" }
  #     }
  #   }
  # }
}

#================================================================================
# NOTES
#================================================================================

# 1. CROSS-ACCOUNT TRUST:
#    - Production account trusts management account root
#    - management_account_id is fetched from TFC remote state
#    - TFC authenticates to management, assumes role in production

# 2. NETWORKING:
#    - VPC uses private IP space (10.0.0.0/16)
#    - VPC Endpoints for AWS services (no NAT for ECR, S3, etc.)
#    - fck-nat for public internet access (DockerHub, external APIs)

# 3. EKS:
#    - Private cluster endpoint (no public access)
#    - Karpenter for node autoscaling
#    - Single t3.medium node for bootstrap

# 4. PREREQUISITES:
#    - Create Route53 zone: platform-09.qts.one
#    - Delegate NS records in Cloudflare
#    - Create GitHub App secret: eks/argocd/github_app_private_key
#    - Find and configure SSO role ARN in eks_access_entries

