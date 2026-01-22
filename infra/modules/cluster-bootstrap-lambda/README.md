# EKS Bootstrap Lambda

Lambda function to bootstrap EKS clusters with ArgoCD and initial configuration.

## Dependencies

- `boto3` (included in Lambda runtime)
- `pyyaml` - YAML parsing for Kubernetes manifests
- `kubernetes` - Kubernetes Python client

## Building the Package

Before running `terraform apply`, you must build the Lambda package:

```bash
cd infra/modules/cluster-bootstrap-lambda
./build.sh
```

This installs Python dependencies into `./package/` which Terraform zips and uploads.

## When to Rebuild

Run `./build.sh` again when:
- `src/handler.py` changes
- `src/requirements.txt` changes (dependency updates)

## Files

- `src/handler.py` - Lambda handler code
- `src/requirements.txt` - Python dependencies
- `package/` - Built deployment package (git-ignored)
- `build.sh` - Build script
