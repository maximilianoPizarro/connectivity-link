# Connectivity Link — demo & GitOps overview

<div align="center">
  <img src="https://maximilianopizarro.github.com/connectivity-link/rhcl-overview.png" width="900"/>
</div>

This repository contains a demo of Connectivity Link using a GitOps workflow. It shows how applications and infrastructure are declared as Kubernetes/Helm manifests and managed with ArgoCD (OpenShift GitOps). Authentication for the demo is provided by Keycloak.

Quick overview
- Connectivity Link: a set of configurations and examples demonstrating connectivity between components (services, gateways, and authentication) within an OpenShift cluster in a GitOps context.
- OpenShift GitOps (ArgoCD): used as the GitOps controller to reconcile the declared state in this repository with the cluster.

Important requirements
- OpenShift version: **4.20** (this demo and manifests are validated against this version).
- Permissions: **cluster-admin** privileges are required to install the OpenShift GitOps operator and to allow the ApplicationSet/instance to create/manage cluster-scoped objects when needed.

Getting started (single minimal manual step)
1. Install the OpenShift GitOps Operator (via OperatorHub in the OpenShift console or via OLM). This is the only manual step required before applying the manifests in this demo.
   - In the OpenShift console: Operators → OperatorHub → search for "OpenShift GitOps" → Install.
   - CLI alternative: use `oc` to install the operator with OLM if you have an appropriate catalog/package available.
2. Create the ApplicationSet / ArgoCD instance using the top-level manifest `applicationset-intance.yaml` in this repository:

```bash
oc apply -f applicationset-intance.yaml
```

- `applicationset-intance.yaml` creates/instantiates the applications defined in this repo and points them to this repository for ArgoCD to reconcile.
- After applying, open the OpenShift GitOps (ArgoCD) console to view status and sync applications if needed.

Image pattern in documentation
For centering large images in documentation and keeping visual consistency we use this HTML pattern inside Markdown:

```html
<div align="center">
  <img src="https://<your-host>/path/to/repo/docs/image.png" width="900"/>
</div>
```

Example in this repo (already included above):

```html
<div align="center">
  <img src="https://maximilianopizarro.github.com/connectivity-link/rhcl-overview.png" width="900"/>
</div>
```

Notes about image hosting
- If you use GitHub Pages or `raw.githubusercontent.com`, adjust the URL to where you serve static assets.
- Keep `width="900"` for most screenshots; adjust as required.

Installation and permissions (details)
- The OpenShift GitOps operator requires admin access to install on the cluster.
- The ApplicationSet (`applicationset-intance.yaml`) may create resources across namespaces and, depending on the applications' declarations, might need ClusterRole/ClusterRoleBinding — hence cluster-admin is recommended during initial setup.

TL;DR
- Requirements: OpenShift 4.20 + cluster-admin.
- Minimal step: install the OpenShift GitOps operator.
- Then: `oc apply -f applicationset-intance.yaml` to instantiate the demo applications.
- Outcome: ArgoCD (OpenShift GitOps) will detect and manage the resources declared in this repository.

Top-level layout (what each path represents):

- [`applicationset-intance.yaml`](applicationset-intance.yaml) — ArgoCD ApplicationSet/instance manifest that ties multiple applications together.
- [`developer-hub/README.md`](developer-hub/README.md) — Developer Hub app configuration and notes.
- developer-hub/ (ArgoCD Backstage / Developer Hub configuration)
  - [`developer-hub/app-config.yaml`](developer-hub/app-config.yaml) — Backstage application config.
  - [`developer-hub/backstage.yaml`](developer-hub/backstage.yaml) — Backstage Kubernetes manifest.
  - [`developer-hub/dynamic-plugins.yaml`](developer-hub/dynamic-plugins.yaml) — Dynamic plugin config.
  - [`developer-hub/kustomization.yaml`](developer-hub/kustomization.yaml) — Kustomize overlay for developer-hub.
  - [`developer-hub/ols-embeddings.yaml`](developer-hub/ols-embeddings.yaml) — Embeddings/ML integration config.
  - [`developer-hub/rcsconfig-onprem.yaml`](developer-hub/rcsconfig-onprem.yaml) — RCS on-prem config.
  - [`developer-hub/rcsconfig.yaml`](developer-hub/rcsconfig.yaml) — RCS cloud config.
  - [`developer-hub/rhdh-rbac-policy.yaml`](developer-hub/rhdh-rbac-policy.yaml) — RBAC policy for Developer Hub.
  - [`developer-hub/rolebinding.yaml`](developer-hub/rolebinding.yaml) — RoleBinding for the app namespace.
  - [`developer-hub/secret-secrets-rhdh.yaml`](developer-hub/secret-secrets-rhdh.yaml) — Secrets manifest for Developer Hub.
- neuralbank/ (Helm chart for the neuralbank service)
  - [`neuralbank/Chart.yaml`](neuralbank/Chart.yaml)
  - [`neuralbank/helm-values.yaml`](neuralbank/helm-values.yaml)
  - [`neuralbank/templates/`](neuralbank/templates/) — Template manifests used by the chart.
- operators/ (Helm charts for operators used in the demo)
  - [`operators/.helmignore`](operators/.helmignore)
  - [`operators/Chart.yaml`](operators/Chart.yaml)
  - [`operators/helm-values.yaml`](operators/helm-values.yaml)
  - [`operators/templates/`](operators/templates/)
  - [`operators/tests/`](operators/tests/)
- rhbk/ (Keycloak and related secrets / realm setup used for auth in the demo)
  - [`rhbk/keycloak-backstage-realm.yaml`](rhbk/keycloak-backstage-realm.yaml) — Backstage realm config for Keycloak.
  - [`rhbk/keycloak-db-secret.yaml`](rhbk/keycloak-db-secret.yaml) — DB credentials secret for Keycloak.
  - [`rhbk/keycloak-initial-admin.yaml`](rhbk/keycloak-initial-admin.yaml) — Initial admin credentials for Keycloak.
  - [`rhbk/keycloak.yaml`](rhbk/keycloak.yaml) — Keycloak operator CR that deploys Keycloak (demo config).

Notes
- The demo config uses a Keycloak operator CR ([`rhbk/keycloak.yaml`](rhbk/keycloak.yaml)) to bootstrap an instance and wire it to a Postgres DB.
- Everything in this repo is intended to be applied via a GitOps controller (ArgoCD), so changes to these files represent the desired cluster state.
