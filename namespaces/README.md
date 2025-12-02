# Namespaces

This ArgoCD Application creates and manages Kubernetes namespaces for the connectivity-link demo infrastructure.

## Overview

This component defines all the namespaces required for the demo, ensuring proper isolation and organization of resources across different components.

## Architecture

Namespaces provide:
- **Resource Isolation**: Logical separation of resources
- **RBAC Boundaries**: Namespace-scoped role-based access control
- **Resource Quotas**: Namespace-level resource limits
- **Network Policies**: Network isolation between namespaces

## Configuration

### Key Configuration Files

- **`namespaces.yaml`**: Defines all namespaces for the demo including:
  - `openshift-gitops` - ArgoCD and GitOps resources
  - `developer-hub` - Developer Hub (Backstage) resources
  - `neuralbank-stack` - NeuralBank application resources
  - `rhbk-operator` - Keycloak resources
  - `workshop-pipelines` - Tekton pipeline resources
  - `openshift-devspaces` - Dev Spaces resources
  - Additional namespaces as needed

## Dependencies

- **Kubernetes Cluster**: Requires cluster-admin privileges to create namespaces
- **OpenShift GitOps**: ArgoCD for GitOps deployment

## ArgoCD Integration

This application is managed by ArgoCD:
- **Application Name**: `namespaces`
- **Namespace**: `openshift-gitops`
- **Sync Policy**: Automated with self-heal enabled
- **Source**: This Git repository (`namespaces/` path)
- **Sync Wave**: `1` (deployed first, before other applications)

## Namespace Structure

### Infrastructure Namespaces

- **`openshift-gitops`**: GitOps controller and ArgoCD resources
- **`openshift-operators`**: Operator subscriptions and resources
- **`istio-system`**: Service mesh control plane

### Application Namespaces

- **`developer-hub`**: Developer Hub (Backstage) deployment
- **`neuralbank-stack`**: NeuralBank application stack
- **`workshop-pipelines`**: Tekton pipelines and CI/CD resources
- **`openshift-devspaces`**: Dev Spaces workspaces

### Operator Namespaces

- **`rhbk-operator`**: Keycloak operator and instances
- **`kuadrant-operator`**: Kuadrant/Authorino operator
- **`rhdh-operator`**: Developer Hub operator

## Best Practices

### Namespace Organization

- Group related resources in the same namespace
- Use consistent naming conventions
- Document namespace purposes
- Apply appropriate labels and annotations

### Resource Management

- Set resource quotas where appropriate
- Use network policies for security
- Apply RBAC policies per namespace
- Monitor namespace resource usage

## Troubleshooting

### Common Issues

1. **Namespace creation fails**
   - Verify cluster-admin privileges
   - Check for existing namespaces
   - Review resource quotas
   - Check namespace finalizers

2. **Resources not deploying**
   - Verify namespace exists
   - Check namespace labels
   - Review RBAC policies
   - Check resource quotas

## Related Components

All other components depend on namespaces being created first:
- [OpenShift GitOps](../openshift-gitops/README.md) - Uses `openshift-gitops` namespace
- [Developer Hub](../developer-hub/README.md) - Uses `developer-hub` namespace
- [NeuralBank Stack](../neuralbank-stack/README.md) - Uses `neuralbank-stack` namespace

## References

- [Kubernetes Namespaces Documentation](https://kubernetes.io/docs/concepts/overview/working-with-objects/namespaces/)
- [OpenShift Projects and Namespaces](https://docs.openshift.com/container-platform/latest/applications/projects/working-with-projects.html)

