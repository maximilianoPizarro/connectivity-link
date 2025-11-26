# Connectivity Link — Demo & GitOps Overview

<link rel="icon" href="https://raw.githubusercontent.com/maximilianoPizarro/botpress-helm-chart/main/favicon-152.ico" type="image/x-icon" >
<p align="left">
<img src="https://img.shields.io/badge/redhat-CC0000?style=for-the-badge&logo=redhat&logoColor=white" alt="Redhat">
<img src="https://img.shields.io/badge/openshift-%23121011.svg?style=for-the-badge&logo=redhat&logoColor=dark" alt="OpenSHift">
<img src="https://img.shields.io/badge/argocd-0077B5?style=for-the-badge&logo=argo" alt="kubernetes">
<img src="https://img.shields.io/badge/helm-0db7ed?style=for-the-badge&logo=helm&logoColor=white" alt="Helm">
<a href="https://github.com/maximilianoPizarro/connectivity-link"><img src="https://img.shields.io/badge/GitHub-%23121011.svg?style=for-the-badge&logo=linkedin&logoColor=black" alt="github" /></a>
<a href="https://www.linkedin.com/in/maximiliano-gregorio-pizarro-consultor-it"><img src="https://img.shields.io/badge/LinkedIn-0077B5?style=for-the-badge&logo=linkedin&logoColor=white" alt="linkedin" /></a>
</p>

<div align="center">
  <img src="https://maximilianopizarro.github.io/connectivity-link/rhcl-overview.png" width="900"/>
</div>

## 🚀 Quick Start Recommendation

**For the best experience, we recommend forking this repository to your own GitHub organization or user account.** This allows you to:
- Customize configurations without affecting the original repository
- Set up your own GitOps workflows with ArgoCD pointing to your fork
- Modify cluster-specific settings (like domain names) in your own repository
- Maintain your own version control and deployment pipeline

After forking, update the repository references in `applicationset-instance.yaml` to point to your fork.

## 📋 TL;DR

- **Requirements**: OpenShift 4.20+ with cluster-admin privileges
- **Minimal step**: Install the OpenShift GitOps operator
- **Then**: `oc apply -f applicationset-instance.yaml` to instantiate the demo applications
- **Outcome**: ArgoCD (OpenShift GitOps) will detect and manage the resources declared in this repository

## 📖 Overview

This repository contains a comprehensive demo of **Connectivity Link** using a GitOps workflow. It demonstrates how applications and infrastructure are declared as Kubernetes/Helm manifests and managed with ArgoCD (OpenShift GitOps). The demo includes:

- **Service Mesh**: Istio-based service mesh for traffic management and security
- **API Gateway**: Kubernetes Gateway API implementation with Istio
- **Authentication**: Keycloak for identity and access management
- **Authorization**: Kuadrant/Authorino for OIDC-based API protection
- **Application Stack**: NeuralBank demo application (frontend, backend, database)
- **Developer Hub**: Red Hat Developer Hub (Backstage) integration

<div align="center">
  <img src="https://maximilianopizarro.github.io/connectivity-link/openshift-operator.png" width="900"/>
</div>

### Key Components

- **Connectivity Link**: A set of configurations and examples demonstrating connectivity between components (services, gateways, and authentication) within an OpenShift cluster in a GitOps context
- **OpenShift GitOps (ArgoCD)**: Used as the GitOps controller to reconcile the declared state in this repository with the cluster
- **Service Mesh Operator**: Manages the Istio service mesh control plane and data plane
- **RHCL Operator**: Red Hat Connectivity Link operator for managing connectivity policies and OIDC authentication

## ⚙️ Important Requirements

- **OpenShift version**: **4.20+** (this demo and manifests are validated against this version)
- **Permissions**: **cluster-admin** privileges are required to:
  - Install the OpenShift GitOps operator
  - Allow the ApplicationSet/instance to create/manage cluster-scoped objects
  - Install and configure service mesh operators
  - Set up RBAC for ArgoCD to manage resources across namespaces

## 🔧 Configuration: Cluster Domain Setup

**⚠️ Important**: This repository contains demo cluster domain references (`apps.cluster-lv5jx.lv5jx.sandbox2484.opentlc.com`) that must be updated to match your OpenShift cluster's base domain before deployment.

### Automatic Domain Update (In Development)

We provide a bash script to automatically replace all cluster domain references:


```bash
chmod +x update-cluster-domain.sh
./update-cluster-domain.sh <your-cluster-base-domain>
```

**Example:**
```bash
./update-cluster-domain.sh apps.your-cluster.example.com
```

The script will:
- Find all YAML files containing the demo cluster domain
- Replace them with your cluster's base domain
- Show a summary of updated files

### Manual Domain Update

If you prefer to update manually, search and replace `apps.cluster-lv5jx.lv5jx.sandbox2484.opentlc.com` with your cluster's base domain in the following locations:

- `neuralbank-stack/values.yaml` - Keycloak and application URLs
- `rhcl-operator/` - OIDC policies and route configurations
- `servicemeshoperator3/` - Gateway route hostnames
- `rhbk/` - Keycloak hostname and redirect URIs

<div align="center">
  <img src="https://maximilianopizarro.github.io/connectivity-link/replace-guid.png" width="900"/>
</div>


### Finding Your Cluster Domain

To find your OpenShift cluster's base domain:

```bash
oc get ingress.config/cluster -o jsonpath='{.spec.domain}'
```

Or check your cluster's console URL - it typically follows the pattern: `console-openshift-console.apps.<your-cluster-domain>`

## 🚀 Getting Started

### Step 1: Install OpenShift GitOps Operator

Install the OpenShift GitOps Operator (via OperatorHub in the OpenShift console or via OLM). This is the only manual step required before applying the manifests in this demo.

- **Console method**: Operators → OperatorHub → search for "OpenShift GitOps" → Install
- **CLI alternative**: Use `oc` to install the operator with OLM if you have an appropriate catalog/package available

### Step 2: Update Cluster Domain (Required)

Before proceeding, update the cluster domain references as described in the [Configuration](#-configuration-cluster-domain-setup) section above.

### Step 3: Create ApplicationSet Instance

Create the ApplicationSet / ArgoCD instance using the top-level manifest:

```bash
oc apply -f applicationset-instance.yaml
```

- `applicationset-instance.yaml` creates/instantiates the applications defined in this repo and points them to this repository for ArgoCD to reconcile
- After applying, open the OpenShift GitOps (ArgoCD) console to view status and sync applications if needed

<div align="center">
  <img src="https://maximilianopizarro.github.io/connectivity-link/openshift-gitops.png" width="900"/>
</div>


## 📁 Repository Structure

### Top-Level Files

- [`applicationset-instance.yaml`](applicationset-instance.yaml) — ArgoCD ApplicationSet/instance manifest that ties multiple applications together
- [`update-cluster-domain.sh`](update-cluster-domain.sh) — Bash script to automatically update cluster domain references

### Developer Hub (`developer-hub/`)

Red Hat Developer Hub (Backstage) configuration and manifests:

- [`developer-hub/README.md`](developer-hub/README.md) — Developer Hub app configuration and notes
- [`developer-hub/app-config.yaml`](developer-hub/app-config.yaml) — Backstage application configuration
- [`developer-hub/backstage.yaml`](developer-hub/backstage.yaml) — Backstage Kubernetes deployment manifest
- [`developer-hub/dynamic-plugins.yaml`](developer-hub/dynamic-plugins.yaml) — Dynamic plugin configuration
- [`developer-hub/kustomization.yaml`](developer-hub/kustomization.yaml) — Kustomize overlay for developer-hub
- [`developer-hub/ols-embeddings.yaml`](developer-hub/ols-embeddings.yaml) — Embeddings/ML integration configuration
- [`developer-hub/rcsconfig-onprem.yaml`](developer-hub/rcsconfig-onprem.yaml) — RCS on-premises configuration
- [`developer-hub/rcsconfig.yaml`](developer-hub/rcsconfig.yaml) — RCS cloud configuration
- [`developer-hub/rhdh-rbac-policy.yaml`](developer-hub/rhdh-rbac-policy.yaml) — RBAC policy for Developer Hub
- [`developer-hub/rolebinding.yaml`](developer-hub/rolebinding.yaml) — RoleBinding for the app namespace
- [`developer-hub/secret-secrets-rhdh.yaml`](developer-hub/secret-secrets-rhdh.yaml) — Secrets manifest for Developer Hub

### NeuralBank Stack (`neuralbank-stack/`)

Helm chart for the NeuralBank demo application (frontend, backend, database, and proxy):

- [`neuralbank-stack/Chart.yaml`](neuralbank-stack/Chart.yaml) — Helm chart metadata
- [`neuralbank-stack/values.yaml`](neuralbank-stack/values.yaml) — Helm chart default values (includes Keycloak and API configuration)
- [`neuralbank-stack/templates/`](neuralbank-stack/templates/) — Kubernetes manifest templates:
  - `backend.yaml` — Backend service deployment
  - `db-deployment.yaml` — PostgreSQL database deployment
  - `db-resources.yaml` — Database persistent volume and service
  - `frontend.yaml` — Frontend application deployment
  - `neuralbank-config.yaml` — ConfigMap with runtime configuration (Keycloak URLs, API endpoints)
  - `proxy.yaml` — Nginx reverse proxy/gateway configuration
  - `route.yaml` — OpenShift Route for external access
  - `sa-default.yaml` — Service account definitions
  - `rolebinding.yaml` — RBAC bindings
  - `scc-rolebinding.yaml` — Security context constraints

### Operators (`operators/`)

Helm charts for operators used in the demo:

- [`operators/Chart.yaml`](operators/Chart.yaml) — Helm chart metadata
- [`operators/helm-values.yaml`](operators/helm-values.yaml) — Operator configuration values
- [`operators/templates/`](operators/templates/) — Operator subscription and configuration manifests:
  - `rhbk.yaml` — Red Hat Build of Keycloak operator subscription
  - `rhcl-operator.yaml` — Red Hat Connectivity Link operator subscription
  - `rhdh.yaml` — Red Hat Developer Hub operator subscription
  - `servicemeshoperator3.yaml` — Service Mesh Operator (Istio) subscription
  - `subscriptions.yaml` — Operator subscription definitions
- [`operators/tests/`](operators/tests/) — Helm chart tests

### Red Hat Build of Keycloak (`rhbk/`)

Keycloak and related secrets/realm setup used for authentication in the demo:

- [`rhbk/keycloak-backstage-realm.yaml`](rhbk/keycloak-backstage-realm.yaml) — Backstage realm configuration for Keycloak
- [`rhbk/keycloak-db-secret.yaml`](rhbk/keycloak-db-secret.yaml) — Database credentials secret for Keycloak
- [`rhbk/keycloak-initial-admin.yaml`](rhbk/keycloak-initial-admin.yaml) — Initial admin credentials for Keycloak
- [`rhbk/keycloak.yaml`](rhbk/keycloak.yaml) — Keycloak operator CR that deploys Keycloak (demo configuration)
- [`rhbk/postgres.yaml`](rhbk/postgres.yaml) — PostgreSQL database for Keycloak
- [`rhbk/kustomization.yaml`](rhbk/kustomization.yaml) — Kustomize configuration
- [`rhbk/rolebinding.yaml`](rhbk/rolebinding.yaml) — RBAC bindings for Keycloak namespace

### RHCL Operator (`rhcl-operator/`)

Red Hat Connectivity Link operator configurations for API gateway, OIDC authentication, and authorization policies:

- [`rhcl-operator/kustomization.yaml`](rhcl-operator/kustomization.yaml) — Kustomize configuration for RHCL resources
- [`rhcl-operator/kuadrant.yaml`](rhcl-operator/kuadrant.yaml) — Kuadrant CR (manages Authorino for OIDC authentication)
- [`rhcl-operator/oidc-policy.yaml`](rhcl-operator/oidc-policy.yaml) — OIDCPolicy CR defining OIDC authentication flow (issuer, client credentials, endpoints)
- [`rhcl-operator/neuralbank-route.yaml`](rhcl-operator/neuralbank-route.yaml) — Kubernetes Gateway API HTTPRoute resources:
  - `neuralbank-api-route` — Routes `/api` and `/q` paths to backend service
  - `neuralbank-root-route` — Routes root path and static assets to frontend service
- [`rhcl-operator/neuralbank-oidc-callback.yaml`](rhcl-operator/neuralbank-oidc-callback.yaml) — HTTPRoute for OIDC callback endpoint (`/auth/callback`)
- [`rhcl-operator/keycloak-authpolicy.yaml`](rhcl-operator/keycloak-authpolicy.yaml) — AuthPolicy CR for advanced authentication rules and token handling
- [`rhcl-operator/rolebinding.yaml`](rhcl-operator/rolebinding.yaml) — RBAC bindings for ArgoCD to manage RHCL resources

**Key Features:**
- OIDC-based authentication using Keycloak as the identity provider
- API protection with Authorino (via Kuadrant)
- Gateway API HTTPRoute definitions for traffic routing
- Token-based authorization with cookie and header support

### Service Mesh Operator 3 (`servicemeshoperator3/`)

Service Mesh Operator (Istio) configurations for service mesh control plane and gateway:

- [`servicemeshoperator3/kustomization.yaml`](servicemeshoperator3/kustomization.yaml) — Kustomize configuration for service mesh resources
- [`servicemeshoperator3/smcp-controlplane.yaml`](servicemeshoperator3/smcp-controlplane.yaml) — Service Mesh Control Plane (SMCP) configuration:
  - `Istio` CR — Istio control plane deployment (version v1.27.3)
  - `IstioCNI` CR — Istio CNI plugin configuration
  - ClusterRole/ClusterRoleBinding — RBAC for ArgoCD to manage Istio resources
- [`servicemeshoperator3/gateway.yaml`](servicemeshoperator3/gateway.yaml) — Kubernetes Gateway API Gateway resource:
  - `neuralbank-gateway` — Gateway with HTTP (8080) and HTTPS (443) listeners
  - Role/RoleBinding — RBAC for ArgoCD to manage Gateway resources in istio-system namespace
- [`servicemeshoperator3/gateway-route.yaml`](servicemeshoperator3/gateway-route.yaml) — Example HTTPRoute for gateway (commented out by default)

**Key Features:**
- Istio service mesh control plane management
- Kubernetes Gateway API implementation
- Multi-protocol support (HTTP/HTTPS)
- Cross-namespace route support

### Namespaces (`namespaces/`)

- [`namespaces/namespaces.yaml`](namespaces/namespaces.yaml) — Kubernetes namespace definitions for the demo

## 📝 Notes

- The demo configuration uses a Keycloak operator CR ([`rhbk/keycloak.yaml`](rhbk/keycloak.yaml)) to bootstrap an instance and wire it to a PostgreSQL database
- Everything in this repository is intended to be applied via a GitOps controller (ArgoCD), so changes to these files represent the desired cluster state
- The service mesh and gateway configurations work together to provide:
  - Traffic management and routing
  - mTLS between services
  - OIDC authentication at the gateway level
  - API protection with fine-grained authorization policies

## 🏗️ Architecture Diagrams

### The Application Solution without Auth 🙌:

<div align="center">
  <img src="https://maximilianopizarro.github.io/connectivity-link/rhcl.png" width="900"/>
</div>

### The Application Solution with Auth 🔐 powered by Red Hat Build of Keycloak & Authorino:

<div align="center">
  <img src="https://maximilianopizarro.github.io/connectivity-link/rhcl-policy-topogy.png" width="900"/>
</div>
