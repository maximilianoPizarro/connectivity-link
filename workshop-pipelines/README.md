# Workshop Pipelines

This directory contains the configuration for deploying the workshop-pipelines Helm chart from the external Helm repository.

## Helm Repository

The chart is sourced from:
```
https://maximilianopizarro.github.io/workshop-pipelines/
```

## Structure

This directory contains:

- **`helmchartrepository.yaml`**: OpenShift HelmChartRepository resource that registers the Helm repository in the cluster
- **`role.yaml`**: ClusterRole and ClusterRoleBinding that grant ArgoCD permissions to create and manage HelmChartRepository resources
- **`values.yaml`**: Custom values file for the workshop-pipelines Helm chart (version 0.1.6)
- **`kustomization.yaml`**: Kustomize configuration to organize the resources

## Configuration

The `values.yaml` file contains the exact structure from chart version 0.1.6. You must configure the following values before deployment:

1. **Namespace**: Replace `<YOUR-NAMESPACE>` with your OpenShift namespace
2. **Pipeline Source Image**: Update the sourceImage path with your namespace
3. **Pipeline Target Image**: Configure your Quay.io username and repository
4. **Route Host**: Update with your namespace and cluster domain
5. **Quay.io Secret** (optional): Configure if you want to enable image promotion to Quay.io

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

