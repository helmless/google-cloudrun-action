#!/bin/bash
set -e

# This script processes a list of JSON objects and combines them into a JSON array

# Read JSON objects line by line from stdin
JSON_OBJECTS=()
while IFS= read -r line; do
  if [ -n "$line" ]; then
    JSON_OBJECTS+=("$line")
  fi
done

# Return counts and combined array
echo "deployed_count=${#JSON_OBJECTS[@]}"

# Combine objects into a JSON array
if [ ${#JSON_OBJECTS[@]} -gt 0 ]; then
  echo "workloads=[$(printf '%s,' "${JSON_OBJECTS[@]}" | sed 's/,$//')]"
else
  echo "workloads=[]"
fi 