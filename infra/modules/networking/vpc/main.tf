module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "6.6.0"

  name                  = local.config.vpc_name
  cidr                  = local.config.vpc_cidr
  secondary_cidr_blocks = local.config.secondary_cidr_blocks

  azs                 = local.config.availability_zones
  public_subnets      = local.config.public_subnets
  public_subnet_names = local.config.public_subnet_names
  public_subnet_tags  = local.config.public_subnet_tags

  private_subnets      = local.config.private_subnets
  private_subnet_names = local.config.private_subnet_names
  private_subnet_tags  = local.config.private_subnet_tags

  enable_nat_gateway     = var.config.enable_nat_gateway
  single_nat_gateway     = var.config.single_nat_gateway
  one_nat_gateway_per_az = var.config.one_nat_gateway_per_az

  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = local.config.tags
}
