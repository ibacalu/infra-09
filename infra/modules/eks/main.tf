module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "21.14.0"

  name               = var.eks.cluster_name
  kubernetes_version = var.eks.cluster_version

  vpc_id     = data.aws_vpc.this.id
  subnet_ids = var.config.private_subnet_ids

  tags             = local.tags
  prefix_separator = var.eks.prefix_separator

  ################################################################################
  # Cluster Access / Authentication (SSO via Access Entries)
  ################################################################################
  # Use API mode for authentication - works with SSO/Identity Center
  authentication_mode                      = "API"
  enable_cluster_creator_admin_permissions = true
  access_entries                           = var.eks.access_entries

  ################################################################################
  # Cluster
  ################################################################################
  enabled_log_types                  = var.eks.cluster_enabled_log_types
  additional_security_group_ids      = var.eks.cluster_additional_security_group_ids
  control_plane_subnet_ids           = var.eks.control_plane_subnet_ids
  endpoint_private_access            = var.eks.cluster_endpoint_private_access
  endpoint_public_access             = var.eks.cluster_endpoint_public_access
  endpoint_public_access_cidrs       = var.eks.cluster_endpoint_public_access_cidrs
  ip_family                          = var.eks.cluster_ip_family
  service_ipv4_cidr                  = var.eks.cluster_service_ipv4_cidr
  service_ipv6_cidr                  = var.eks.cluster_service_ipv6_cidr
  outpost_config                     = var.eks.outpost_config
  encryption_config                  = var.eks.cluster_encryption_config
  attach_encryption_policy           = var.eks.attach_cluster_encryption_policy
  cluster_tags                       = var.eks.cluster_tags
  create_primary_security_group_tags = var.eks.create_cluster_primary_security_group_tags
  timeouts                           = var.eks.cluster_timeouts

  ################################################################################
  # KMS Key
  ################################################################################
  create_kms_key                    = var.eks.create_kms_key
  kms_key_description               = var.eks.kms_key_description
  kms_key_deletion_window_in_days   = var.eks.kms_key_deletion_window_in_days
  enable_kms_key_rotation           = var.eks.enable_kms_key_rotation
  kms_key_enable_default_policy     = var.eks.kms_key_enable_default_policy
  kms_key_owners                    = var.eks.kms_key_owners
  kms_key_administrators            = var.eks.kms_key_administrators
  kms_key_users                     = var.eks.kms_key_users
  kms_key_service_users             = var.eks.kms_key_service_users
  kms_key_source_policy_documents   = var.eks.kms_key_source_policy_documents
  kms_key_override_policy_documents = var.eks.kms_key_override_policy_documents
  kms_key_aliases                   = var.eks.kms_key_aliases

  ################################################################################
  # CloudWatch Log Group
  ################################################################################
  create_cloudwatch_log_group            = var.eks.create_cloudwatch_log_group
  cloudwatch_log_group_retention_in_days = var.eks.cloudwatch_log_group_retention_in_days
  cloudwatch_log_group_kms_key_id        = var.eks.cloudwatch_log_group_kms_key_id

  ################################################################################
  # Cluster Security Group
  ################################################################################
  create_security_group           = var.eks.create_cluster_security_group
  security_group_id               = var.eks.cluster_security_group_id
  security_group_name             = var.eks.cluster_security_group_name
  security_group_use_name_prefix  = var.eks.cluster_security_group_use_name_prefix
  security_group_description      = var.eks.cluster_security_group_description
  security_group_additional_rules = var.eks.cluster_security_group_additional_rules
  security_group_tags             = var.eks.cluster_security_group_tags

  ################################################################################
  # EKS IPV6 CNI Policy
  ################################################################################
  create_cni_ipv6_iam_policy = var.eks.create_cni_ipv6_iam_policy

  ################################################################################
  # Node Security Group
  ################################################################################
  create_node_security_group                   = var.eks.create_node_security_group
  node_security_group_id                       = var.eks.node_security_group_id
  node_security_group_name                     = var.eks.node_security_group_name
  node_security_group_use_name_prefix          = var.eks.node_security_group_use_name_prefix
  node_security_group_description              = var.eks.node_security_group_description
  node_security_group_additional_rules         = var.eks.node_security_group_additional_rules
  node_security_group_enable_recommended_rules = var.eks.node_security_group_enable_recommended_rules
  node_security_group_tags                     = var.eks.node_security_group_tags

  ################################################################################
  # IRSA
  ################################################################################
  enable_irsa              = var.eks.enable_irsa
  openid_connect_audiences = var.eks.openid_connect_audiences
  custom_oidc_thumbprints  = var.eks.custom_oidc_thumbprints

  ################################################################################
  # Cluster IAM Role
  ################################################################################
  create_iam_role                   = var.eks.create_iam_role
  iam_role_arn                      = var.eks.iam_role_arn
  iam_role_name                     = var.eks.iam_role_name
  iam_role_use_name_prefix          = var.eks.iam_role_use_name_prefix
  iam_role_path                     = var.eks.iam_role_path
  iam_role_description              = var.eks.iam_role_description
  iam_role_permissions_boundary     = var.eks.iam_role_permissions_boundary
  iam_role_additional_policies      = var.eks.iam_role_additional_policies
  iam_role_tags                     = var.eks.iam_role_tags
  encryption_policy_use_name_prefix = var.eks.cluster_encryption_policy_use_name_prefix
  encryption_policy_name            = var.eks.cluster_encryption_policy_name
  encryption_policy_description     = var.eks.cluster_encryption_policy_description
  encryption_policy_path            = var.eks.cluster_encryption_policy_path
  encryption_policy_tags            = var.eks.cluster_encryption_policy_tags

  ################################################################################
  # EKS Addons
  ################################################################################
  addons          = var.eks.cluster_addons
  addons_timeouts = var.eks.cluster_addons_timeouts

  ################################################################################
  # EKS Identity Provider
  ################################################################################
  identity_providers = var.eks.cluster_identity_providers

  ################################################################################
  # Fargate
  ################################################################################
  fargate_profiles = var.eks.fargate_profiles

  ################################################################################
  # Self Managed Node Group
  ################################################################################
  self_managed_node_groups = var.eks.self_managed_node_groups

  ################################################################################
  # EKS Managed Node Group
  ################################################################################
  eks_managed_node_groups = local.eks_managed_node_groups
}

module "irsa" {
  source = "./modules/irsa"

  config = local.irsa
}



# Karpenter node access entry - created separately to avoid circular dependency
# This allows Karpenter-launched nodes to join the cluster
resource "aws_eks_access_entry" "karpenter_node" {
  cluster_name  = module.eks.cluster_name
  principal_arn = module.irsa.karpenter_node_iam_role_arn
  type          = "EC2_LINUX"

  tags = local.tags
}
