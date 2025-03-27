#!/bin/bash
set -e

# This script deploys a single Cloud Run manifest file

MANIFEST_PATH="$1"
DRY_RUN="$2"
METADATA_PATH="$3"  # Optional path to metadata file

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

# Extract NAME from the manifest - this is always in the manifest
NAME=$(yq eval '.metadata.name' "$MANIFEST_PATH")

# Check if we're using a metadata file
if [ -n "$METADATA_PATH" ] && [ -f "$METADATA_PATH" ]; then
  # Check if it's a valid metadata file
  METADATA_API=$(yq eval '.apiVersion' "$METADATA_PATH")
  METADATA_KIND=$(yq eval '.kind' "$METADATA_PATH")
  
  if [[ "$METADATA_API" == "cloudrun.helmless.io/v1" && "$METADATA_KIND" == "Metadata" ]]; then
    echo "🔍 Found Helmless Metadata file, using its values"
    
    # Extract values from the metadata file
    PROJECT=$(yq eval '.spec.project' "$METADATA_PATH")
    REGION=$(yq eval '.spec.region' "$METADATA_PATH")
    
    echo "🏢 Project from metadata: $PROJECT"
    echo "🌎 Region from metadata: $REGION"
  else
    echo "⚠️ Provided metadata file is not valid. It should have apiVersion: cloudrun.helmless.io/v1, kind: Metadata"
    # Fall back to extracting from manifest
    REGION=$(yq eval '.metadata.labels["cloud.googleapis.com/location"]' "$MANIFEST_PATH")
    PROJECT=$(yq eval '.metadata.labels["project"]' "$MANIFEST_PATH")
  fi
else
  # Extract from manifest labels as before
  REGION=$(yq eval '.metadata.labels["cloud.googleapis.com/location"]' "$MANIFEST_PATH")
  PROJECT=$(yq eval '.metadata.labels["project"]' "$MANIFEST_PATH")
fi

TYPE=$(yq eval '.kind' "$MANIFEST_PATH" | tr '[:upper:]' '[:lower:]')

# Verify required fields
if [ -z "$PROJECT" ]; then
  echo "❌ No project found in metadata or manifest labels. Ensure either:"
  echo "   - Your metadata file has a valid spec.project field"
  echo "   - Your manifest has a 'project' label"
  exit 1
fi

if [ -z "$REGION" ]; then
  echo "❌ No region found in metadata or manifest labels. Ensure either:"
  echo "   - Your metadata file has a valid spec.region field"
  echo "   - Your manifest has a 'cloud.googleapis.com/location' label"
  exit 1
fi

if [ -z "$NAME" ]; then
  echo "❌ No name found in manifest. Ensure your manifest has a valid metadata.name field."
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