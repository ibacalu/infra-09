# Create OIDC Identity Provider for Terraform Cloud
resource "aws_iam_openid_connect_provider" "tfc" {
  url             = "https://app.terraform.io"
  client_id_list  = ["aws.workload.identity"]
  thumbprint_list = [data.tls_certificate.tfc.certificates[0].sha1_fingerprint]

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-tfc-oidc"
  })
}

# IAM Role for Terraform Cloud
resource "aws_iam_role" "tfc" {
  name = "${var.project_name}-TerraformCloud"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Federated = aws_iam_openid_connect_provider.tfc.arn
      }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "app.terraform.io:aud" = "aws.workload.identity"
        }
        StringLike = {
          # Allow any workspace in the organization to assume this role
          "app.terraform.io:sub" = "organization:${var.tfc_organization}:project:*:workspace:*:run_phase:*"
        }
      }
    }]
  })

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-TerraformCloud"
  })
}

# Attach AdministratorAccess policy to the TFC role
resource "aws_iam_role_policy_attachment" "tfc_admin" {
  role       = aws_iam_role.tfc.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}
