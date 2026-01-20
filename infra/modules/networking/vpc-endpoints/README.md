# VPC Endpoints Module

Provides VPC Endpoints for private EKS clusters without NAT Gateway.

## Required Endpoints for EKS

| Endpoint | Type | Purpose |
|----------|------|---------|
| `s3` | Gateway (FREE) | ECR image layers |
| `ecr.api` | Interface | ECR API calls |
| `ecr.dkr` | Interface | Docker registry |
| `ec2` | Interface | Node provisioning |
| `sts` | Interface | IRSA/Pod Identity |
| `logs` | Interface | CloudWatch logs |

## Usage

```hcl
module "vpc_endpoints" {
  source = "../../modules/networking/vpc-endpoints"

  name            = "my-cluster"
  vpc_id          = module.vpc.vpc_id
  vpc_cidr        = "10.0.0.0/16"
  subnet_ids      = module.vpc.private_subnets
  route_table_ids = module.vpc.private_route_table_ids
}
```
