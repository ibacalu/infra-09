locals {
  name = "${var.project_name}-${var.cluster_identifier}"

  # Tags
  tags = merge(var.tags, {
    Cluster = local.name
  })

  # Generates ConfigMap in ArgoCD with relevant cluster information
  cluster_config_data = {
    cluster_name     = module.eks.cluster_name
    cluster_endpoint = module.eks.cluster_endpoint
    cluster_arn      = module.eks.cluster_arn
    region           = data.aws_region.current.id
    vpc_id           = var.vpc_config.vpc_id
    environment      = var.environment

    # IAM Roles (Pod Identity)
    karpenter_iam_role_arn           = aws_iam_role.karpenter.arn
    karpenter_node_iam_role_arn      = aws_iam_role.karpenter_node.arn
    external_dns_iam_role_arn        = aws_iam_role.external_dns.arn
    cert_manager_iam_role_arn        = aws_iam_role.cert_manager.arn
    aws_ebs_csi_driver_iam_role_arn  = aws_iam_role.aws_ebs_csi_driver.arn
    external_secrets_iam_role_arn    = aws_iam_role.external_secrets.arn
    aws_load_balancer_controller_arn = aws_iam_role.aws_load_balancer_controller.arn

    # DNS
    rootDNSZoneName    = var.root_route53_zone_name
    rootDNSZoneId      = var.root_route53_zone_id
    clusterDNSZoneName = aws_route53_zone.cluster.name
    clusterDNSZoneId   = aws_route53_zone.cluster.zone_id
    clusterDNSZoneCert = aws_acm_certificate.cluster.arn

    letsencrypt_email = var.letsencrypt_email
    cluster-issuer    = "letsencrypt-prod"
  }
}
