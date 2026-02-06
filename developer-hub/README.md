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

## RBAC and Permissions

The Developer Hub uses a role-based access control (RBAC) system defined in `rhdh-rbac-policy.yaml`. Permissions are organized hierarchically with role inheritance.

### Permission Structure

#### Platform Team Role (Full Access)

The `platform-team` role provides full access to all Developer Hub components and features. The following groups inherit this role:

- **`infrastructure`** - Infrastructure management team
- **`platformengineers`** - Platform engineering team
- **`platform-team`** - Platform team (legacy group)
- **`rhdh`** - Red Hat Developer Hub team

**Full Access Permissions Include:**
- **Catalog**: Full CRUD operations on catalog entities, locations, and entity creation
- **TechDocs**: Full CRUD operations on technical documentation
- **Scaffolder**: Full access to templates, tasks, and action execution (read, write, create, update, delete)
- **Lightspeed**: Full CRUD operations on AI chat conversations
- **APIs, Resources, Systems, Domains**: Full CRUD operations
- **Groups and Users**: Full CRUD operations
- **Templates**: Full CRUD operations
- **Dynamic Plugins**: Full access including install/uninstall capabilities
- **Permission Policies**: Full CRUD operations on RBAC policies
- **Plugin Configuration**: Full CRUD operations

#### Application Team Role (Limited Access)

The `application-team` role provides limited access focused on development workflows. The following groups inherit this role:

- **`application-team`** - Application development team (legacy group)
- **`developers`** - General developers team
- **`devteam1`** - Development Team 1

**Limited Access Permissions Include:**
- **TechDocs**: Read-only access to view technical documentation
- **Scaffolder**: Read templates and execute actions (launch templates)
- **Lightspeed**: Read and create AI chat conversations

**Note**: Application Team members cannot create, update, or delete catalog entities, manage plugins, or modify RBAC policies.

#### Authenticated Users (Basic Access)

All authenticated users (logged-in users) have basic read-only permissions:

- **Catalog**: Read-only access to view catalog entities and locations
- **TechDocs**: Read-only access to view technical documentation
- **Scaffolder**: Read templates and execute actions (launch templates)
- **Lightspeed**: Read and create AI chat conversations
- **APIs, Resources, Systems, Domains, Groups, Users**: Read-only access

### Role Inheritance

Permissions are assigned through role inheritance:

```
platform-team (full access)
  ├── infrastructure
  ├── platformengineers
  ├── platform-team
  └── rhdh

application-team (limited access)
  ├── application-team
  ├── developers
  └── devteam1
```

### User Group Synchronization

User group membership is automatically synchronized from Keycloak using the `keycloakOrg` provider. Users inherit permissions based on their Keycloak group membership:

- Users in Keycloak groups (`/infrastructure`, `/platformengineers`, `/rhdh`) automatically get `platform-team` permissions
- Users in Keycloak groups (`/developers`, `/devteam1`) automatically get `application-team` permissions
- All authenticated users get basic read-only permissions

### Configuration

RBAC policies are defined in `rhdh-rbac-policy.yaml` using the Casbin policy format. The policy file is loaded as a ConfigMap and applied to the Developer Hub instance.

**Key Policy Sections:**
- Individual user permissions (e.g., `maximilianopizarro` - full admin)
- Group-based role definitions
- Role inheritance assignments
- Basic permissions for authenticated users

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

4. **Lightspeed / Llama Stack version mismatch**
   - **"Client version 0.4.3 is not compatible with server version 0.2.18"**: `lightspeed-stack:latest` uses client 0.4.3; Red Hat llama-stack has no 0.4.x image tag. **Fix:** Use `lightspeed-stack:0.2.0` (see below).
   - **"Llama Stack version <= 0.2.17 is required, but 0.2.18 is used"**: `lightspeed-stack:0.2.0` only accepts server <= 0.2.17, while `llama-stack:0.1.1` reports 0.2.18. **Fix:** Use `llama-stack:0.1.0` (reports 0.2.17). If `0.1.0` is not available or still reports 0.2.18, you may need a different lightspeed-stack image tag that allows 0.2.18; check [Quay](https://quay.io/repository/lightspeed-core/lightspeed-stack) for tags.

## Related Components

- [Keycloak](../rhbk/README.md) - Authentication provider
- [OpenShift GitOps](../openshift-gitops/README.md) - GitOps controller

## References

- [Red Hat Developer Hub Documentation](https://access.redhat.com/documentation/en-us/red_hat_developer_hub/)
- [Backstage Documentation](https://backstage.io/docs)
- [Backstage Catalog Model](https://backstage.io/docs/features/software-catalog/descriptor-format)
