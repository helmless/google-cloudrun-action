#!/bin/bash
set -e

# Default values
CLEANUP="false"
DRY_RUN="false"
TYPE="service"
PROJECT="helmless"
# The output directory will now be relative to the chart/values directory
OUTPUT_DIR_NAME="output"

# Function to display help message
show_help() {
  echo "Usage: ./test.sh <chart_or_values_dir> [options]"
  echo ""
  echo "Arguments:"
  echo "  <chart_or_values_dir>  Path to either a Helm chart directory or a directory with values files"
  echo ""
  echo "Options:"
  echo "  --cleanup              Clean up deployed resources after testing"
  echo "  --type <service|job>   Specify workload type (default: service) for values-only testing"
  echo "  --project <name>       Specify the GCP project ID (default: helmless)"
  echo "  --dry-run              Perform a dry run of the deployment"
  echo "  --help                 Show this help message"
  echo ""
  echo "Examples:"
  echo "  ./test.sh charts/e2e-test --cleanup"
  echo "  ./test.sh charts/values-only --type job --cleanup"
  exit 0
}

# Parse arguments
if [ $# -lt 1 ]; then
  show_help
fi

CHART_OR_VALUES_DIR=$1
shift

# Parse options
while [[ $# -gt 0 ]]; do
  case $1 in
    --cleanup)
      CLEANUP="true"
      shift
      ;;
    --dry-run)
      DRY_RUN="true"
      shift
      ;;
    --type)
      if [ -z "$2" ]; then
        echo "Error: --type option requires a value (service or job)"
        exit 1
      fi
      TYPE="$2"
      if [[ "$TYPE" != "service" && "$TYPE" != "job" ]]; then
        echo "Error: --type must be either 'service' or 'job'"
        exit 1
      fi
      shift 2
      ;;
    --project)
      if [ -z "$2" ]; then
        echo "Error: --project option requires a value"
        exit 1
      fi
      PROJECT="$2"
      shift 2
      ;;
    --help)
      show_help
      ;;
    *)
      echo "Unknown option: $1"
      show_help
      ;;
  esac
done

# Normalize chart or values directory path (remove trailing slash)
CHART_OR_VALUES_DIR=${CHART_OR_VALUES_DIR%/}

# Create the output directory relative to the chart/values directory
OUTPUT_DIR="$CHART_OR_VALUES_DIR/$OUTPUT_DIR_NAME"

echo "🔍 Testing configuration:"
echo "  - Chart/Values directory: $CHART_OR_VALUES_DIR"
echo "  - Workload type: $TYPE"
echo "  - Project: $PROJECT"
echo "  - Cleanup after testing: $CLEANUP"
echo "  - Dry run: $DRY_RUN"
echo "  - Output directory: $OUTPUT_DIR"

# Create output directory if it doesn't exist
mkdir -p "$OUTPUT_DIR"

# Check if the directory is a chart (contains Chart.yaml) or values-only
if [ -f "$CHART_OR_VALUES_DIR/Chart.yaml" ]; then
  echo "📦 Found Chart.yaml - treating as a Helm chart"
  
  # Get values files from the chart directory
  VALUES_FILES=""
  for values_file in "$CHART_OR_VALUES_DIR"/values*.yaml; do
    if [ -f "$values_file" ]; then
      if [ -z "$VALUES_FILES" ]; then
        VALUES_FILES="-f $values_file"
      else
        VALUES_FILES="$VALUES_FILES -f $values_file"
      fi
    fi
  done
  
  echo "🔄 Templating chart..."
  # Template the chart using helm
  eval "helm template --dependency-update --output-dir $OUTPUT_DIR $CHART_OR_VALUES_DIR $VALUES_FILES --set global.project=$PROJECT"
  
  # Set the input path for the deployment script
  INPUT_PATH="$OUTPUT_DIR"
else
  echo "📝 No Chart.yaml found - treating as values-only directory"
  
  # Get values files from the values directory
  VALUES_FILES=""
  for values_file in "$CHART_OR_VALUES_DIR"/values*.yaml; do
    if [ -f "$values_file" ]; then
      if [ -z "$VALUES_FILES" ]; then
        VALUES_FILES="-f $values_file"
      else
        VALUES_FILES="$VALUES_FILES -f $values_file"
      fi
    fi
  done
  
  if [ -z "$VALUES_FILES" ]; then
    echo "❌ No values files found in $CHART_OR_VALUES_DIR"
    exit 1
  fi
  
  # Determine which chart to use based on the type
  if [ "$TYPE" = "service" ]; then
    CHART="oci://ghcr.io/helmless/google-cloudrun-service"
  else
    CHART="oci://ghcr.io/helmless/google-cloudrun-job"
  fi
  
  echo "🔄 Templating values with $CHART..."
  # Template the values using helm
  eval "helm template --dependency-update --output-dir $OUTPUT_DIR $CHART $VALUES_FILES --set global.project=$PROJECT"
  
  # Set the input path for the deployment script
  INPUT_PATH="$OUTPUT_DIR"
fi

echo "🚀 Running deployment script..."
# Run the deployment script with the path to the deploy directory
DEPLOY_DIR=$(dirname "$0")/deploy
INPUT_PATH="$INPUT_PATH" DRY_RUN=$DRY_RUN CLEANUP=$CLEANUP $DEPLOY_DIR/entrypoint.sh

# Clean up temporary files
if [ "$CLEANUP" = "true" ]; then
  echo "🧹 Cleaning up temporary files..."
  rm -rf "$OUTPUT_DIR"
else
  echo "📂 Templates available at: $OUTPUT_DIR"
fi

echo "✅ Test completed!" 