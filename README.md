# helmless/google-cloudrun-deploy-action

![Version](https://img.shields.io/github/v/release/helmless/google-cloudrun-deploy-action)
![License](https://img.shields.io/github/license/helmless/google-cloudrun-deploy-action)

The [helmless/google-cloudrun-deploy-action](https://github.com/helmless/google-cloudrun-deploy-action) is a GitHub Action to deploy a serverless manifest to Google Cloud Run.

You need to supply a rendered manifest, for example using the [helmless/template-action](https://github.com/helmless/template-action) before to deploy the manifest.

## Prerequisites

<!-- x-release-please-start-version -->
<!-- action-docs-usage action="action.yaml" project="helmless/google-cloudrun-deploy-action" version="v0.1.0" -->
### Usage

```yaml
- uses: helmless/google-cloudrun-deploy-action@v0.1.0
  with:
    manifest_path:
    # The path to the rendered Helmless Google Cloud Run manifest. Use the helmless/action to template the manifest.
    #
    # Required: false
    # Default: helmless_manifest.yaml

    gcp_project:
    # Google Cloud project ID to deploy to.
    #
    # Required: true
    # Default: ""

    dry_run:
    # If true, only validate the configuration without deploying.
    #
    # Required: false
    # Default: false
```
<!-- action-docs-usage action="action.yaml" project="helmless/google-cloudrun-deploy-action" version="v0.1.0" -->
<!-- x-release-please-end -->

<!-- action-docs-inputs source="action.yaml" -->
### Inputs

| name | description | required | default |
| --- | --- | --- | --- |
| `manifest_path` | <p>The path to the rendered Helmless Google Cloud Run manifest. Use the helmless/action to template the manifest.</p> | `false` | `helmless_manifest.yaml` |
| `gcp_project` | <p>Google Cloud project ID to deploy to.</p> | `true` | `""` |
| `dry_run` | <p>If true, only validate the configuration without deploying.</p> | `false` | `false` |
<!-- action-docs-inputs source="action.yaml" -->

<!-- action-docs-outputs source="action.yaml" -->
### Outputs

| name | description |
| --- | --- |
| `name` | <p>The name of the deployed Cloud Run workload.</p> |
| `type` | <p>The type of workload that was deployed. Either "service" or "job".</p> |
| `region` | <p>The region the workload was deployed to.</p> |
<!-- action-docs-outputs source="action.yaml" -->
