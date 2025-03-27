#!/bin/bash
set -e

# This script deploys a single Cloud Run manifest file

MANIFEST_PATH="$1"
DRY_RUN="$2"

# Validate manifest is a supported Cloud Run resource type
MANIFEST_API_VERSION=$(yq eval '.apiVersion' "$MANIFEST_PATH")
MANIFEST_KIND=$(yq eval '.kind' "$MANIFEST_PATH")

# Check for valid Cloud Run resource types
if [[ "$MANIFEST_API_VERSION" == "serving.knative.dev/v1" && "$MANIFEST_KIND" == "Service" ]]; then
  echo "✅ Valid Cloud Run Service manifest detected"
  WORKLOAD_TYPE="service"
elif [[ "$MANIFEST_API_VERSION" == "run.googleapis.com/v1" && "$MANIFEST_KIND" == "Job" ]]; then
  echo "✅ Valid Cloud Run Job manifest detected"
  WORKLOAD_TYPE="job"
else
  echo "❌ Invalid manifest type. Skipping deployment for $MANIFEST_PATH"
  echo "   - apiVersion: $MANIFEST_API_VERSION, kind: $MANIFEST_KIND"
  exit 0
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

# Setup dry run options
DRY_RUN_FLAG=""
if [ "$DRY_RUN" = "true" ]; then
  if [ "$WORKLOAD_TYPE" = "service" ]; then
    # Dry run is supported for services
    DRY_RUN_FLAG="--dry-run"
    echo "🔍 Performing dry run for service"
  else
    # Dry run is not supported for jobs
    echo "⚠️ Dry run is not supported for Cloud Run jobs - validation only"
    # Validate the manifest but don't deploy
    yq eval '.' "$MANIFEST_PATH" > /dev/null
    echo "{\"name\":\"$NAME\",\"type\":\"$TYPE\",\"region\":\"$REGION\",\"project\":\"$PROJECT\"}"
    exit 0
  fi
fi

# Deploy to Cloud Run
gcloud run ${TYPE}s replace "$MANIFEST_PATH" \
  --region=$REGION \
  --project=$PROJECT $DRY_RUN_FLAG
  
# Return workload details as JSON
echo "{\"name\":\"$NAME\",\"type\":\"$TYPE\",\"region\":\"$REGION\",\"project\":\"$PROJECT\"}" 