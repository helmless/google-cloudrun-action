#!/bin/bash
set -e

# This script finds all Kubernetes manifests in a given path (file or directory)
# and outputs a newline-separated list of manifest paths

INPUT_PATH="$1"

if [ -d "$INPUT_PATH" ]; then
  # It's a directory, find all YAML files
  find "$INPUT_PATH" -type f -name "*.yaml" -o -name "*.yml" | sort
elif [ -f "$INPUT_PATH" ]; then
  # It's a file, just return the file path
  echo "$INPUT_PATH"
else
  echo "Error: Path $INPUT_PATH is not a file or directory" >&2
  exit 1
fi 