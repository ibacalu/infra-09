################################################################################
# Bootstrap Lambda
#
# This module creates a Lambda function that bootstraps the EKS cluster with
# ArgoCD and initial configuration. It runs inside the VPC and authenticates
# to EKS using IAM (via Access Entries).
################################################################################

locals {
  argocd_project_manifest = templatefile("${path.module}/templates/project.tftpl", {})

  argocd_application_manifest = templatefile("${path.module}/templates/application.tftpl", {
    organisation = {
      # Use "bootstrap" as the name to distinguish from potentially other "organisation" apps
      name        = "bootstrap"
      repo_url    = var.argocd_config.repo_url
      repo_path   = "gitops/services/argocd/base/overrides/plugins/organisation"
      branch      = "HEAD"
      environment = var.environment
    }
  })
}

module "bootstrap_lambda" {
  source = "../cluster-bootstrap-lambda"

  name_prefix = local.name
  vpc_id      = module.vpc.vpc_id
  subnet_ids  = module.vpc.private_subnets
  tags        = local.tags
}

# Grant Lambda access to the EKS cluster
resource "aws_eks_access_entry" "bootstrap_lambda" {
  cluster_name  = module.eks.cluster_name
  principal_arn = module.bootstrap_lambda.role_arn
  type          = "STANDARD"

  tags = local.tags
}

resource "aws_eks_access_policy_association" "bootstrap_lambda" {
  cluster_name  = module.eks.cluster_name
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
  principal_arn = module.bootstrap_lambda.role_arn

  access_scope {
    type = "cluster"
  }
}

resource "aws_lambda_invocation" "bootstrap" {
  function_name = module.bootstrap_lambda.function_name

  input = jsonencode({
    cluster_name = module.eks.cluster_name
    region       = data.aws_region.current.id

    # Secrets are read from Secrets Manager by prefix
    secrets_prefix = var.secrets_prefix

    # ArgoCD manifests (pre-rendered by kustomization provider)
    # Passed in priority order: p0 (CRDs/Namespaces), p1 (Core), p2 (CRs)
    argocd_manifests_p0 = [
      for id in data.kustomization_overlay.argocd.ids_prio[0] :
      data.kustomization_overlay.argocd.manifests[id]
    ]
    argocd_manifests_p1 = [
      for id in data.kustomization_overlay.argocd.ids_prio[1] :
      data.kustomization_overlay.argocd.manifests[id]
    ]
    argocd_manifests_p2 = concat([
      for id in data.kustomization_overlay.argocd.ids_prio[2] :
      data.kustomization_overlay.argocd.manifests[id]
      ], [
      local.argocd_project_manifest,
      local.argocd_application_manifest
    ])

    # ArgoCD bootstrap application config
    argocd_config = var.argocd_config

    # Cluster config for ConfigMap
    cluster_config = local.cluster_config_data
  })

  # Re-invoke if cluster or config changes
  triggers = {
    cluster_endpoint        = module.eks.cluster_endpoint
    config_hash             = sha256(jsonencode(local.cluster_config_data))
    argocd_hash             = sha256(jsonencode(var.argocd_config))
    argocd_manifests_hash   = sha256(jsonencode(data.kustomization_overlay.argocd.ids))
    argocd_project_hash     = sha256(local.argocd_project_manifest)
    argocd_application_hash = sha256(local.argocd_application_manifest)
  }

  depends_on = [
    module.eks,
    aws_eks_access_entry.bootstrap_lambda,
    aws_eks_access_policy_association.bootstrap_lambda,
    aws_eks_access_entry.karpenter_node
  ]
}

resource "aws_security_group_rule" "bootstrap_lambda_to_cluster" {
  description              = "Allow HTTPS from Bootstrap Lambda"
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = module.bootstrap_lambda.security_group_id
  security_group_id        = module.eks.cluster_security_group_id
}
