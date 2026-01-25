# Root Route53 zone (Shared resource)
resource "aws_route53_zone" "root" {
  name    = var.root_route53_zone
  comment = "Root zone for production clusters"

  tags = merge(local.common_tags, {
    Name = var.root_route53_zone
  })
}

# EC2 Spot Service-Linked Role
# Required for Karpenter to provision Spot instances.
resource "aws_iam_service_linked_role" "spot" {
  aws_service_name = "spot.amazonaws.com"
  description      = "SLR for EC2 Spot Instances"
  tags             = local.common_tags
}

# =============================================================================
# Shared VPC Infrastructure
# All clusters share a single VPC with dedicated subnets per cluster
# =============================================================================

module "vpc" {
  source = "../../modules/networking/vpc"

  config = {
    environment   = lower(local.common_tags.Environment)
    vpc_name      = "${var.project_name}-vpc"
    vpc_cidr      = "10.0.0.0/16"
    max_cidr_mask = 18

    # Dedicated subnets per cluster
    clusters = {
      for key, _ in local.clusters : key => {
        public_subnet_new_bit  = 8 # /24
        private_subnet_new_bit = 6 # /22
      }
    }

    public_subnet_tags = {
      "kubernetes.io/role/elb" = "1"
    }
    private_subnet_tags = merge(
      { "kubernetes.io/role/internal-elb" = "1" },
      { for key, _ in local.clusters : "karpenter.sh/discovery/${var.project_name}-${key}" => "true" }
    )

    enable_nat_gateway = false # Using fck-nat
    tags               = local.common_tags
  }
}

# Shared VPC Endpoints - reduces costs and improves latency
module "vpc_endpoints" {
  source = "../../modules/networking/vpc-endpoints"

  name            = var.project_name
  vpc_id          = module.vpc.vpc_id
  vpc_cidr        = "10.0.0.0/16"
  subnet_ids      = module.vpc.private_subnets
  route_table_ids = module.vpc.vpc.private_route_table_ids
  tags            = local.common_tags
}

# Shared NAT (cost optimization - single NAT for all clusters)
module "fck_nat" {
  source = "../../modules/networking/fck-nat"

  name                    = var.project_name
  vpc_id                  = module.vpc.vpc_id
  public_subnet_id        = module.vpc.public_subnets[0]
  private_route_table_ids = module.vpc.vpc.private_route_table_ids
  instance_type           = "t4g.micro"
  tags                    = local.common_tags
}

module "clusters" {
  source   = "../../modules/cluster-stack"
  for_each = local.cluster_configs

  providers = {
    kustomization = kustomization
  }

  # Context
  project_name       = each.value.project_name
  environment        = each.value.environment
  cluster_identifier = each.key
  region             = each.value.region

  # Shared VPC Configuration with per-cluster subnets
  vpc_config = {
    vpc_id = module.vpc.vpc_id
    # Filter subnets by matching cluster key in network_objects
    public_subnets = [
      for i, n in [for obj in module.vpc.network_objects : obj if obj.type == "Public"] :
      module.vpc.public_subnets[i] if n.cluster == each.key
    ]
    private_subnets = [
      for i, n in [for obj in module.vpc.network_objects : obj if obj.type == "Private"] :
      module.vpc.private_subnets[i] if n.cluster == each.key
    ]
  }

  # EKS Config
  cluster_version = each.value.cluster_version

  # ArgoCD Config
  argocd_config = each.value.argocd_config

  # Setup user access to the cluster
  access_entries = each.value.access_entries
  tags           = each.value.tags

  # Shared Resources
  root_route53_zone_name = each.value.root_route53_zone_name
  root_route53_zone_id   = each.value.root_route53_zone_id
  letsencrypt_email      = each.value.letsencrypt_email

  # Explicit secrets (ARN + name for direct loading)
  secrets = [
    for k, v in aws_secretsmanager_secret.bootstrap_secrets : {
      arn  = v.arn
      name = split("/", v.name)[length(split("/", v.name)) - 1]
    } if startswith(k, each.key)
  ]
}
