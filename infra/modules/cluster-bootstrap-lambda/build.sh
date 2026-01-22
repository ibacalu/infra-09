#!/bin/bash
# Build the Lambda deployment package
# Run this script when handler.py or requirements.txt change

set -e
cd "$(dirname "$0")"

echo "Building Lambda package..."

# Clean and create package directory
rm -rf package
mkdir -p package

# Install dependencies (using uv if available, fallback to pip)
if command -v uv &> /dev/null; then
    uv pip install -r src/requirements.txt --target package --quiet
else
    pip install -r src/requirements.txt -t package --quiet --upgrade
fi

# Copy handler
cp src/handler.py package/

echo "Done! Package ready in ./package/"
echo "Now run 'terraform apply' from the production environment."
