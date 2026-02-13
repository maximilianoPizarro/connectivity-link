# OpenShift GitOps (ArgoCD)

This ArgoCD Application configures OpenShift GitOps, which provides ArgoCD as a GitOps controller for managing Kubernetes applications and infrastructure.

## Overview

OpenShift GitOps provides:
- **GitOps Workflow**: Declarative application management using Git as the source of truth
- **Continuous Sync**: Automatic synchronization of cluster state with Git repository
- **Multi-cluster Support**: Manage applications across multiple clusters
- **Application Management**: Visual interface for application status and management
- **RBAC**: Role-based access control for fine-grained permissions

## Architecture

The OpenShift GitOps deployment consists of:
- **ArgoCD Server**: Main application server with web UI
- **Application Controller**: Reconciles application state
- **Repo Server**: Handles Git repository operations
- **Redis**: Caching and session storage
- **ConfigMaps**: Configuration and plugin settings

## Configuration

### Key Configuration Files

- **`kustomization.yaml`**: Kustomize configuration for organizing resources
- **`patches/argocd-instance-patch.yaml`**: Patches for ArgoCD instance configuration
- **`resources/admin-permissions.yaml`**: Admin permissions and RBAC configuration
- **`resources/cmp-plugin-configmap.yaml`**: ConfigMap plugin configuration

### ArgoCD Instance Configuration

The ArgoCD instance is configured with:
- **Server Configuration**: External access, TLS, and authentication
- **Controller Settings**: Sync policies and resource management
- **RBAC**: Role-based access control policies
- **Plugins**: ConfigMap and other plugin configurations

## Dependencies

- **OpenShift GitOps Operator**: Required operator (installed manually or via OLM)
- **Git Repositories**: Access to Git repositories for application sources
- **Kubernetes API**: Cluster access for application deployment

## ArgoCD Integration

This application manages itself:
- **Application Name**: `openshift-gitops`
- **Namespace**: `openshift-gitops`
- **Sync Policy**: Configured via ArgoCD instance settings
- **Source**: This Git repository (`openshift-gitops/` path)

## Application Management

### ApplicationSet

The repository uses ApplicationSet for managing multiple applications:
- **`applicationset-instance.yaml`**: Defines all applications in the demo
- **Template-based**: Uses Go templates for dynamic application generation
- **Sync Waves**: Ordered deployment using sync waves

### Application Types

Applications are categorized by type:
- **Plain**: Standard Kubernetes manifests
- **Helm**: Helm chart deployments
- **Kustomize**: Kustomize-based deployments
- **RBAC**: Role and binding resources

## Access

- **ArgoCD UI**: `https://openshift-gitops-server-openshift-gitops.apps.<cluster-domain>`
- **CLI**: `argocd` CLI tool
- **API**: REST API for programmatic access

## Troubleshooting

### Health check: Service (postgres-db / rhbk)

If the **rhbk** app is stuck on "waiting for healthy state of /Service/postgres-db", Argo CD is waiting for the Service to be marked Healthy. By default, Services of type LoadBalancer are only Healthy when they have `loadBalancer.ingress`; our Service is ClusterIP/headless.

**Immediate fix (manual ConfigMap patch):** apply the health customization in the cluster:

1. **Patch the ConfigMap** (Bash / Git Bash):

```bash
oc -n openshift-gitops patch cm argocd-cm --type merge -p '{"data":{"resource.customizations.health._Service":"hs = {}\nhs.status = \"Healthy\"\nhs.message = \"Service exists\"\nreturn hs"}}'
```

   On PowerShell, use a file to avoid quoting issues: create `service-health-patch.json` with content `{"data":{"resource.customizations.health._Service":"hs = {}\nhs.status = \"Healthy\"\nhs.message = \"Service exists\"\nreturn hs"}}`, then run `oc -n openshift-gitops patch cm argocd-cm --type merge -p (Get-Content service-health-patch.json -Raw)`.

2. **Restart the application controller** so it reloads the config (OpenShift GitOps uses a StatefulSet named `openshift-gitops-application-controller`):

```bash
oc -n openshift-gitops rollout restart statefulset openshift-gitops-application-controller
```

3. **Re-sync the rhbk app** in the Argo CD UI or CLI.

**GitOps approach:** The patch `patches/argocd-instance-patch.yaml` already includes `resourceHealthChecks` and `extraConfig` for Service. If after syncing the **openshift-gitops** app the `argocd-cm` still does not show the key, the ArgoCD CR may not be patched by this app (verify the CR has `spec.resourceHealthChecks` or `spec.extraConfig`).

### Common Issues

1. **Applications not syncing**
   - Check repository connectivity
   - Verify Git credentials
   - Review application controller logs
   - Check sync policies

2. **Repository access issues**
   - Verify repository URLs
   - Check credentials and secrets
   - Review network policies
   - Verify Git provider access

3. **Sync conflicts**
   - Review application status
   - Check for resource conflicts
   - Verify sync policies
   - Review application controller logs

## Related Components

All other components in this repository are managed by ArgoCD:
- [Developer Hub](../developer-hub/README.md)
- [NeuralBank Stack](../neuralbank-stack/README.md)
- [Keycloak](../rhbk/README.md)
- [RHCL Operator](../rhcl-operator/README.md)
- [Service Mesh](../servicemeshoperator3/README.md)

## References

- [OpenShift GitOps Documentation](https://access.redhat.com/documentation/en-us/openshift_gitops/)
- [ArgoCD Documentation](https://argo-cd.readthedocs.io/)
- [ApplicationSet Documentation](https://argocd-applicationset.readthedocs.io/)
- [GitOps Principles](https://www.gitops.tech/)

