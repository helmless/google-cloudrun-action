#!/bin/bash

# Template the charts
helm template --dependency-update --output-dir ./charts/e2e-test/output charts/e2e-test -f charts/e2e-test/values.dev.yaml --set global.project=${1:-helmless}
