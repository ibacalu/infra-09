# Dagster Job Failure Runbook

## Alert: Dagster Job Failed

**Severity**: Critical  
**Service**: dagster  
**Team**: data-engineering

---

## Quick Diagnosis

1. **Check the Dagster UI**
   - Navigate to: https://dagster.{your-cluster-domain}/runs
   - Look for runs with status `FAILURE` (red)
   - Click on the failed run to see the error details and logs

2. **Common Failure Reasons**
   | Symptom | Likely Cause | Fix |
   |---------|--------------|-----|
   | `ImagePullBackOff` | Container image not available | Check image exists, verify registry auth |
   | `OOMKilled` | Memory limit exceeded | Increase memory limits in values.yaml |
   | Database connection error | PostgreSQL unavailable | Check `dagster-db-rw` service and CNPG cluster |
   | Timeout | Run took too long | Check data volume, optimize pipeline |

3. **Check Pod Logs**
   ```bash
   # Get celery worker pods
   kubectl get pods -n dagster -l app=dagster-celery-worker
   
   # View logs for a specific run
   kubectl logs -n dagster <pod-name> --tail=100
   ```

---

## Escalation

If the issue persists after basic troubleshooting:

1. Check if this is a one-time failure or recurring
2. Review recent code changes to `apps/dagster-pipelines`
3. Escalate to the data-engineering team via PagerDuty

---

## Related Links

- [Dagster Helm Chart Values](../../gitops/services/dagster/environments/production/values.yaml)
- [Pipeline Code](../../apps/dagster-pipelines/dagster_pipelines/definitions.py)
- [Grafana Dashboard](https://grafana.{your-cluster-domain}/d/dagster-pipeline-dash)
