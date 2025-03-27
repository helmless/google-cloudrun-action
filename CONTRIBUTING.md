# Contributing

We welcome contributions! Please see the [Helmless contribution guidelines](https://helmless.io/contributing) for a general overview.

This guide is specific to the `google-cloudrun-deploy-action` repository.

## Development

This is a regular composite Github Action and thus does not require any special setup, except for the pre-commit hooks.

### Prerequisites

We use [asdf](https://asdf-vm.com/) to manage the dependencies. First add the plugins:

```sh
asdf plugin add helm
asdf plugin add action-validator
asdf plugin add pre-commit
```

Then install the tools and dependencies:

```sh
asdf install
```

After that install the pre-commit hooks:

```sh
pre-commit install
```

You are now ready to make changes to the action.

### Testing

The bulk of the action is located under [`./deploy`](./deploy) and is written in Bash so it can be tested locally using a templated Helmless manifest.

For convenience, there is a script to template and test the action with a single command:

```sh
./test.sh <your-chart-or-values-directory> --cleanup --project <your-project-id>
```

This will template the chart or values directory and run the action with the templated manifests.

The `--cleanup` flag will delete the deployed resources after the test is complete.

The `--type` flag can be used to specify the type of workload to deploy, either `service` or `job`.

The `--project` flag can be used to specify the Google Cloud project to deploy to.

The `--help` flag will display the help message.

