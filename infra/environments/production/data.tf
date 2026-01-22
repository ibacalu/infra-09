data "terraform_remote_state" "management" {
  backend = "remote"

  config = {
    organization = "infra-09"
    workspaces = {
      name = "management"
    }
  }
}
# Find the SSO Admin role dynamically
# This handles the random suffix that AWS SSO adds to the role name
data "aws_iam_roles" "sso_admin" {
  name_regex  = "AWSReservedSSO_platform-AdminAccess_.*"
  path_prefix = "/aws-reserved/sso.amazonaws.com/"
}

data "aws_iam_roles" "sso_developer" {
  name_regex  = "AWSReservedSSO_platform-DeveloperAccess_.*"
  path_prefix = "/aws-reserved/sso.amazonaws.com/"
}

data "aws_iam_roles" "sso_readonly" {
  name_regex  = "AWSReservedSSO_platform-ReadOnlyAccess_.*"
  path_prefix = "/aws-reserved/sso.amazonaws.com/"
}
