# Red Hat Connectivity Link Operator

This ArgoCD Application deploys and configures the Red Hat Connectivity Link (RHCL) Operator, which provides API gateway, OIDC authentication, and authorization policies using Kuadrant and Authorino.

## Overview

RHCL Operator enables:
- **API Gateway**: Kubernetes Gateway API implementation for traffic routing
- **OIDC Authentication**: OpenID Connect-based authentication using Keycloak
- **Authorization Policies**: Fine-grained access control with Authorino
- **Rate Limiting**: API rate limiting and throttling policies
- **Traffic Management**: Advanced routing and load balancing

## Architecture

The RHCL configuration consists of:
- **Kuadrant CR**: Manages Authorino for authentication/authorization
- **OIDCPolicy CR**: Defines OIDC authentication flow and endpoints
- **AuthPolicy CR**: Advanced authentication rules and token handling
- **HTTPRoute Resources**: Kubernetes Gateway API routes for application traffic
- **RateLimitPolicy CR**: Rate limiting configuration

## Configuration

### Key Configuration Files

- **`kuadrant.yaml`**: Kuadrant Custom Resource that manages Authorino
- **`oidc-policy.yaml`**: OIDC Policy defining:
  - Keycloak issuer URL
  - Client credentials
  - Token endpoints
  - Authentication flow
- **`keycloak-authpolicy.yaml`**: Advanced AuthPolicy with:
  - Token validation rules
  - Cookie and header support
  - Custom authentication logic
- **`neuralbank-route.yaml`**: HTTPRoute resources:
  - `/api` and `/q` routes to backend service
  - Root path and static assets to frontend service
- **`neuralbank-oidc-callback.yaml`**: OIDC callback route (`/auth/callback`)
- **`ratelimit-policy-customers.yaml`**: Rate limiting policy for customer endpoints

### OIDC Authentication Flow

1. User requests protected resource
2. Gateway redirects to Keycloak for authentication
3. User authenticates with Keycloak
4. Keycloak returns OIDC token
5. Authorino validates token
6. Request proceeds to backend service

## Dependencies

- **RHCL Operator**: Required operator subscription (installed via `operators` component)
- **Service Mesh**: Istio Gateway for traffic routing (provided by `servicemeshoperator3`)
- **Keycloak**: OIDC identity provider (provided by `rhbk` component)
- **OpenShift GitOps**: ArgoCD for GitOps deployment

## ArgoCD Integration

This application is managed by ArgoCD:
- **Application Name**: `rhcl-operator`
- **Namespace**: `openshift-operators`
- **Sync Policy**: Automated with self-heal enabled
- **Source**: This Git repository (`rhcl-operator/` path)

## API Protection

### Protected Endpoints

- **NeuralBank API**: `/api/*` endpoints protected with OIDC
- **Query Endpoints**: `/q/*` endpoints with authentication
- **Frontend**: Root path with optional authentication

### Rate Limiting

Rate limiting policies can be applied to:
- Specific routes
- User-based limits
- IP-based limits
- Custom rate limit rules

## Troubleshooting

### Common Issues

1. **Authentication not working**
   - Verify Keycloak is accessible
   - Check OIDC policy configuration
   - Review Authorino logs
   - Verify token validation rules

2. **Routes not accessible**
   - Check HTTPRoute resources
   - Verify Gateway configuration
   - Review service mesh status
   - Check network policies

3. **Rate limiting issues**
   - Verify RateLimitPolicy CR
   - Check Authorino rate limit configuration
   - Review rate limit service logs

## Related Components

- [Keycloak](../rhbk/README.md) - OIDC identity provider
- [Service Mesh](../servicemeshoperator3/README.md) - Istio Gateway
- [NeuralBank Stack](../neuralbank-stack/README.md) - Protected application

## References

- [Red Hat Connectivity Link Documentation](https://access.redhat.com/documentation/en-us/red_hat_connectivity_link/)
- [Kuadrant Documentation](https://docs.kuadrant.io/)
- [Authorino Documentation](https://github.com/kuadrant/authorino)
- [Kubernetes Gateway API](https://gateway-api.sigs.k8s.io/)

