#!/bin/bash
set -e

# This script finds all Cloud Run manifests in a given path (file or directory)
# and outputs a newline-separated list of manifest paths
# It excludes Metadata manifests (apiVersion: cloudrun.helmless.io/v1, kind: Metadata)

INPUT_PATH="$1"

is_cloud_run_manifest() {
  local file="$1"
  # Use grep to check if this is a Cloud Run manifest
  if (grep -q "apiVersion: serving.knative.dev/v1" "$file" && grep -q "kind: Service" "$file") || \
     (grep -q "apiVersion: run.googleapis.com/v1" "$file" && grep -q "kind: Job" "$file"); then
    return 0 # true
  else
    return 1 # false
  fi
}

is_metadata_manifest() {
  local file="$1"
  # Use grep to check if this is a Metadata manifest
  if grep -q "apiVersion: cloudrun.helmless.io/v1" "$file" && grep -q "kind: Metadata" "$file"; then
    return 0 # true
  else
    return 1 # false
  fi
}

if [ -d "$INPUT_PATH" ]; then
  # It's a directory, find all YAML files
  find "$INPUT_PATH" -type f \( -name "*.yaml" -o -name "*.yml" \) -print0 | sort -z | 
  while IFS= read -r -d '' file; do
    # Skip Metadata manifests, only output Cloud Run manifests
    if ! is_metadata_manifest "$file" && is_cloud_run_manifest "$file"; then
      echo "$file"
    fi
  done
elif [ -f "$INPUT_PATH" ]; then
  # It's a single file
  if ! is_metadata_manifest "$INPUT_PATH" && is_cloud_run_manifest "$INPUT_PATH"; then
    echo "$INPUT_PATH"
  fi
else
  echo "Error: Path $INPUT_PATH is not a file or directory" >&2
  exit 1
fi 