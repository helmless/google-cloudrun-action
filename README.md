<a href="https://helmless.io" target="_blank">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset=".github/helmless_title.png">
    <img alt="Helmless.io - Serverless Deployments Without Compromise" src=".github/helmless_title_light.png">
  </picture>
</a>

# helmless/google-cloudrun-action

![Version](https://img.shields.io/github/v/release/helmless/google-cloudrun-action)
![License](https://img.shields.io/github/license/helmless/google-cloudrun-action)

The [helmless/google-cloudrun-action](https://github.com/helmless/google-cloudrun-action) is a GitHub Action to template and deploy Helmless Helm charts to Google Cloud Run in a single step. This streamlined action follows a "golden path" approach for ease of use, while providing just enough flexibility for common use cases.

For advanced customization, you can use the individual actions directly: [helmless/template-action](https://github.com/helmless/template-action) and [helmless/google-cloudrun-action/deploy](https://github.com/helmless/google-cloudrun-action/tree/main/deploy).

## Prerequisites

- A Google Cloud Platform account with appropriate permissions
- Credentials for Google Cloud (typically provided via [google-github-actions/auth](https://github.com/google-github-actions/auth))
- Your values file must include the `project` and `region` settings to identify the GCP project and region

## Example Workflow

The following example workflow demonstrates how to deploy a Helmless Helm chart to Google Cloud Run. For more details on how to setup your workflow, see the [Helmless Documentation](https://helmless.io/docs/cloudrun/ci-cd).

<!-- x-release-please-start-version -->
```yaml
name: 🚀 Deploy to Google Cloud Run

on:
  workflow_dispatch:
  push:
    branches:
      - main
  pull_request:
    branches:
      - main

jobs:
  deploy:
    name: 🚀 Deploy
    runs-on: ubuntu-latest
    permissions:
      contents: read
      id-token: write
    steps:
      - name: 📥 Checkout Repository
        uses: actions/checkout@v4

      - name: 🔑 Google Auth
        id: auth
        uses: google-github-actions/auth@v2
        with:
          # See the Helmless Documentation for more information on how to setup a Workload Identity Provider
          # https://helmless.io/docs/cloudrun/ci-cd/#workload-identity-federation
          workload_identity_provider: "projects/YOUR_PROJECT_ID/locations/global/workloadIdentityPools/YOUR_WORKLOAD_IDENTITY_POOL/providers/github"

      - name: 🚀 Deploy Workload with Custom Chart
        uses: helmless/google-cloudrun-action@v0.2.1
        with:
          # Replace this with the path to your Helm chart using the Helmless Helm chart as dependency
          chart: './charts/e2e-test'
          # The values files are merged in order with the values.yaml file in the chart
          # The last file wins if there are conflicts
          files: |
            ./charts/values-only/values.dev.yaml
          # If true, the final manifest will be checked against the Cloud Run API
          # without actually deploying.
          dry_run: false
      
      - name: 🚀 Deploy Helmless Default Chart
        uses: helmless/google-cloudrun-action@v0.2.1
        with:
          # As a convenience you can set the type to "service" or "job"
          # and the chart will be set automatically.
          type: service
          # In this case you need to provide all values files you want to use.
          files: |
            ./charts/values-only/values.yaml
            ./charts/values-only/values.dev.yaml
```
<!-- x-release-please-end -->

<!-- x-release-please-start-version -->
<!-- action-docs-usage action="action.yaml" project="helmless/google-cloudrun-action" version="v0.2.1" -->
### Usage

```yaml
- uses: helmless/google-cloudrun-action@v0.1.0
  with:
    chart:
    # Helm chart to use for templating. Defaults to the Google Cloud Run chart.
    #
    # Required: false
    # Default: oci://ghcr.io/helmless/google-cloudrun-service

    chart_version:
    # Version of the Helm chart to use.
    #
    # Required: false
    # Default: latest

    files:
    # Glob patterns of value files to include when templating the chart.
    #
    # Required: false
    # Default: values.yaml

    template_only:
    # If true, only template the chart without deploying. Will also skip dry_run validation.
    #
    # Required: false
    # Default: false

    dry_run:
    # If true, only validate the configuration without deploying.
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
| `template_only` | <p>If true, only template the chart without deploying. Will also skip dry_run validation.</p> | `false` | `false` |
| `dry_run` | <p>If true, only validate the configuration without deploying.</p> | `false` | `false` |
<!-- action-docs-inputs source="action.yaml" -->

<!-- action-docs-outputs source="action.yaml" -->
### Outputs

| name | description |
| --- | --- |
| `manifests_deployed` | <p>The number of manifests that were deployed.</p> |
| `workloads` | <p>JSON array of all deployed Cloud Run workloads with their details (name, type, region, project).</p> |
<!-- action-docs-outputs source="action.yaml" -->

### Using Deployment Outputs

The action returns information about all deployed workloads as a JSON array, which you can use in subsequent steps:
<!-- x-release-please-start-version -->
```yaml
- name: Deploy to Cloud Run
  id: deploy
  uses: helmless/google-cloudrun-action@v0.2.1
  with:
    files: values/production.yaml

- name: Use deployment outputs
  run: |
    # The number of manifests deployed
    echo "Deployed ${{ steps.deploy.outputs.manifests_deployed }} workload(s)"
    
    # Access the workloads array (parse with jq)
    echo '${{ steps.deploy.outputs.workloads }}' | jq -r '.[] | "Deployed \(.type) \(.name) to \(.project) in \(.region)"'
```
<!-- x-release-please-end -->

## 🤝🏻 Contributing

We welcome contributions! Please see the [Contributing Guide](CONTRIBUTING.md) for more information and the general [Helmless contribution guidelines](https://helmless.io/contributing).

## 📝 License

This project is licensed under the [MIT License](LICENSE). See the [LICENSE](LICENSE) file for details.