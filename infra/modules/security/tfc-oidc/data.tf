# Get the TFC OIDC thumbprint
data "tls_certificate" "tfc" {
  url = "https://app.terraform.io"
}
