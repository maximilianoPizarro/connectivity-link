# Connectivity Link — demo & GitOps overview

This repository is a demo of Connectivity Link using a GitOps workflow. It shows how applications and infra are declared as Kubernetes/Helm manifests and managed by ArgoCD (or similar GitOps tools). Authentication for the demo is provided via Keycloak.

Top-level layout (what each path represents):

- [applicationset-intance.yaml](applicationset-intance.yaml) — ArgoCD ApplicationSet/instance manifest that ties multiple applications together.
- [developer-hub/README.md](developer-hub/README.md) — Developer Hub app configuration and notes.
- developer-hub/ (ArgoCD Backstage / Developer Hub configuration)
  - [developer-hub/app-config.yaml](developer-hub/app-config.yaml) — Backstage application config.
  - [developer-hub/backstage.yaml](developer-hub/backstage.yaml) — Backstage Kubernetes manifest.
  - [developer-hub/dynamic-plugins.yaml](developer-hub/dynamic-plugins.yaml) — Dynamic plugin config.
  - [developer-hub/kustomization.yaml](developer-hub/kustomization.yaml) — Kustomize overlay for developer-hub.
  - [developer-hub/ols-embeddings.yaml](developer-hub/ols-embeddings.yaml) — Embeddings/ML integration config.
  - [developer-hub/rcsconfig-onprem.yaml](developer-hub/rcsconfig-onprem.yaml) — RCS on-prem config.
  - [developer-hub/rcsconfig.yaml](developer-hub/rcsconfig.yaml) — RCS cloud config.
  - [developer-hub/rhdh-rbac-policy.yaml](developer-hub/rhdh-rbac-policy.yaml) — RBAC policy for Developer Hub.
  - [developer-hub/rolebinding.yaml](developer-hub/rolebinding.yaml) — RoleBinding for the app namespace.
  - [developer-hub/secret-secrets-rhdh.yaml](developer-hub/secret-secrets-rhdh.yaml) — Secrets manifest for Developer Hub.
- neuralbank/ (Helm chart for the neuralbank service)
  - [neuralbank/Chart.yaml](neuralbank/Chart.yaml)
  - [neuralbank/helm-values.yaml](neuralbank/helm-values.yaml)
  - [neuralbank/templates/](neuralbank/templates/) — Template manifests used by the chart.
- operators/ (Helm charts for operators used in the demo)
  - [operators/.helmignore](operators/.helmignore)
  - [operators/Chart.yaml](operators/Chart.yaml)
  - [operators/helm-values.yaml](operators/helm-values.yaml)
  - [operators/templates/](operators/templates/)
  - [operators/tests/](operators/tests/)
- rhbk/ (Keycloak and related secrets / realm setup used for auth in the demo)
  - [rhbk/keycloak-backstage-realm.yaml](rhbk/keycloak-backstage-realm.yaml) — Backstage realm config for Keycloak.
  - [rhbk/keycloak-db-secret.yaml](rhbk/keycloak-db-secret.yaml) — DB credentials secret for Keycloak.
  - [rhbk/keycloak-initial-admin.yaml](rhbk/keycloak-initial-admin.yaml) — Initial admin credentials for Keycloak.
  - [rhbk/keycloak.yaml](rhbk/keycloak.yaml) — Keycloak operator CR that deploys Keycloak (demo config).

Notes
- The demo config uses a Keycloak operator CR ([`rhbk/keycloak.yaml`](rhbk/keycloak.yaml)) to bootstrap an instance and wire it to a Postgres DB.
- Everything in this repo is intended to be applied via a GitOps controller (ArgoCD), so changes to these files represent the desired cluster state.