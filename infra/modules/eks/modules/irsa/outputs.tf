output "autoscaler_iam_role_arn" {
  value = aws_iam_role.autoscaler.arn
}

output "external_dns_iam_role_arn" {
  value = aws_iam_role.external_dns.arn
}

output "cert_manager_iam_role_arn" {
  value = aws_iam_role.cert_manager.arn
}

output "aws_ebs_csi_driver_iam_role_arn" {
  value = aws_iam_role.aws_ebs_csi_driver.arn
}

output "aws_load_balancer_controller_arn" {
  value = aws_iam_role.aws_load_balancer_controller.arn
}

output "karpenter_iam_role_arn" {
  value = aws_iam_role.irsa.arn
}

output "karpenter_node_iam_role_arn" {
  value = aws_iam_role.this.arn
}

output "external_secrets_iam_role_arn" {
  value = one(aws_iam_role.external_secrets[*].arn)
}
