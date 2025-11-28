# Workshop Pipelines

This directory contains the configuration for deploying the workshop-pipelines Helm chart from the external Helm repository.

## Helm Repository

The chart is sourced from:
```
https://maximilianopizarro.github.io/workshop-pipelines/
```

## Configuration

The `values.yaml` file in this directory contains custom values that override the default chart values. Modify this file to customize the deployment according to your needs.

## Usage

This application is managed by ArgoCD through the ApplicationSet defined in `applicationset-instance.yaml`. The ApplicationSet is configured to:

- Use the Helm repository: `https://maximilianopizarro.github.io/workshop-pipelines/`
- Deploy the chart specified in the ApplicationSet configuration (default: `workshop-pipelines`)
- Apply custom values from `values.yaml` in this directory using `additionalSources` feature

**Note:** The ApplicationSet uses `additionalSources` to reference the `values.yaml` file from the Git repository. This requires ArgoCD 2.6+ or OpenShift GitOps 1.9+. If you're using an older version, you may need to:
- Use inline values in the ApplicationSet template, or
- Create a separate Application resource instead of using ApplicationSet

## Local Testing

To test the chart locally with these values:

```bash
helm repo add workshop-pipelines https://maximilianopizarro.github.io/workshop-pipelines/
helm repo update
helm install workshop-pipelines workshop-pipelines/<chart-name> -f values.yaml --namespace <namespace>
```

Replace `<chart-name>` with the actual chart name from the repository and `<namespace>` with your target namespace.

