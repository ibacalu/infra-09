locals {
  tags = merge(
    {
      ManagedBy = "Terraform"
      Module    = "fck-nat"
    },
    var.tags
  )

  # Convert list of route table IDs to map format required by fck-nat module
  route_tables_map = { for idx, rt_id in var.private_route_table_ids : "rt-${idx}" => rt_id }
}

module "fck_nat" {
  source  = "RaJiska/fck-nat/aws"
  version = "1.4.0"

  name      = "${var.name}-fck-nat"
  vpc_id    = var.vpc_id
  subnet_id = var.public_subnet_id

  instance_type = var.instance_type

  # Automatically update private route tables
  update_route_tables = true
  route_tables_ids    = local.route_tables_map

  tags = local.tags
}
