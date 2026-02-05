# Red Hat OpenShift Dev Spaces

This ArgoCD Application deploys Red Hat OpenShift Dev Spaces, a cloud-based development environment that provides containerized workspaces for developers.

## Overview

Dev Spaces provides:
- **Cloud-based IDE**: Browser-based development environment powered by Eclipse Che
- **Workspace Management**: Containerized workspaces that can be shared and versioned
- **Multi-language Support**: Support for various programming languages and frameworks
- **Integration**: Seamless integration with Git repositories and CI/CD pipelines

## Architecture

The Dev Spaces deployment consists of:
- **CheCluster CR**: Main custom resource that defines the Dev Spaces instance
- **DevWorkspace Operator**: Manages workspace lifecycle and resources
- **Image Puller**: Pre-pulls container images for faster workspace startup

## Configuration

### Key Configuration Files

- **`checluster.yaml`**: Main Dev Spaces configuration including:
  - Server configuration (hostname, TLS)
  - Database configuration (PostgreSQL)
  - Storage configuration
  - Git services integration
- **`devworkspace-operator-config.yaml`**: DevWorkspace Operator configuration
- **`image-puller-instance.yaml`**: Image puller configuration for pre-caching images

### CheCluster Configuration

The CheCluster custom resource defines:
- **Server**: External access URL and TLS settings
- **Database**: PostgreSQL connection (embedded or external)
- **Storage**: Persistent volume configuration for workspaces
- **Git Services**: Git provider integrations

## Dependencies

- **Dev Spaces Operator**: Required operator subscription (installed via `operators` component)
- **PostgreSQL**: Database for Dev Spaces metadata (can be embedded or external)
- **OpenShift GitOps**: ArgoCD for GitOps deployment

## ArgoCD Integration

This application is managed by ArgoCD:
- **Application Name**: `devspaces`
- **Namespace**: `openshift-devspaces`
- **Sync Policy**: Automated with self-heal enabled
- **Source**: This Git repository (`devspaces/` path)

## Access

- **Dev Spaces URL**: `https://devspaces.apps.<cluster-domain>`
- **ArgoCD Application**: Available in OpenShift GitOps console

## Workspace Management

### Creating Workspaces

Workspaces can be created from:
- Git repositories (GitHub, GitLab, Bitbucket)
- Devfile definitions
- Pre-configured workspace templates

### Workspace Types

- **Ephemeral**: Temporary workspaces that are deleted when stopped
- **Persistent**: Workspaces with persistent storage

## Troubleshooting

### Common Issues

1. **Workspace not starting**
   - Check DevWorkspace Operator logs
   - Verify image puller is working
   - Review workspace resource limits

2. **Git integration not working**
   - Verify Git provider credentials
   - Check network policies
   - Review Git service configuration

3. **Storage issues**
   - Verify persistent volume claims
   - Check storage class availability
   - Review storage quotas

## Related Components

- [Operators](../operators/README.md) - Dev Spaces operator subscription
- [OpenShift GitOps](../openshift-gitops/README.md) - GitOps controller

## References

- [Red Hat OpenShift Dev Spaces Documentation](https://access.redhat.com/documentation/en-us/red_hat_openshift_dev_spaces/)
- [Eclipse Che Documentation](https://www.eclipse.org/che/docs/)
- [DevWorkspace Operator](https://github.com/devfile/devworkspace-operator)

