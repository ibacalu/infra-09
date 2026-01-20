# Provider configuration for management account
provider "aws" {
  region = var.aws_region

  default_tags {
    tags = local.common_tags
  }
}
