variable "config" {
  description = "(Required) Module configuration"
  type = object({
    #? EKS Cluster name
    cluster_name = string,

    #? OIDC Provider ARN
    oidc_provider_arn = string,

    #? Annotations to attach to Argo workloads
    cluster_oidc_issuer_url = string,

    route53_zone_ids = list(string),

    # Feature flags
    enable_external_secrets = optional(bool, false)
  })
}
