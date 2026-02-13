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

Si la app **rhbk** se queda en "waiting for healthy state of /Service/postgres-db", Argo CD está esperando que el Service se marque Healthy. Por defecto, los Services tipo LoadBalancer solo son Healthy cuando tienen `loadBalancer.ingress`; nuestro Service es ClusterIP/headless.

**Solución inmediata (parche manual del ConfigMap):** aplicar la customización de salud en el cluster:

```bash
# Bash / Git Bash:
oc -n openshift-gitops patch cm argocd-cm --type merge -p '{"data":{"resource.customizations.health._Service":"hs = {}\nhs.status = \"Healthy\"\nhs.message = \"Service exists\"\nreturn hs"}}'
```

En PowerShell, usar un archivo para evitar problemas con comillas (crear `service-health-patch.json` con el contenido `{"data":{"resource.customizations.health._Service":"hs = {}\nhs.status = \"Healthy\"\nhs.message = \"Service exists\"\nreturn hs"}}` y luego `oc -n openshift-gitops patch cm argocd-cm --type merge -p (Get-Content service-health-patch.json -Raw)`).

Luego reiniciar el application controller para que recargue la configuración:

```bash
oc -n openshift-gitops rollout restart deployment openshift-gitops-application-controller
```

**Solución GitOps:** el patch `patches/argocd-instance-patch.yaml` ya incluye `resourceHealthChecks` y `extraConfig` para Service. Si tras sincronizar la app **openshift-gitops** el `argocd-cm` no muestra la clave, el ArgoCD CR puede no estar siendo parcheado por esta app (comprobar que el CR incluye `spec.resourceHealthChecks` o `spec.extraConfig`).

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

