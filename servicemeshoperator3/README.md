# Service Mesh Operator 3 (Istio)

This ArgoCD Application deploys and configures the Service Mesh Operator, which manages Istio-based service mesh for traffic management, security, and observability.

## Overview

The Service Mesh Operator provides:
- **Service Mesh Control Plane**: Istio control plane management
- **Kubernetes Gateway API**: Gateway implementation for traffic routing
- **mTLS**: Mutual TLS encryption between services
- **Traffic Management**: Advanced routing, load balancing, and circuit breaking
- **Observability**: Metrics, tracing, and logging integration

## Architecture

The Service Mesh deployment consists of:
- **Service Mesh Control Plane (SMCP)**: Istio control plane configuration
- **Istio Gateway**: Kubernetes Gateway API implementation
- **Istio CNI**: Container Network Interface plugin
- **Data Plane**: Sidecar proxies injected into application pods

## Configuration

### Key Configuration Files

- **`smcp-controlplane.yaml`**: Service Mesh Control Plane configuration:
  - Istio version (v1.27.3)
  - Control plane components (pilot, citadel, galley, etc.)
  - Istio CNI configuration
  - RBAC for ArgoCD management
- **`gateway.yaml`**: Kubernetes Gateway API Gateway resource:
  - `neuralbank-gateway` with HTTP (8080) and HTTPS (443) listeners
  - TLS configuration
  - Hostname configuration
- **`gateway-route.yaml`**: Example HTTPRoute (commented out by default)

### Service Mesh Control Plane

The SMCP defines:
- **Version**: Istio version to deploy
- **Components**: Control plane components and their configuration
- **CNI**: Istio CNI plugin settings
- **Network**: Network configuration and multi-cluster support

### Gateway Configuration

The Gateway resource provides:
- **Listeners**: HTTP and HTTPS listeners
- **TLS**: TLS certificate configuration
- **Hostname**: External hostname for the gateway

## Dependencies

- **Service Mesh Operator**: Required operator subscription (installed via `operators` component)
- **OpenShift GitOps**: ArgoCD for GitOps deployment
- **Network Policies**: May require network policy configuration

## ArgoCD Integration

This application is managed by ArgoCD:
- **Application Name**: `servicemeshoperator3`
- **Namespace**: `openshift-operators`
- **Sync Policy**: Automated with self-heal enabled
- **Source**: This Git repository (`servicemeshoperator3/` path)

## Traffic Management

### Features

- **Load Balancing**: Multiple load balancing algorithms
- **Circuit Breaking**: Automatic failure detection and recovery
- **Retry Logic**: Configurable retry policies
- **Timeout**: Request timeout configuration
- **Fault Injection**: Testing resilience with fault injection

### mTLS

Mutual TLS is enabled by default:
- Automatic certificate management
- Service-to-service encryption
- Certificate rotation

## Troubleshooting

### App stuck Progressing (litemaas-gateway-istio / neuralbank-gateway-istio)

Istio creates Services `*-gateway-istio` in `istio-system` for each Gateway. They are type LoadBalancer with empty `status.loadBalancer` until an external LB is provisioned, so Argo CD marks them as **Progressing** and the app can stay Progressing.

**Fix:** Configure Argo CD to treat Services as Healthy when they exist (see [OpenShift GitOps README](../openshift-gitops/README.md#health-check-service-postgres-db--rhbk)): patch `argocd-cm` with `resource.customizations.health._Service` and restart the application controller. That removes the Progressing state for these Services.

### Common Issues

1. **Control plane not starting**
   - Check operator logs
   - Verify SMCP resource status
   - Review resource quotas
   - Check Istio operator logs

2. **Gateway not accessible**
   - Verify Gateway resource
   - Check route configuration
   - Review network policies
   - Verify TLS certificates

3. **Sidecar injection not working**
   - Check namespace labels
   - Verify Istio CNI is installed
   - Review sidecar injection webhook logs
   - Check pod annotations

## Related Components

- [RHCL Operator](../rhcl-operator/README.md) - Uses Gateway for routing
- [NeuralBank Stack](../neuralbank-stack/README.md) - Applications using service mesh
- [Operators](../operators/README.md) - Service Mesh operator subscription

## References

- [Red Hat Service Mesh Documentation](https://access.redhat.com/documentation/en-us/red_hat_openshift_service_mesh/)
- [Istio Documentation](https://istio.io/latest/docs/)
- [Kubernetes Gateway API](https://gateway-api.sigs.k8s.io/)
- [Service Mesh Operator](https://github.com/maistra/istio-operator)

