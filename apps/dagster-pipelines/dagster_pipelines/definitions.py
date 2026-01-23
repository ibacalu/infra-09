"""
Dagster Pipelines - Test data pipeline

This module defines a demonstration data pipeline with:
- Assets: Data processing steps following ETL pattern
- Jobs: Runnable pipeline definitions
- Schedules: Automated daily execution
"""

import json
import random
from datetime import datetime
from typing import Any

import dagster as dg


# =============================================================================
# Assets: Define data processing steps
# =============================================================================


@dg.asset(
    description="Fetches raw data from external source (simulated)",
    metadata={"source": "external_api", "format": "json"},
)
def raw_data(context: dg.AssetExecutionContext) -> dict[str, Any]:
    """Simulate fetching data from an external API."""
    context.log.info("Fetching raw data from external source...")
    
    # Simulated data representing daily metrics
    data = {
        "timestamp": datetime.now().isoformat(),
        "records": [
            {"id": i, "value": random.randint(1, 100), "category": random.choice(["A", "B", "C"])}
            for i in range(10)
        ],
        "source": "demo_api",
    }
    
    context.log.info(f"Fetched {len(data['records'])} records")
    return data


@dg.asset(
    description="Transforms and enriches raw data",
    deps=[raw_data],
    metadata={"processing_type": "aggregation"},
)
def processed_data(context: dg.AssetExecutionContext, raw_data: dict[str, Any]) -> dict[str, Any]:
    """Process and aggregate the raw data."""
    context.log.info("Processing raw data...")
    
    records = raw_data.get("records", [])
    
    # Aggregate by category
    aggregated = {}
    for record in records:
        category = record["category"]
        if category not in aggregated:
            aggregated[category] = {"count": 0, "total_value": 0}
        aggregated[category]["count"] += 1
        aggregated[category]["total_value"] += record["value"]
    
    # Calculate averages
    for category in aggregated:
        aggregated[category]["avg_value"] = (
            aggregated[category]["total_value"] / aggregated[category]["count"]
        )
    
    result = {
        "timestamp": raw_data.get("timestamp"),
        "processed_at": datetime.now().isoformat(),
        "aggregations": aggregated,
        "total_records": len(records),
    }
    
    context.log.info(f"Processed data into {len(aggregated)} categories")
    return result


@dg.asset(
    description="Generates final data report",
    deps=[processed_data],
    metadata={"output_type": "report"},
)
def data_report(context: dg.AssetExecutionContext, processed_data: dict[str, Any]) -> str:
    """Generate a human-readable report from processed data."""
    context.log.info("Generating data report...")
    
    report_lines = [
        "=" * 50,
        "DATA PIPELINE REPORT",
        "=" * 50,
        f"Generated at: {datetime.now().isoformat()}",
        f"Source timestamp: {processed_data.get('timestamp')}",
        f"Total records processed: {processed_data.get('total_records')}",
        "",
        "Category Breakdown:",
        "-" * 30,
    ]
    
    for category, stats in processed_data.get("aggregations", {}).items():
        report_lines.append(
            f"  {category}: count={stats['count']}, avg={stats['avg_value']:.2f}"
        )
    
    report_lines.extend(["", "=" * 50, "END OF REPORT", "=" * 50])
    
    report = "\n".join(report_lines)
    context.log.info(f"Report generated:\n{report}")
    
    return report


# =============================================================================
# Jobs: Define runnable pipeline combinations
# =============================================================================

data_pipeline_job = dg.define_asset_job(
    name="data_pipeline_job",
    selection=[raw_data, processed_data, data_report],
    description="Complete data pipeline: fetch → process → report",
)


# =============================================================================
# Schedules: Automated execution
# =============================================================================

@dg.schedule(
    job=data_pipeline_job,
    cron_schedule="0 0 * * *",  # Daily at midnight
    default_status=dg.DefaultScheduleStatus.STOPPED,
)
def daily_pipeline_schedule(context: dg.ScheduleEvaluationContext):
    """Run the data pipeline daily at midnight."""
    return dg.RunRequest(
        run_key=f"daily-{context.scheduled_execution_time.strftime('%Y-%m-%d')}",
        tags={"schedule": "daily", "automated": "true"},
    )


# =============================================================================
# Definitions: Register all components
# =============================================================================

defs = dg.Definitions(
    assets=[raw_data, processed_data, data_report],
    jobs=[data_pipeline_job],
    schedules=[daily_pipeline_schedule],
)
