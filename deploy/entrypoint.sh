#!/bin/bash
set -e

# Environment variables with defaults for local testing
# When run from the GitHub action, these will be provided as env vars
: "${INPUT_PATH:=./charts/e2e-test/output/}"
: "${DRY_RUN:=false}"
: "${CLEANUP:=false}"
: "${SCRIPTS_DIR:=$(dirname "$0")/scripts}"

# Set a default GITHUB_OUTPUT if not in a GitHub Action environment
if [ -z "$GITHUB_ACTIONS" ]; then
  # Running locally
  : "${GITHUB_OUTPUT:=/dev/null}"
  IN_GITHUB_ACTIONS=false
else
  # Running in GitHub Actions
  IN_GITHUB_ACTIONS=true
fi

# Clean up deploy_results.json if it exists from a previous run
if [ -f deploy_results.json ]; then
  echo "🧹 Cleaning up existing deploy_results.json from previous run"
  rm deploy_results.json
fi

# First, look for Metadata manifest which will be used for all deployments
echo "🔍 Looking for Helmless Metadata manifest..."
METADATA_MANIFEST=""

# Find the first metadata file in the input path
if [ -d "$INPUT_PATH" ]; then
  # Simple find command filtering for yaml files
  find "$INPUT_PATH" -type f \( -name "*.yaml" -o -name "*.yml" \) -print0 | 
  while IFS= read -r -d '' file; do
    if grep -q "apiVersion: cloudrun.helmless.io/v1" "$file" && grep -q "kind: Metadata" "$file"; then
      METADATA_MANIFEST="$file"
      echo "✅ Found Metadata manifest: $METADATA_MANIFEST"
      break
    fi
  done
elif [ -f "$INPUT_PATH" ] && grep -q "apiVersion: cloudrun.helmless.io/v1" "$INPUT_PATH" && grep -q "kind: Metadata" "$INPUT_PATH"; then
  METADATA_MANIFEST="$INPUT_PATH"
  echo "✅ Found Metadata manifest: $METADATA_MANIFEST"
fi

# Now find Cloud Run manifests
echo "🔍 Finding Cloud Run manifests..."
MANIFESTS=$("$SCRIPTS_DIR/find-manifests.sh" "$INPUT_PATH")

# Check if we found any manifests
if [ -z "$MANIFESTS" ]; then
  echo "❌ No Cloud Run manifests found to deploy!"
  exit 1
fi

# Count how many manifests we found
MANIFEST_COUNT=$(echo "$MANIFESTS" | wc -l | tr -d ' ')
echo "📊 Found $MANIFEST_COUNT Cloud Run manifest(s) to deploy"

# Deploy each manifest and collect results
DEPLOY_RESULTS=()
for manifest in $MANIFESTS; do
  MANIFEST_NAME=$(basename "$manifest")
  echo "🚀 Deploying manifest: $MANIFEST_NAME"
  
  # Deploy the manifest and show all log output
  # We need to pass through all output while also capturing the JSON result
  # Create a temporary file to store the output
  TMP_OUTPUT=$(mktemp)
  
  # Run the deploy script and capture all output, passing the metadata manifest if found
  "$SCRIPTS_DIR/deploy-manifest.sh" "$manifest" "$DRY_RUN" "$METADATA_MANIFEST" | tee "$TMP_OUTPUT"
  exit_code=${PIPESTATUS[0]}
  
  if [ $exit_code -eq 0 ]; then
    echo "✅ Successfully deployed manifest"
    # Extract only the JSON object (which is the last line of output)
    json_result=$(tail -n 1 "$TMP_OUTPUT")
    # Verify it looks like JSON before adding it to results
    if [[ "$json_result" == *"{"* && "$json_result" == *"}"* ]]; then
      echo "$json_result" >> deploy_results.json
    else
      echo "⚠️ Failed to get valid JSON result from deployment"
    fi
  else
    echo "❌ Failed to deploy manifest"
    rm -f "$TMP_OUTPUT"
    exit 1
  fi
  
  # Clean up the temporary file
  rm -f "$TMP_OUTPUT"
done

# Process the results
if [ -f deploy_results.json ]; then
  RESULTS=$(cat deploy_results.json | "$SCRIPTS_DIR/process-results.sh")
  
  # If running in GitHub Actions, set outputs
  if [ "$IN_GITHUB_ACTIONS" = true ]; then
    echo "$RESULTS" >> $GITHUB_OUTPUT
  else
    # When running locally, just display the results
    echo "$RESULTS"
  fi
  echo "🎉 Deployment complete!"
else
  if [ "$IN_GITHUB_ACTIONS" = true ]; then
    echo "workloads=[]" >> $GITHUB_OUTPUT
    echo "deployed_count=0" >> $GITHUB_OUTPUT
  fi
  echo "⚠️ No deployments were processed"
fi

# If CLEANUP is enabled, clean up all deployed workloads
if [ "$CLEANUP" = "true" ]; then
  echo "🧹 Cleanup flag enabled. Cleaning up deployed workloads..."
  if [ -f deploy_results.json ]; then
    # Parse deploy_results.json to get details of deployed workloads
    while IFS= read -r line; do
      # We now know each line is a valid JSON object
      if [ -n "$line" ]; then
        # Extract values from the JSON - using more reliable jq if available
        if command -v jq >/dev/null 2>&1; then
          name=$(echo "$line" | jq -r '.name')
          type=$(echo "$line" | jq -r '.type')
          region=$(echo "$line" | jq -r '.region')
          project=$(echo "$line" | jq -r '.project')
        else
          # Fallback to grep method if jq is not available
          name=$(echo "$line" | grep -o '"name":"[^"]*"' | cut -d'"' -f4)
          type=$(echo "$line" | grep -o '"type":"[^"]*"' | cut -d'"' -f4)
          region=$(echo "$line" | grep -o '"region":"[^"]*"' | cut -d'"' -f4)
          project=$(echo "$line" | grep -o '"project":"[^"]*"' | cut -d'"' -f4)
        fi
        
        echo "🗑️  Deleting $type: $name in $region of project $project"
        
        # Command to delete the workload
        if [ "$type" = "service" ]; then
          gcloud run services delete "$name" --region="$region" --project="$project" --quiet
        elif [ "$type" = "job" ]; then
          gcloud run jobs delete "$name" --region="$region" --project="$project" --quiet
        else
          echo "⚠️  Unknown workload type: $type - skipping deletion"
        fi
      fi
    done < deploy_results.json
    
    echo "🧹 Cleanup complete!"
    # Remove the deploy results file after cleanup
    rm deploy_results.json
  else
    echo "⚠️ No deployment results found for cleanup"
  fi
fi

# Print summary for local runs
if [ "$IN_GITHUB_ACTIONS" = false ]; then
  echo "📝 Local run summary:"
  echo "  - Manifests deployed: $MANIFEST_COUNT"
  if [ -f deploy_results.json ]; then
    echo "  - Details available in deploy_results.json"
  fi
  if [ "$CLEANUP" = "true" ]; then
    echo "  - Cleanup: Enabled (workloads have been deleted)"
  else
    echo "  - Cleanup: Disabled (workloads are still running)"
  fi
fi 