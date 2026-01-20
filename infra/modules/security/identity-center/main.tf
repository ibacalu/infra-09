# AWS IAM Identity Center (SSO) Module
# Provides centralized user management across AWS accounts

# Data source to get the Identity Center instance
data "aws_ssoadmin_instances" "example" {}

locals {
  identity_store_id = tolist(data.aws_ssoadmin_instances.example.identity_store_ids)[0]
  instance_arn      = tolist(data.aws_ssoadmin_instances.example.arns)[0]
}

# Permission sets for different access levels
resource "aws_ssoadmin_permission_set" "admin_access" {
  name             = "${var.project_name}-AdminAccess"
  description      = "Full administrative access to AWS accounts"
  instance_arn     = local.instance_arn
  session_duration = "PT4H" # 4 hours

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-AdminAccess"
    Type = "PermissionSet"
  })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_ssoadmin_permission_set" "developer_access" {
  name             = "${var.project_name}-DeveloperAccess"
  description      = "Developer access with read/write permissions to development resources"
  instance_arn     = local.instance_arn
  session_duration = "PT8H" # 8 hours

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-DeveloperAccess"
    Type = "PermissionSet"
  })
}

resource "aws_ssoadmin_permission_set" "readonly_access" {
  name             = "${var.project_name}-ReadOnlyAccess"
  description      = "Read-only access to AWS resources"
  instance_arn     = local.instance_arn
  session_duration = "PT8H" # 8 hours

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-ReadOnlyAccess"
    Type = "PermissionSet"
  })
}

# Attach AWS managed policies to permission sets
resource "aws_ssoadmin_managed_policy_attachment" "admin_access_policy" {
  instance_arn       = local.instance_arn
  managed_policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
  permission_set_arn = aws_ssoadmin_permission_set.admin_access.arn
}

resource "aws_ssoadmin_managed_policy_attachment" "developer_access_policy" {
  instance_arn       = local.instance_arn
  managed_policy_arn = "arn:aws:iam::aws:policy/PowerUserAccess"
  permission_set_arn = aws_ssoadmin_permission_set.developer_access.arn
}

resource "aws_ssoadmin_managed_policy_attachment" "readonly_access_policy" {
  instance_arn       = local.instance_arn
  managed_policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
  permission_set_arn = aws_ssoadmin_permission_set.readonly_access.arn
}

# Groups for organizing users
resource "aws_identitystore_group" "administrators" {
  display_name      = "${var.project_name}-Administrators"
  description       = "Administrators with full access to all accounts"
  identity_store_id = local.identity_store_id
}

resource "aws_identitystore_group" "developers" {
  display_name      = "${var.project_name}-Developers"
  description       = "Developers with access to development and production resources"
  identity_store_id = local.identity_store_id
}

resource "aws_identitystore_group" "viewers" {
  display_name      = "${var.project_name}-Viewers"
  description       = "Users with read-only access to resources"
  identity_store_id = local.identity_store_id
}
# User Management - GitOps Style
# Users are defined in terraform.tfvars and created automatically
resource "aws_identitystore_user" "users" {
  for_each = var.users

  identity_store_id = local.identity_store_id
  display_name      = "${each.value.first_name} ${each.value.last_name}"
  user_name         = each.key

  name {
    given_name  = each.value.first_name
    family_name = each.value.last_name
  }

  emails {
    value   = each.value.email
    type    = "work"
    primary = true
  }
}

# Group lookup for dynamic membership
locals {
  group_ids = {
    "administrators" = aws_identitystore_group.administrators.group_id
    "developers"     = aws_identitystore_group.developers.group_id
    "viewers"        = aws_identitystore_group.viewers.group_id
  }

  # Flatten user-group mappings for for_each
  user_group_memberships = flatten([
    for user_key, user in var.users : [
      for group in user.groups : {
        key      = "${user_key}-${group}"
        user_key = user_key
        group    = group
      }
    ]
  ])
}

# Assign users to groups based on their configuration
resource "aws_identitystore_group_membership" "user_memberships" {
  for_each = { for m in local.user_group_memberships : m.key => m }

  identity_store_id = local.identity_store_id
  group_id          = local.group_ids[each.value.group]
  member_id         = aws_identitystore_user.users[each.value.user_key].user_id
}

# Account Assignments - Assign permission sets to AWS accounts
# Management Account assignments
resource "aws_ssoadmin_account_assignment" "management_admin" {
  instance_arn       = local.instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.admin_access.arn
  principal_id       = aws_identitystore_group.administrators.group_id
  principal_type     = "GROUP"
  target_id          = var.management_account_id
  target_type        = "AWS_ACCOUNT"
}

# Security Account assignments
resource "aws_ssoadmin_account_assignment" "security_admin" {
  instance_arn       = local.instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.admin_access.arn
  principal_id       = aws_identitystore_group.administrators.group_id
  principal_type     = "GROUP"
  target_id          = var.security_account_id
  target_type        = "AWS_ACCOUNT"
}

resource "aws_ssoadmin_account_assignment" "security_developer" {
  instance_arn       = local.instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.developer_access.arn
  principal_id       = aws_identitystore_group.developers.group_id
  principal_type     = "GROUP"
  target_id          = var.security_account_id
  target_type        = "AWS_ACCOUNT"
}

# Production Account assignments
resource "aws_ssoadmin_account_assignment" "production_admin" {
  instance_arn       = local.instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.admin_access.arn
  principal_id       = aws_identitystore_group.administrators.group_id
  principal_type     = "GROUP"
  target_id          = var.production_account_id
  target_type        = "AWS_ACCOUNT"
}

resource "aws_ssoadmin_account_assignment" "production_developer" {
  instance_arn       = local.instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.developer_access.arn
  principal_id       = aws_identitystore_group.developers.group_id
  principal_type     = "GROUP"
  target_id          = var.production_account_id
  target_type        = "AWS_ACCOUNT"
}

resource "aws_ssoadmin_account_assignment" "production_readonly" {
  instance_arn       = local.instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.readonly_access.arn
  principal_id       = aws_identitystore_group.viewers.group_id
  principal_type     = "GROUP"
  target_id          = var.production_account_id
  target_type        = "AWS_ACCOUNT"
}
