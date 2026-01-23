# VPC
module "vpc" {
  source = "../../modules/networking/vpc"

  config = {
    environment   = var.environment
    vpc_name      = "${local.name}-vpc"
    vpc_cidr      = var.vpc_cidr
    max_cidr_mask = 18

    clusters = {
      main = {
        public_subnet_new_bit  = 8 # /24
        private_subnet_new_bit = 6 # /22
      }
    }

    public_subnet_tags = {
      "kubernetes.io/role/elb"               = "1"
      "karpenter.sh/discovery/${local.name}" = "true"
    }
    private_subnet_tags = {
      "kubernetes.io/role/internal-elb"      = "1"
      "karpenter.sh/discovery/${local.name}" = "true"
    }

    enable_nat_gateway = false # Using fck-nat
    tags               = local.tags
  }
}

# VPC Endpoints
module "vpc_endpoints" {
  source = "../../modules/networking/vpc-endpoints"

  name            = local.name
  vpc_id          = module.vpc.vpc_id
  vpc_cidr        = var.vpc_cidr
  subnet_ids      = module.vpc.private_subnets
  route_table_ids = module.vpc.vpc.private_route_table_ids
  tags            = local.tags
}

# NAT
module "fck_nat" {
  source = "../../modules/networking/fck-nat"

  name                    = local.name
  vpc_id                  = module.vpc.vpc_id
  public_subnet_id        = module.vpc.public_subnets[0]
  private_route_table_ids = module.vpc.vpc.private_route_table_ids
  instance_type           = var.nat_instance_type
  tags                    = local.tags
}

# EKS
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "21.14.0"

  name               = local.name
  kubernetes_version = var.cluster_version

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets # Worker nodes in private subnets

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
    coredns    = { most_recent = true }
    kube-proxy = { most_recent = true }
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

# Setup IAM Roles for Service Accounts
module "irsa" {
  source = "../eks/modules/irsa"

  config = {
    cluster_name            = module.eks.cluster_name
    oidc_provider_arn       = module.eks.oidc_provider_arn
    cluster_oidc_issuer_url = module.eks.cluster_oidc_issuer_url

    # Route53 zones for ExternalDNS
    route53_zone_ids = [var.root_route53_zone_id] # Add cluster zone if created

    # Feature flags
    enable_karpenter                = true
    enable_cluster_autoscaler       = false
    enable_external_dns             = true
    enable_cert_manager             = true
    enable_aws_ebs_csi_driver       = true
    enable_load_balancer_controller = true
    enable_external_secrets         = true
  }
}

# Karpenter Node Access
resource "aws_eks_access_entry" "karpenter_node" {
  cluster_name  = module.eks.cluster_name
  principal_arn = module.irsa.karpenter_node_iam_role_arn
  type          = "EC2_LINUX"

  tags = local.tags
}
