# helmless/google-cloudrun-action

![Version](https://img.shields.io/github/v/release/helmless/google-cloudrun-action)
![License](https://img.shields.io/github/license/helmless/google-cloudrun-action)

The [helmless/google-cloudrun-action](https://github.com/helmless/google-cloudrun-action) is a GitHub Action to template and deploy applications to Google Cloud Run in a single step. This streamlined action follows a "golden path" approach for ease of use, while providing just enough flexibility for common use cases.

For advanced customization, you can use the individual actions directly: [helmless/template-action](https://github.com/helmless/template-action) and [helmless/google-cloudrun-deploy-action](https://github.com/helmless/google-cloudrun-deploy-action).

## Prerequisites

- A Google Cloud Platform account with appropriate permissions
- Credentials for Google Cloud (typically provided via [google-github-actions/auth](https://github.com/google-github-actions/auth))
- Your values file must include a `project` label to identify the GCP project

<!-- x-release-please-start-version -->
<!-- action-docs-usage action="action.yaml" project="helmless/google-cloudrun-action" version="v0.1.0" -->
### Usage

```yaml
- uses: helmless/google-cloudrun-action@v0.1.0
  with:
    # Chart configuration
    chart: oci://ghcr.io/helmless/google-cloudrun-service
    # Helm chart to use for templating
    #
    # Required: false
    # Default: oci://ghcr.io/helmless/google-cloudrun-service
    
    files: values.yaml
    # Glob patterns of value files to include when templating the chart
    #
    # Required: false
    # Default: values.yaml
    
    # Optional configuration
    dry_run: false
    # If true, only validate the configuration without deploying
    #
    # Required: false
    # Default: false
```
<!-- action-docs-usage action="action.yaml" project="helmless/google-cloudrun-action" version="v0.1.0" -->
<!-- x-release-please-end -->

<!-- action-docs-inputs source="action.yaml" -->
### Inputs

| name | description | required | default |
| --- | --- | --- | --- |
| `chart` | <p>Helm chart to use for templating. Defaults to the Google Cloud Run chart.</p> | `false` | `oci://ghcr.io/helmless/google-cloudrun-service` |
| `chart_version` | <p>Version of the Helm chart to use.</p> | `false` | `latest` |
| `files` | <p>Glob patterns of value files to include when templating the chart.</p> | `false` | `values.yaml` |
| `dry_run` | <p>If true, only validate the configuration without deploying.</p> | `false` | `false` |
<!-- action-docs-inputs source="action.yaml" -->

<!-- action-docs-outputs source="action.yaml" -->
### Outputs

| name | description |
| --- | --- |
| `manifests_deployed` | <p>The number of manifests that were deployed.</p> |
| `workloads` | <p>JSON array of all deployed Cloud Run workloads with their details (name, type, region, project).</p> |
<!-- action-docs-outputs source="action.yaml" -->

## How It Works

This action performs two key operations in sequence:

1. **Template Generation**: Uses [helmless/action](https://github.com/helmless/template-action) to template a Helm chart into Cloud Run manifests.
2. **Individual Deployments**: Iterates through each generated manifest and deploys it to Google Cloud Run.

The manifests are always printed to the console for visibility, saved to a combined `helmless_manifest.yaml` file, and individual template files are stored in the `helmless_templates` directory.

### Required Labels

Each manifest must include the following labels in the `metadata.labels` section:

- `project`: The Google Cloud project ID to deploy to
- `cloud.googleapis.com/location`: The region to deploy to

These are automatically populated if you're using the default Google Cloud Run chart, but you must provide them in your values file.

### Multi-Manifest Support

This action supports deploying multiple related Cloud Run resources together:

- If your Helm chart generates multiple manifests (e.g., a service + job), each will be deployed separately
- Each manifest must include `kind` and `name` fields, in addition to the required labels
- Resources are deployed in alphabetical order by filename

### Using Deployment Outputs

The action returns information about all deployed workloads as a JSON array, which you can use in subsequent steps:

```yaml
- name: Deploy to Cloud Run
  id: deploy
  uses: helmless/google-cloudrun-action@v0.1.0
  with:
    files: values/production.yaml

- name: Use deployment outputs
  run: |
    # The number of manifests deployed
    echo "Deployed ${{ steps.deploy.outputs.manifests_deployed }} workload(s)"
    
    # Access the workloads array (parse with jq)
    echo '${{ steps.deploy.outputs.workloads }}' | jq -r '.[] | "Deployed \(.type) \(.name) to \(.project) in \(.region)"'
```

## Common Use Cases

### Simple Deployment

```yaml
name: Deploy to Cloud Run

on:
  push:
    branches: [ main ]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - id: auth
        uses: google-github-actions/auth@v2
        with:
          credentials_json: ${{ secrets.GCP_CREDENTIALS }}
      
      - name: Deploy to Cloud Run
        uses: helmless/google-cloudrun-action@v0.1.0
        with:
          files: values/production.yaml
```

### Example values.yaml

```yaml
# Required labels for deployment
labels:
  project: my-gcp-project-id
  cloud.googleapis.com/location: us-central1

# Service configuration
image:
  repository: gcr.io/my-project/my-app
  tag: latest
```

### Advanced Customization

For more complex scenarios, use the individual actions directly:

```yaml
- name: Template manifest
  uses: helmless/action@v1
  with:
    chart: oci://ghcr.io/helmless/google-cloudrun-service
    chart_version: '1.2.3'
    files: 'values/production.yaml'
    values: |
      image.repository=gcr.io/my-project/my-app
      image.tag=${{ github.sha }}
    output_path: my-manifest.yaml

- name: Deploy to Cloud Run
  id: deploy
  uses: helmless/google-cloudrun-deploy-action@v1
  with:
    path: my-manifest.yaml

- name: Process deployment results
  run: |
    WORKLOADS='${{ steps.deploy.outputs.workloads }}'
    echo "Deployed workloads: $WORKLOADS"
```
