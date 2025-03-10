#!/bin/bash
set -e

# This script deploys a single Cloud Run manifest file

MANIFEST_PATH="$1"
DRY_RUN="$2"

# Setup dry run flag
DRY_RUN_FLAG=""
if [ "$DRY_RUN" = "true" ]; then
  DRY_RUN_FLAG="--dry-run"
fi

# Extract required information from manifest
REGION=$(yq eval '.metadata.labels["cloud.googleapis.com/location"]' "$MANIFEST_PATH")
NAME=$(yq eval '.metadata.name' "$MANIFEST_PATH")
TYPE=$(yq eval '.kind' "$MANIFEST_PATH" | tr '[:upper:]' '[:lower:]')
PROJECT=$(yq eval '.metadata.labels["project"]' "$MANIFEST_PATH")

# Verify required fields
if [ -z "$PROJECT" ]; then
  echo "❌ No project label found in manifest. Ensure your values file sets project in the labels."
  exit 1
fi

if [ -z "$REGION" ]; then
  echo "❌ No region label found. Ensure your values file sets cloud.googleapis.com/location in the labels."
  exit 1
fi

# Log deployment details
echo "🏢 Project: $PROJECT"
echo "🌎 Region: $REGION"
echo "🏷️ Workload name: $NAME"
echo "📦 Workload type: $TYPE"

# Deploy to Cloud Run
gcloud run ${TYPE}s replace "$MANIFEST_PATH" \
  --region=$REGION \
  --project=$PROJECT $DRY_RUN_FLAG
  
# Return workload details as JSON
echo "{\"name\":\"$NAME\",\"type\":\"$TYPE\",\"region\":\"$REGION\",\"project\":\"$PROJECT\"}" 