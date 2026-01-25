# EKS Cluster
# VPC, VPC Endpoints, and NAT are provided by the parent module (shared infrastructure)

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "21.14.0"

  name               = local.name
  kubernetes_version = var.cluster_version

  vpc_id     = var.vpc_config.vpc_id
  subnet_ids = var.vpc_config.private_subnets # Worker nodes in private subnets

  # Access
  endpoint_private_access = true
  endpoint_public_access  = true

  authentication_mode                      = "API"
  enable_cluster_creator_admin_permissions = true
  access_entries                           = var.access_entries

  # Security Groups - Enable recommended rules for node-to-control-plane communication
  node_security_group_enable_recommended_rules = true

  node_security_group_tags = {
    # Required for Karpenter EC2NodeClass validation (spec.securityGroupSelectorTerms)
    "karpenter.sh/discovery/${local.name}" = "true"
  }

  # Addons - VPC CNI must be deployed before compute (nodes need CNI for networking)
  addons = {
    coredns                = { most_recent = true }
    kube-proxy             = { most_recent = true }
    eks-pod-identity-agent = { most_recent = true }
    aws-ebs-csi-driver     = { most_recent = true }
    vpc-cni = {
      most_recent    = true
      before_compute = true # Ensure CNI is ready before nodes try to join
      configuration_values = jsonencode({
        env = {
          ENABLE_PREFIX_DELEGATION = "true"
          WARM_PREFIX_TARGET       = "1"
        }
      })
      resolve_conflicts_on_update = "OVERWRITE"
    }
  }

  # Node Groups
  eks_managed_node_groups = {
    system = {
      name           = "system"
      instance_types = ["t3.medium"]
      capacity_type  = "ON_DEMAND"
      min_size       = 1
      max_size       = 3
      desired_size   = 1

      # Bottlerocket - purpose-built for containers, minimal attack surface,
      # atomic updates with rollback, works reliably with EKS managed node groups
      ami_type = "BOTTLEROCKET_x86_64"

      # Increase max-pods since we enabled Prefix Delegation in VPC CNI
      bootstrap_extra_args = <<-EOT
        [settings.kubernetes]
        "max-pods" = 110
      EOT

      labels = { "node-role" = "system" }
      tags   = { "karpenter.sh/discovery" = local.name }
    }
  }

  tags = local.tags
}
