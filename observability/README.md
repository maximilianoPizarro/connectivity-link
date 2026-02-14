# Observability (Cluster Observability Operator)

This ArgoCD Application deploys observability resources using the **Red Hat OpenShift Cluster Observability Operator (COO)**.

## Prerequisites

- **Cluster Observability Operator** must be installed (included in `operators` Helm values). The operator runs in `openshift-cluster-observability-operator` and provides the `MonitoringStack` CRD.

## What is deployed

- **Namespace**: `observability`
- **MonitoringStack** (`connectivity-link-stack`): A monitoring stack that includes:
  - **Prometheus** for metrics collection
  - Configurable retention (default 7 days)
  - Optional: Alertmanager, Thanos Querier (can be enabled in the CR if needed)
- **ServiceMonitor** (`kuadrant`): Discovers and scrapes Kuadrant/Authorino metrics from the `istio-system` namespace so the COO Prometheus can collect them. The Kuadrant CR in `rhcl-operator/kuadrant.yaml` has `components.observability.enable: true` so the controller exposes metrics.
- **ServiceMonitor** (`litemaas-gateway-metrics`): Scrapes Envoy metrics (port 15090) for the LiteMaaS gateway so request metrics (e.g. `istio_requests_total`) are available.
- **ServiceMonitor** (`neuralbank-gateway-metrics`): Same for the Neuralbank gateway so request metrics are available for both gateways.

## Usage

1. Ensure the **operators** application has synced so the Cluster Observability Operator is installed.
2. Sync the **observability** application in ArgoCD.
3. Prometheus and related resources will be created in the `observability` namespace by the COO.
4. To add dashboards or Grafana, deploy the [Grafana Operator](https://docs.openshift.com/container-platform/latest/monitoring/enabling-the-grafana-operator.html) and create a Grafana instance with Prometheus as a data source (e.g. the service exposed by the MonitoringStack).

## Operator versions

Observability depends on the **Cluster Observability Operator (COO)**. It is installed via the `operators` application (`operators/helm-values.yaml`):

- **cluster-observability-operator**: namespace `openshift-cluster-observability-operator`, channel `stable`, source `redhat-operators`.

The `MonitoringStack` CR uses API `monitoring.rhobs/v1alpha1`. Ensure the operators app has synced so COO is installed before syncing observability.

## Troubleshooting: no request metrics

If you don't see request metrics (e.g. `istio_requests_total`) for the gateways:

1. **COO and MonitoringStack**
   - Confirm the operator is installed: `oc get csv -n openshift-cluster-observability-operator`
   - Confirm the stack exists and Prometheus is running: `oc get monitoringstack -n observability` and `oc get pods -n observability`

2. **ServiceMonitors and targets**
   - ServiceMonitors live in namespace `observability` and point at Services in `istio-system` (gateways) or Kuadrant/Authorino pods.
   - Check that the gateway Services have the label used by the ServiceMonitor, e.g. `gateway.networking.k8s.io/gateway-name=litemaas-gateway` or `neuralbank-gateway`:  
     `oc get svc -n istio-system -l gateway.networking.k8s.io/gateway-name`
   - In Prometheus (or the COO Prometheus UI), check **Status → Targets** and ensure the `observability/*` jobs show targets and are "UP".

3. **Grafana / dashboards**
   - If you use Grafana, ensure the datasource points to the Prometheus instance created by the MonitoringStack (e.g. `connectivity-link-stack-prometheus.observability.svc.cluster.local`). Request metrics will appear as `istio_requests_total` and similar when scraped from the gateway Envoy (port 15090).

## Links

- [Cluster Observability Operator documentation](https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/cluster_observability_operator/)
- [MonitoringStack CR reference](https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/cluster_observability_operator/#monitoring-stack-cr)
