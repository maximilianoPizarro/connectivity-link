# Developer Hub (Red Hat Developer Hub / Backstage)

This ArgoCD Application deploys an instance of Red Hat Developer Hub (Backstage), a developer portal that provides a unified interface for discovering, managing, and documenting software components and services.

## Overview

Developer Hub is configured with:
- **Keycloak Authentication**: OIDC-based authentication using Red Hat Build of Keycloak
- **Catalog Integration**: Automatic discovery of components from GitHub repositories
- **Dynamic Plugins**: Extensible plugin system for custom functionality
- **TechDocs**: Documentation rendering and management
- **RBAC**: Role-based access control for fine-grained permissions

## Architecture

The Developer Hub deployment consists of:
- **Backend Service**: Core Backstage backend API
- **Frontend Service**: React-based user interface
- **PostgreSQL Database**: Catalog and user data storage
- **ConfigMaps**: Application configuration and plugin settings

## Configuration

### Key Configuration Files

- **`app-config.yaml`**: Main Backstage configuration including:
  - Catalog providers (GitHub, Keycloak)
  - Authentication providers (OIDC)
  - Integration settings
  - Catalog locations and autodiscovery rules
- **`backstage.yaml`**: Kubernetes deployment manifests
- **`dynamic-plugins.yaml`**: Dynamic plugin configuration
- **`ols-embeddings.yaml`**: AI/ML embeddings configuration (optional)
- **`rcsconfig.yaml`**: Remote configuration service settings

### Catalog Autodiscovery

The configuration includes autodiscovery for the `redhat-ai-dev/ai-lab-template` repository:
- Automatically discovers `catalog-info.yaml` files
- Scans the `main` branch
- Updates catalog every 30 minutes

### Authentication Flow

1. User accesses Developer Hub
2. Redirected to Keycloak for authentication
3. OIDC token exchange
4. User session established in Backstage

## Dependencies

- **Keycloak**: Required for authentication (`rhbk` component)
- **PostgreSQL**: Database for catalog and user data
- **OpenShift GitOps**: ArgoCD for GitOps deployment

## ArgoCD Integration

This application is managed by ArgoCD:
- **Application Name**: `developer-hub`
- **Namespace**: `developer-hub`
- **Sync Policy**: Automated with self-heal enabled
- **Source**: This Git repository (`developer-hub/` path)

## Access

- **Developer Hub URL**: `https://developer-hub.apps.<cluster-domain>`
- **ArgoCD Application**: Available in OpenShift GitOps console

## Troubleshooting

### Common Issues

1. **Authentication not working**
   - Verify Keycloak is running and accessible
   - Check OIDC configuration in `app-config.yaml`
   - Verify Keycloak realm configuration

2. **Catalog not updating**
   - Check GitHub integration token
   - Verify autodiscovery configuration
   - Review catalog provider logs

3. **Plugins not loading**
   - Verify dynamic plugin configuration
   - Check plugin repository accessibility
   - Review backend logs for plugin errors

## Related Components

- [Keycloak](../rhbk/README.md) - Authentication provider
- [OpenShift GitOps](../openshift-gitops/README.md) - GitOps controller

## References

- [Red Hat Developer Hub Documentation](https://access.redhat.com/documentation/en-us/red_hat_developer_hub/)
- [Backstage Documentation](https://backstage.io/docs)
- [Backstage Catalog Model](https://backstage.io/docs/features/software-catalog/descriptor-format)
