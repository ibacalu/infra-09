module "db" {
  source  = "terraform-aws-modules/rds/aws"
  version = "~> 6.0"

  identifier = var.identifier

  engine               = "postgres"
  engine_version       = "14"
  family               = "postgres14"
  major_engine_version = "14"
  instance_class       = var.instance_class

  allocated_storage     = var.allocated_storage
  max_allocated_storage = 100

  db_name  = var.db_name
  username = var.username
  port     = 5432

  # We will rely on IAM authentication or standard password auth.
  # For this challenge, we let the module generate a random password if not provided.
  manage_master_user_password = true

  vpc_security_group_ids = [module.security_group.security_group_id]

  # DB subnet group
  create_db_subnet_group = true
  subnet_ids             = var.subnet_ids

  # Database Deletion Protection
  deletion_protection = false # For demo purposes
  skip_final_snapshot = true  # For demo purposes

  tags = var.tags
}

module "security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 5.0"

  name        = "${var.identifier}-sg"
  description = "Complete PostgreSQL example security group"
  vpc_id      = var.vpc_id

  # Ingress
  ingress_with_source_security_group_id = [
    {
      from_port                = 5432
      to_port                  = 5432
      protocol                 = "tcp"
      description              = "PostgreSQL access from EKS nodes"
      source_security_group_id = element(var.allowed_security_groups, 0)
    },
  ]

  # If there is more than one allowed SG, we might need a dynamic block or multiple rules.
  # For simplicity, assuming the first one is the node group SG.

  tags = var.tags
}
