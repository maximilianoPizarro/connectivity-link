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

## Usage

1. Ensure the **operators** application has synced so the Cluster Observability Operator is installed.
2. Sync the **observability** application in ArgoCD.
3. Prometheus and related resources will be created in the `observability` namespace by the COO.
4. To add dashboards or Grafana, deploy the [Grafana Operator](https://docs.openshift.com/container-platform/latest/monitoring/enabling-the-grafana-operator.html) and create a Grafana instance with Prometheus as a data source (e.g. the service exposed by the MonitoringStack).

## Links

- [Cluster Observability Operator documentation](https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/cluster_observability_operator/)
- [MonitoringStack CR reference](https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/cluster_observability_operator/#monitoring-stack-cr)
