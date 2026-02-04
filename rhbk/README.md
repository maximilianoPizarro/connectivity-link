# Red Hat Build of Keycloak

This ArgoCD Application deploys an instance of Red Hat Build of Keycloak, an open-source identity and access management solution providing OIDC, OAuth 2.0, and SAML authentication.

## Overview

Keycloak serves as the central authentication provider for the connectivity-link demo, providing:
- **OIDC Authentication**: OpenID Connect protocol support
- **OAuth 2.0**: Authorization framework
- **User Federation**: Integration with external identity providers
- **Realm Management**: Isolated authentication domains

## Architecture

The Keycloak deployment consists of:
- **Keycloak Instance**: Managed by Red Hat Build of Keycloak Operator
- **PostgreSQL Database**: Persistent storage for realm and user data
- **Realms**: Separate authentication domains:
  - `devhub` - Developer Hub authentication
  - `neuralbank` - NeuralBank application authentication

## Configuration

### Keycloak Instance

The `keycloak.yaml` file defines the Keycloak Custom Resource:
- **Instances**: Number of Keycloak pods (default: 1)
- **Database**: PostgreSQL connection configuration
- **Hostname**: External access URL
- **TLS**: SSL/TLS configuration

### Database Configuration

PostgreSQL is configured via:
- **`postgres.yaml`**: PostgreSQL deployment and service
- **`keycloak-db-secret.yaml`**: Database credentials secret

### Realm Configuration

- **`keycloak-devhub-realm.yaml`**: Developer Hub realm with OIDC clients
- **`keycloak-neuralbank-realm.yaml`**: NeuralBank application realm with:
  - **neuralbank-frontend** (public client): frontend PKCE
  - **neuralbank-backend** (bearer only): API
  - **neuralbank** (confidential): OIDCPolicy and backend; client secret is obtained by the install playbook from Keycloak once the realm is ready, then used to update `neuralbank-stack/values.yaml`, `rhcl-operator/oidc-policy.yaml`, and to patch the OIDCPolicy in-cluster.

### Initial Admin

- **`keycloak-initial-admin.yaml`**: Initial admin user credentials
- **Username**: `admin`
- **Password**: Managed via secret (see deployment)

## Dependencies

- **Red Hat Build of Keycloak Operator**: Required operator subscription
- **PostgreSQL**: Database backend
- **OpenShift GitOps**: ArgoCD for GitOps deployment

## ArgoCD Integration

This application is managed by ArgoCD:
- **Application Name**: `rhbk`
- **Namespace**: `rhbk-operator`
- **Sync Policy**: Automated with self-heal enabled
- **Source**: This Git repository (`rhbk/` path)

## Access

- **Keycloak Admin Console**: `https://rhbk.apps.<cluster-domain>/admin`
- **ArgoCD Application**: Available in OpenShift GitOps console

## Security Considerations

⚠️ **Important**: 
- Change default admin credentials in production
- Use strong passwords for database and admin users
- Enable TLS/HTTPS for all connections
- Regularly update Keycloak and PostgreSQL images
- Review and restrict network policies

## Troubleshooting

### Common Issues

1. **Keycloak not starting**
   - Check PostgreSQL connectivity
   - Verify database credentials in secret
   - Review Keycloak operator logs

2. **Realm not accessible**
   - Verify realm CR is applied
   - Check realm configuration syntax
   - Review Keycloak logs for realm errors

3. **Database connection issues**
   - Verify PostgreSQL is running
   - Check database credentials
   - Review network policies

## Related Components

- [Developer Hub](../developer-hub/README.md) - Uses Keycloak for authentication
- [NeuralBank Stack](../neuralbank-stack/README.md) - Uses Keycloak for OIDC
- [RHCL Operator](../rhcl-operator/README.md) - Uses Keycloak as OIDC provider

## References

- [Red Hat Build of Keycloak Documentation](https://access.redhat.com/documentation/en-us/red_hat_build_of_keycloak/)
- [Keycloak Documentation](https://www.keycloak.org/documentation)
- [OIDC Protocol](https://openid.net/connect/)
