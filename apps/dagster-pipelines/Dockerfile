# syntax=docker/dockerfile:1
FROM docker.io/dagster/dagster-celery-k8s:1.12.12

# Install our custom code
WORKDIR /opt/dagster/app

# Copy project files
COPY pyproject.toml .
COPY dagster_pipelines/ ./dagster_pipelines/

# Install the package
RUN pip install --no-cache-dir -e .

# Set working directory for dagster
WORKDIR /opt/dagster/dagster_home

# Expose gRPC port
EXPOSE 3030
