"""
EKS Cluster Bootstrap Lambda

This Lambda function bootstraps an EKS cluster with ArgoCD and initial secrets.
It uses the Python kubernetes client (no kubectl binary needed) and authenticates
via IAM (EKS Access Entries).
"""

import base64
import json
import logging
import os
import tempfile
import time
from typing import Any, Optional

import boto3
import yaml

# Import kubernetes client
from kubernetes import client as k8s_client
from kubernetes import dynamic
from kubernetes.client import Configuration, ApiClient
from kubernetes.client.rest import ApiException
from kubernetes.dynamic.exceptions import NotFoundError

logger = logging.getLogger()
logger.setLevel(logging.INFO)


class EKSAuth:
    """Handles EKS authentication using IAM."""

    TOKEN_PREFIX = "k8s-aws-v1."
    TOKEN_EXPIRATION_MINS = 14
    STS_TOKEN_EXPIRES_IN = 60

    def __init__(self, cluster_name: str, region: str):
        self.cluster_name = cluster_name
        self.region = region
        self.session = boto3.Session()

    def get_token(self) -> str:
        """Generate EKS token using standard boto3 approach."""
        from botocore.signers import RequestSigner

        client = self.session.client("sts", region_name=self.region)
        signer = RequestSigner(
            client.meta.service_model.service_id,
            self.region,
            "sts",
            "v4",
            self.session.get_credentials(),
            self.session.events,
        )

        url = signer.generate_presigned_url(
            {
                "method": "GET",
                "url": f"https://sts.{self.region}.amazonaws.com/?Action=GetCallerIdentity&Version=2011-06-15",
                "body": {},
                "headers": {"x-k8s-aws-id": self.cluster_name},
                "context": {},
            },
            expires_in=self.STS_TOKEN_EXPIRES_IN,
            operation_name="",
        )

        return self.TOKEN_PREFIX + base64.urlsafe_b64encode(url.encode()).decode().rstrip("=")


def get_cluster_info(cluster_name: str, region: str) -> dict:
    """Get EKS cluster endpoint and CA data."""
    eks = boto3.client("eks", region_name=region)
    cluster = eks.describe_cluster(name=cluster_name)["cluster"]
    return {
        "endpoint": cluster["endpoint"],
        "ca_data": cluster["certificateAuthority"]["data"],
    }


def get_secrets_from_sm(prefix: str, region: str) -> dict:
    """
    Read all secrets from Secrets Manager matching the prefix.
    Returns a dict: {"secret-name": {"key": "value", ...}, ...}
    """
    sm = boto3.client("secretsmanager", region_name=region)
    secrets = {}

    try:
        paginator = sm.get_paginator("list_secrets")
        for page in paginator.paginate(Filters=[{"Key": "name", "Values": [prefix]}]):
            for secret in page.get("SecretList", []):
                secret_name = secret["Name"]
                short_name = secret_name.replace(prefix, "").lstrip("/")

                try:
                    value = sm.get_secret_value(SecretId=secret_name)
                    secret_data = json.loads(value["SecretString"])
                    secrets[short_name] = secret_data
                except Exception as e:
                    logger.warning(f"Could not read secret {secret_name}: {e}")
    except Exception as e:
        logger.error(f"Error listing secrets with prefix {prefix}: {e}")

    return secrets


def create_k8s_client(endpoint: str, ca_data: str, token: str) -> ApiClient:
    """Create a configured Kubernetes API client."""
    # Write CA cert to temp file
    ca_cert_file = tempfile.NamedTemporaryFile(delete=False, suffix=".crt")
    ca_cert_file.write(base64.b64decode(ca_data))
    ca_cert_file.close()

    # Configure client
    config = Configuration()
    config.host = endpoint
    config.ssl_ca_cert = ca_cert_file.name
    config.api_key = {"authorization": f"Bearer {token}"}

    return ApiClient(configuration=config)


def create_namespace(api_client: ApiClient, name: str) -> bool:
    """Create a namespace if it doesn't exist."""
    v1 = k8s_client.CoreV1Api(api_client)

    try:
        v1.read_namespace(name=name)
        logger.info(f"Namespace {name} already exists")
        return True
    except ApiException as e:
        if e.status == 404:
            body = k8s_client.V1Namespace(metadata=k8s_client.V1ObjectMeta(name=name))
            try:
                v1.create_namespace(body=body)
                logger.info(f"Created namespace {name}")
                return True
            except ApiException as e:
                logger.error(f"Failed to create namespace {name}: {e}")
                return False
        else:
            logger.error(f"Error checking namespace {name}: {e}")
            return False


def create_secret(
    api_client: ApiClient,
    name: str,
    namespace: str,
    data: dict,
    labels: Optional[dict] = None,
) -> bool:
    """Create or update a Kubernetes secret."""
    v1 = k8s_client.CoreV1Api(api_client)

    body = k8s_client.V1Secret(
        metadata=k8s_client.V1ObjectMeta(
            name=name, namespace=namespace, labels=labels or {}
        ),
        string_data=data,
    )

    try:
        try:
            v1.read_namespaced_secret(name=name, namespace=namespace)
            # Secret exists, patch it
            v1.patch_namespaced_secret(name=name, namespace=namespace, body=body)
            logger.info(f"Updated secret {name} in {namespace}")
        except ApiException as e:
            if e.status == 404:
                # Create new secret
                v1.create_namespaced_secret(namespace=namespace, body=body)
                logger.info(f"Created secret {name} in {namespace}")
            else:
                raise
        return True
    except ApiException as e:
        logger.error(f"Failed to create/update secret {name}: {e}")
        return False


def create_configmap(
    api_client: ApiClient, name: str, namespace: str, data: dict
) -> bool:
    """Create or update a ConfigMap."""
    v1 = k8s_client.CoreV1Api(api_client)

    # All values must be strings
    string_data = {k: str(v) for k, v in data.items()}

    body = k8s_client.V1ConfigMap(
        metadata=k8s_client.V1ObjectMeta(name=name, namespace=namespace),
        data=string_data,
    )

    try:
        try:
            v1.read_namespaced_config_map(name=name, namespace=namespace)
            v1.patch_namespaced_config_map(name=name, namespace=namespace, body=body)
            logger.info(f"Updated configmap {name} in {namespace}")
        except ApiException as e:
            if e.status == 404:
                v1.create_namespaced_config_map(namespace=namespace, body=body)
                logger.info(f"Created configmap {name} in {namespace}")
            else:
                raise
        return True
    except ApiException as e:
        logger.error(f"Failed to create/update configmap {name}: {e}")
        return False


def apply_manifest(api_client: ApiClient, manifest: dict) -> bool:
    """Apply a generic Kubernetes manifest using dynamic client."""

    dyn_client = dynamic.DynamicClient(api_client)

    api_version = manifest.get("apiVersion", "v1")
    kind = manifest.get("kind")
    metadata = manifest.get("metadata", {})
    name = metadata.get("name")
    namespace = metadata.get("namespace")

    try:
        # Get the API resource
        api = None
        # Retry discovery for CRDs that might have just been applied
        for i in range(6):
            try:
                api = dyn_client.resources.get(api_version=api_version, kind=kind)
                break
            except Exception as e:
                # If resource/kind not found, wait and retry
                if i == 5:
                    logger.warning(f"Resource {kind} ({api_version}) not found after retries: {e}")
                    raise
                logger.info(f"Waiting for {kind} CRD to be ready... ({i+1}/6)")
                time.sleep(5)
                # Re-initialize client to refresh discovery cache
                dyn_client = dynamic.DynamicClient(api_client)

        try:
            if namespace:
                api.get(name=name, namespace=namespace)
                try:
                    # Try default patch (Strategic Merge Patch for native resources)
                    api.patch(body=manifest, name=name, namespace=namespace)
                except ApiException as e:
                    if e.status == 415:
                        # Fallback to Merge Patch for Custom Resources
                        api.patch(
                            body=manifest,
                            name=name,
                            namespace=namespace,
                            content_type="application/merge-patch+json",
                        )
                    else:
                        raise
                logger.info(f"Updated {kind}/{name} in {namespace}")
            else:
                api.get(name=name)
                try:
                    # Try default patch
                    api.patch(body=manifest, name=name)
                except ApiException as e:
                    if e.status == 415:
                        # Fallback to Merge Patch
                        api.patch(
                            body=manifest,
                            name=name,
                            content_type="application/merge-patch+json",
                        )
                    else:
                        raise
                logger.info(f"Updated {kind}/{name}")
        except NotFoundError:
            if namespace:
                api.create(body=manifest, namespace=namespace)
                logger.info(f"Created {kind}/{name} in {namespace}")
            else:
                api.create(body=manifest)
                logger.info(f"Created {kind}/{name}")
        return True
    except Exception as e:
        logger.error(f"Failed to apply {kind}/{name}: {e}")
        return False


def apply_argocd_manifests(
    api_client: ApiClient,
    manifests_p0: list,
    manifests_p1: list,
    manifests_p2: list,
) -> bool:
    """
    Apply pre-rendered ArgoCD manifests in priority order.

    Args:
        api_client: Configured Kubernetes API client
        manifests_p0: Priority 0 manifests (CRDs, Namespaces) - must be applied first
        manifests_p1: Priority 1 manifests (Core resources)
        manifests_p2: Priority 2 manifests (Custom Resources) - applied last

    Returns:
        True if all manifests were applied successfully
    """
    all_manifests = [
        ("p0 (CRDs/Namespaces)", manifests_p0),
        ("p1 (Core resources)", manifests_p1),
        ("p2 (Custom Resources)", manifests_p2),
    ]

    total_success = 0
    total_fail = 0

    for priority_name, manifests in all_manifests:
        if not manifests:
            logger.info(f"No {priority_name} manifests to apply")
            continue

        logger.info(f"Applying {len(manifests)} {priority_name} manifests")
        success_count = 0
        fail_count = 0

        for yaml_content in manifests:
            try:
                # Parse YAML (could be multi-document)
                for manifest in yaml.safe_load_all(yaml_content):
                    if manifest:  # Skip empty documents
                        if apply_manifest(api_client, manifest):
                            success_count += 1
                        else:
                            fail_count += 1
            except Exception as e:
                logger.error(f"Failed to parse/apply manifest: {e}")
                fail_count += 1

        logger.info(f"{priority_name}: Applied {success_count}, failed {fail_count}")
        total_success += success_count
        total_fail += fail_count

    logger.info(
        f"Total ArgoCD manifests: {total_success} applied, {total_fail} failures"
    )
    return total_fail == 0




def handler(event: dict, context: Any) -> dict:
    """
    Lambda handler for EKS cluster bootstrap.

    Expected event structure:
    {
        "cluster_name": "platform-09-main-01",
        "region": "eu-central-1",
        "secrets_prefix": "eks/platform-09-main-01/argocd/",
        "argocd_manifests_p0": [...],  # Priority 0: CRDs, Namespaces
        "argocd_manifests_p1": [...],  # Priority 1: Core resources
        "argocd_manifests_p2": [...],  # Priority 2: Custom Resources
        "argocd_config": { "repo_url": ..., "repo_path": ..., "branch": ..., "environment": ... },
        "cluster_config": { ... }
    }
    """
    logger.info(f"Bootstrap started for cluster: {event.get('cluster_name')}")

    cluster_name = event["cluster_name"]
    region = event.get("region", os.environ.get("AWS_REGION", "eu-central-1"))
    secrets_prefix = event.get("secrets_prefix", f"eks/{cluster_name}/argocd/")
    argocd_manifests_p0 = event.get("argocd_manifests_p0", [])
    argocd_manifests_p1 = event.get("argocd_manifests_p1", [])
    argocd_manifests_p2 = event.get("argocd_manifests_p2", [])
    cluster_config = event.get("cluster_config", {})

    # Get cluster info and authenticate
    logger.info(f"Getting cluster info for {cluster_name}")
    cluster_info = get_cluster_info(cluster_name, region)

    logger.info("Generating EKS token")
    auth = EKSAuth(cluster_name, region)
    token = auth.get_token()

    # Create K8s client
    api_client = create_k8s_client(
        cluster_info["endpoint"], cluster_info["ca_data"], token
    )

    results = {"success": True, "steps": []}

    try:
        # Step 1: Create argocd namespace
        logger.info("Creating argocd namespace")
        if create_namespace(api_client, "argocd"):
            results["steps"].append({"namespace": "created"})

        # Step 2: Install ArgoCD (from pre-rendered manifests in priority order)
        has_manifests = (
            argocd_manifests_p0 or argocd_manifests_p1 or argocd_manifests_p2
        )
        if has_manifests:
            logger.info(
                "Installing ArgoCD from pre-rendered manifests (priority order)"
            )
            if apply_argocd_manifests(
                api_client,
                argocd_manifests_p0,
                argocd_manifests_p1,
                argocd_manifests_p2,
            ):
                results["steps"].append({"argocd": "installed"})
            else:
                logger.warning("ArgoCD installation had issues, continuing...")

        # Step 3: Read and create secrets from Secrets Manager
        logger.info(f"Reading secrets with prefix: {secrets_prefix}")
        secrets = get_secrets_from_sm(secrets_prefix, region)
        for secret_name, secret_data in secrets.items():
            labels = {}
            if "_labels" in secret_data:
                try:
                    labels = json.loads(secret_data.pop("_labels"))
                except:
                    pass

            logger.info(f"Creating secret: {secret_name}")
            if create_secret(api_client, secret_name, "argocd", secret_data, labels):
                results["steps"].append({f"secret_{secret_name}": "created"})

        # Step 4: Create cluster-config ConfigMap
        if cluster_config:
            logger.info("Creating cluster-config ConfigMap")
            if create_configmap(api_client, "cluster-config", "argocd", cluster_config):
                results["steps"].append({"configmap_cluster_config": "created"})


        logger.info(f"Bootstrap completed: {results}")
        return results

    except Exception as e:
        logger.error(f"Bootstrap failed: {e}")
        results["success"] = False
        results["error"] = str(e)
        return results

    finally:
        api_client.close()
