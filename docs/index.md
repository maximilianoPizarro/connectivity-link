---
layout: default
title: Security Microservice with Connectivity Link using OpenID Connect (OIDC)
description: Zero Trust Architecture: Automate the installation with OpenShift GitOps of Connectivity Link, Service Mesh 3, Red Hat Build of Keycloak, and a full-stack application secured with Authorino (OIDC) and rate limiting on OpenShift 4.20+
---

<div align="center">
<img src="https://img.shields.io/badge/redhat-CC0000?style=for-the-badge&logo=redhat&logoColor=white" alt="Redhat" style="margin: 0 0.25rem;">
<img src="https://img.shields.io/badge/openshift-%23121011.svg?style=for-the-badge&logo=redhat&logoColor=dark" alt="OpenSHift" style="margin: 0 0.25rem;">
<img src="https://img.shields.io/badge/argocd-0077B5?style=for-the-badge&logo=argo" alt="kubernetes" style="margin: 0 0.25rem;">
<img src="https://img.shields.io/badge/helm-0db7ed?style=for-the-badge&logo=helm&logoColor=white" alt="Helm" style="margin: 0 0.25rem;">
<a href="https://github.com/maximilianoPizarro/connectivity-link"><img src="https://img.shields.io/badge/GitHub-%23121011.svg?style=for-the-badge&logo=linkedin&logoColor=black" alt="github" style="margin: 0 0.25rem;" /></a>
<a href="https://www.linkedin.com/in/maximiliano-gregorio-pizarro-consultor-it"><img src="https://img.shields.io/badge/LinkedIn-0077B5?style=for-the-badge&logo=linkedin&logoColor=white" alt="linkedin" style="margin: 0 0.25rem;" /></a>
</div>

<div align="center" style="margin: 2rem 0;">
  <iframe width="900" height="506" src="https://www.youtube.com/embed/YXOaY-pXajE" title="YouTube video player" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share" allowfullscreen style="max-width: 100%; border-radius: 4px; display: block; margin: 0 auto;"></iframe>
</div>
<div align="center" style="margin-top: 1rem; margin-bottom: 2rem;">
  <p style="font-size: 0.875rem; color: #888; font-style: italic; margin: 0;">Developed and written by Maximiliano Pizarro - Specialist Solution Architect at Red Hat LATAM</p>
</div>

## 🚀 Quick Start Recommendation

**For the best experience, we recommend forking this repository to your own GitHub organization or user account.** This allows you to:
- Customize configurations without affecting the original repository
- Set up your own GitOps workflows with ArgoCD pointing to your fork
- Modify cluster-specific settings (like domain names) in your own repository
- Maintain your own version control and deployment pipeline

<div align="center">
  <img src="{{ site.baseurl }}/rhcl-overview.png" width="900"/>
</div>

After forking, update the repository references in `applicationset-instance.yaml` to point to your fork.

## 📋 TL;DR

- **Requirements**: OpenShift 4.20+, **Python 3.11+**, **OpenShift CLI (`oc`)**, **Ansible Core**, cluster-admin privileges
- **Installation Method**: Automated via `install.sh` (updates cluster domain in all manifests, then runs Ansible playbook)
- **Quick Start**: Run `./install.sh` to install GitOps operator and deploy all applications (or run `ansible-playbook install-gitops.yaml` after updating domain references)
- **Manual Alternative**: Install OpenShift GitOps operator, update cluster domain in manifests, then `oc apply -f applicationset-instance.yaml`
- **Outcome**: ArgoCD manages all components; Connectivity Link via **dynamic console plugin** (Administration → spec.plugins); OIDC client secret obtained from Keycloak by the playbook

## 📖 Overview

<div align="center">
  <img src="{{ site.baseurl }}/openshift-operator.png" width="900"/>
</div>

This repository contains a comprehensive demo of **Connectivity Link** using a GitOps workflow. It demonstrates how applications and infrastructure are declared as Kubernetes/Helm manifests and managed with ArgoCD (OpenShift GitOps). The demo includes:

- **Service Mesh**: Istio-based service mesh for traffic management and security
- **API Gateway**: Kubernetes Gateway API implementation with Istio
- **Authentication**: Keycloak for identity and access management
- **Authorization**: Kuadrant/Authorino for OIDC-based API protection via OIDCPolicy
- **Application Stack**: NeuralBank demo application (frontend, backend, database)
- **Developer Hub**: Red Hat Developer Hub (Backstage) integration
- **Automated Installation**: Ansible playbook for complete infrastructure provisioning

### Key Components

- **Connectivity Link**: A set of configurations and examples demonstrating connectivity between components (services, gateways, and authentication) within an OpenShift cluster in a GitOps context
- **OpenShift GitOps (ArgoCD)**: Used as the GitOps controller to reconcile the declared state in this repository with the cluster
- **Service Mesh Operator**: Manages the Istio service mesh control plane and data plane
- **RHCL Operator**: Red Hat Connectivity Link operator for managing connectivity policies and OIDC authentication
- **Ansible Automation**: Automated installation playbook that ensures proper operator installation order and verification

### Architecture Overview

The architecture follows a **consolidated ApplicationSet approach** where all infrastructure components, operators, and applications are managed through a single `applicationset-instance.yaml` file. This simplifies deployment and ensures proper installation order through `sync_wave` annotations.

**Installation Order (by sync_wave):**
1. **Wave 0**: OpenShift GitOps operator installation
2. **Wave 1**: Namespaces creation
3. **Wave 2**: Operators (rhbk-operator, RBAC configurations)
4. **Wave 3**: Infrastructure components (Service Mesh, RHCL Operator, Developer Hub)
5. **Wave 4-7**: Applications (NeuralBank Stack, LiteMaaS, etc.)

## ⚙️ Important Requirements

- **OpenShift version**: **4.20+** (this demo and manifests are validated against this version)
- **Python**: **3.11+** (required for Ansible Core and collection dependencies)
- **OpenShift CLI (`oc`)**: Installed and logged in to the target cluster (`oc version`, `oc whoami`)
- **Ansible**: **Ansible Core** plus collections `kubernetes.core` and `community.kubernetes` (see [README-INSTALL.md](https://github.com/maximilianoPizarro/connectivity-link/blob/main/README-INSTALL.md))
- **Permissions**: **cluster-admin** privileges are required to install the GitOps operator, create namespaces, and let ArgoCD manage cluster resources

## 🔧 Configuration: Pre-configure DNS with ApplicationSets

**⚠️ Important**: This repository contains demo cluster domain references (`apps.cluster-kbtgl.kbtgl.sandbox4020.opentlc.com`) that must be updated to match your OpenShift cluster's base domain before deployment.

Instead of manually updating cluster domain references, you can pre-configure the DNS hostnames directly in the ApplicationSet definitions. This approach uses **Kustomize patches** and **Helm parameters** to dynamically inject your cluster domain values at deployment time.

### Automatic Domain Update

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

If you prefer to update manually, search and replace `apps.cluster-kbtgl.kbtgl.sandbox4020.opentlc.com` with your cluster's base domain in the following locations:

- `neuralbank-stack/values.yaml` - Keycloak and application URLs
- `rhcl-operator/` - OIDC policies and route configurations
- `servicemeshoperator3/` - Gateway route hostnames
- `rhbk/` - Keycloak hostname and redirect URIs

### Finding Your Cluster Domain

First, find your OpenShift cluster's base domain:

```bash
oc get ingress.config/cluster -o jsonpath='{.spec.domain}'
```

Or check your cluster's console URL - it typically follows the pattern: `console-openshift-console.apps.<your-cluster-domain>`

### Option 1: ApplicationSet with Kustomize Patches (Recommended)

This approach uses **Kustomize patches** to update DNS hostnames in Keycloak, Routes, and OIDC policies. Update the **`keycloak_host`** and **`app_host`** values in the generator elements:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: ApplicationSet
metadata:
  name: connectivity-infra-plain
  namespace: openshift-gitops
spec:
  goTemplate: true
  generators:
    - list:
        elements:
          - name: namespaces
            namespace: openshift-gitops
            path: namespaces
            sync_wave: "1"
          - name: operators
            namespace: openshift-gitops
            path: operators
            sync_wave: "2"
          - name: developer-hub
            namespace: developer-hub
            path: developer-hub
            sync_wave: "2"
          - name: servicemeshoperator3
            namespace: openshift-operators
            path: servicemeshoperator3
            sync_wave: "3"
          - name: rhcl-operator
            namespace: openshift-operators
            path: rhcl-operator
            sync_wave: "3"
  template:
    metadata:
      name: '{{.name}}'
    spec:
      project: default
      source:
        repoURL: 'https://github.com/maximilianoPizarro/connectivity-link.git'
        targetRevision: main
        path: '{{.path}}'
      destination:
        server: 'https://kubernetes.default.svc'
        namespace: '{{.namespace}}'
      syncPolicy:
        automated:
          selfHeal: true
          prune: true
        syncOptions:
          - CreateNamespace=true
---
apiVersion: argoproj.io/v1alpha1
kind: ApplicationSet
metadata:
  name: connectivity-infra-rhbk
  namespace: openshift-gitops
spec:
  goTemplate: true
  generators:
    - list:
        elements:
          - name: rhbk
            namespace: rhbk-operator
            path: rhbk
            sync_wave: "2"
            keycloak_host: rhbk.apps.cluster-24p6f.24p6f.sandbox2386.opentlc.com
            app_host: neuralbank.apps.cluster-24p6f.24p6f.sandbox2386.opentlc.com
  template:
    metadata:
      name: '{{.name}}'
    spec:
      project: default
      source:
        repoURL: 'https://github.com/maximilianoPizarro/connectivity-link.git'
        targetRevision: main
        path: '{{.path}}'
        kustomize:
          patches:
          - target:
              group: k8s.keycloak.org
              kind: Keycloak
              name: rhbk
            patch: |-
              - op: replace
                path: /spec/hostname/hostname
                value: "{{.keycloak_host}}"
          - target:
              group: k8s.keycloak.org
              kind: KeycloakRealmImport
              name: neuralbank-full-import
            patch: |-
              - op: replace
                path: /spec/realm/clients/0/redirectUris/0
                value: "https://{{.app_host}}/*"
          - target:
              group: route.openshift.io
              kind: Route
              name: neuralbank-external-route
            patch: |-
              - op: replace
                path: /spec/host
                value: "{{.app_host}}"
          - target:
              group: extensions.kuadrant.io
              kind: OIDCPolicy
              name: neuralbank-oidc
            patch: |-
              - op: replace
                path: /spec/provider/issuerURL
                value: "https://{{.keycloak_host}}/realms/neuralbank"
              - op: replace
                path: /spec/provider/authorizationEndpoint
                value: "https://{{.keycloak_host}}/realms/neuralbank/protocol/openid-connect/auth"
              - op: replace
                path: /spec/provider/tokenEndpoint
                value: "https://{{.keycloak_host}}/realms/neuralbank/protocol/openid-connect/token"
              - op: replace
                path: /spec/provider/redirectURI
                value: "https://{{.app_host}}/auth/callback"
      destination:
        server: 'https://kubernetes.default.svc'
        namespace: '{{.namespace}}'
      syncPolicy:
        automated:
          selfHeal: true
          prune: true
        syncOptions:
          - CreateNamespace=true
```

**Key Configuration Points:**
- **`keycloak_host`**: Update this value with your Keycloak hostname (e.g., `rhbk.apps.<your-cluster-domain>`)
- **`app_host`**: Update this value with your application hostname (e.g., `neuralbank.apps.<your-cluster-domain>`)
- The Kustomize patches automatically update all DNS references in Keycloak, Routes, and OIDC policies

### Option 2: ApplicationSet with Helm Parameters

For Helm-based deployments, use **Helm parameters** to inject DNS values. Update the **`keycloak_host`** and **`app_host`** values in the generator:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: ApplicationSet
metadata:
  name: connectivity-apps-helm-internal
  namespace: openshift-gitops
spec:
  goTemplate: true
  generators:
    - list:
        elements:
          - name: neuralbank-stack
            namespace: neuralbank-stack
            path: neuralbank-stack
            sync_wave: "5"
            keycloak_host: rhbk.apps.cluster-24p6f.24p6f.sandbox2386.opentlc.com
            app_host: neuralbank.apps.cluster-24p6f.24p6f.sandbox2386.opentlc.com
  template:
    metadata:
      name: '{{.name}}'
    spec:
      project: default
      source:
        repoURL: 'https://github.com/maximilianoPizarro/connectivity-link.git'
        targetRevision: main
        path: '{{.path}}'
        helm:
          parameters:
            - name: "keycloak.issuerUrl"
              value: "https://{{.keycloak_host}}/realms/neuralbank"
            - name: "keycloak.redirectUri"
              value: "https://{{.app_host}}/auth/callback"
            - name: "keycloak.authorizationEndpoint"
              value: "https://{{.keycloak_host}}/realms/neuralbank/protocol/openid-connect/auth"
            - name: "keycloak.tokenEndpoint"
              value: "https://{{.keycloak_host}}/realms/neuralbank/protocol/openid-connect/token"
            - name: "keycloak.postLogoutRedirectUri"
              value: "https://{{.app_host}}"
      destination:
        server: 'https://kubernetes.default.svc'
        namespace: '{{.namespace}}'
      syncPolicy:
        automated:
          selfHeal: true
          prune: true
        syncOptions:
          - CreateNamespace=true
```

**Key Configuration Points:**
- **`keycloak_host`**: Update this value with your Keycloak hostname
- **`app_host`**: Update this value with your application hostname
- Helm parameters automatically inject DNS values into the Helm chart values

### Option 3: External Helm Chart ApplicationSet

For external Helm charts, configure the chart repository and version:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: ApplicationSet
metadata:
  name: connectivity-apps-helm-external
  namespace: openshift-gitops
spec:
  goTemplate: true
  generators:
    - list:
        elements:
          - name: my-app
            namespace: my-namespace
            helmRepoURL: 'https://example.com/helm'
            chart: my-chart
            chartVersion: "1.0.0"
            sync_wave: "5"
  template:
    metadata:
      name: '{{.name}}'
    spec:
      project: default
      source:
        repoURL: '{{.helmRepoURL}}'
        targetRevision: '{{.chartVersion}}'
        chart: '{{.chart}}'
      destination:
        server: 'https://kubernetes.default.svc'
        namespace: '{{.namespace}}'
      syncPolicy:
        automated:
          selfHeal: true
          prune: true
        syncOptions:
          - CreateNamespace=true
```

### Benefits of Pre-configuring DNS

- **No manual file editing**: DNS values are configured once in the ApplicationSet
- **GitOps-friendly**: All configuration is version-controlled in the ApplicationSet manifests
- **Dynamic updates**: Change DNS values by updating the ApplicationSet and ArgoCD will sync automatically
- **Environment-specific**: Use different ApplicationSets for different environments (dev, staging, prod)

## 🚀 Getting Started

### Automated Installation (Recommended)

Use the **`install.sh`** script: it updates all cluster domain references and then runs the Ansible playbook.

**Prerequisites:** Python 3.11+, OpenShift CLI (`oc`), Ansible Core and collections (see [README-INSTALL.md](https://github.com/maximilianoPizarro/connectivity-link/blob/main/README-INSTALL.md)).

**Run the installation:**
```bash
chmod +x install.sh
./install.sh
```

**What `install.sh` does:** Pre-flight checks → detects cluster domain → updates domain in `applicationset-instance.yaml`, `rhbk/keycloak.yaml`, `rhbk/keycloak-neuralbank-realm.yaml`, `neuralbank-stack/values.yaml`, `rhcl-operator/oidc-policy.yaml`, `servicemeshoperator3/gateway-route.yaml` → runs `install-gitops.yaml`.

**What the playbook does:** Skips GitOps install if already available → Installs OpenShift GitOps (channel only, no version pin; Automatic) → Applies ApplicationSet → Enables **dynamic console plugins** via `spec.plugins` → Obtains OIDC client secret from Keycloak (realm `neuralbank`, client `neuralbank`) and updates values/oidc-policy and patches OIDCPolicy → Fixes operator configs (rhbk-operator, devspaces).

### Manual Installation (Alternative)

If you prefer to install manually:

### Step 1: Install OpenShift GitOps Operator

<div align="center">
  <img src="{{ site.baseurl }}/gitops.png" width="900"/>
</div>

Install the OpenShift GitOps Operator (via OperatorHub in the OpenShift console or via OLM). This is the only manual step required before applying the manifests in this demo.

- **Console method**: Operators → OperatorHub → search for "OpenShift GitOps" → Install
- **CLI alternative**: Use `oc` to install the operator with OLM if you have an appropriate catalog/package available

### Step 2: Configure DNS in ApplicationSets (Required)

Before proceeding, **pre-configure your cluster domain** in the ApplicationSet definitions as described in the [Configuration](#-configuration-pre-configure-dns-with-applicationsets) section above. Update the **`keycloak_host`** and **`app_host`** values in the ApplicationSet generators to match your OpenShift cluster domain.

### Step 3: Create ApplicationSet Instance

Create the ApplicationSet / ArgoCD instance using the top-level manifest:

```bash
oc apply -f applicationset-instance.yaml
```

- `applicationset-instance.yaml` creates/instantiates the applications defined in this repo and points them to this repository for ArgoCD to reconcile
- After applying, open the OpenShift GitOps (ArgoCD) console to view status and sync applications if needed

<div align="center">
  <img src="{{ site.baseurl }}/openshift-gitops.png" width="900"/>
</div>


### Step 4: Keycloak and OIDC (Automated or Manual)

If you use **`install.sh`** and the playbook, the realm `neuralbank` includes the client **`neuralbank`** (confidential). The playbook **obtains the client secret** from Keycloak and updates `values.yaml`, `oidc-policy.yaml`, and patches the OIDCPolicy. Commit and push the updated files so ArgoCD syncs.

**If installing manually**, configure the client in the Keycloak console after the realm is imported:

**Access Keycloak Console:**
1. Navigate to the Keycloak route (e.g. `rhbk.apps.<your-cluster-domain>`)
2. Log in with admin credentials (`rhbk/keycloak-initial-admin.yaml`)
3. Select the `neuralbank` realm

**Configure Client Settings:**

For the `neuralbank` client (or `neuralbank-frontend` if using that client):

1. **Navigate to Clients** → Select your client (e.g., `neuralbank`)
2. **Enable Client Authentication:**
   - Set **Client authentication** to **ON** (this makes it a confidential client)
   - Ensure `publicClient` is set to `false` in the configuration
3. **Enable Direct Access Grants:**
   - Enable **Direct access grants** (allows Resource Owner Password Credentials grant type)
4. **Configure PKCE:**
   - Set **Proof Key for Code Exchange Code Challenge Method** to **S256**
   - This enables PKCE (RFC 7636) for enhanced security in authorization code flows

**Generate Client Secret:**

After enabling client authentication, you need to generate and retrieve the client secret:

1. Go to the **Credentials** tab of your client
2. Copy the **Client secret** value
3. Update the `clientSecret` field in [`rhcl-operator/oidc-policy.yaml`](rhcl-operator/oidc-policy.yaml) with this value
4. Commit and push the change to your repository for ArgoCD to sync

**Note:** The client secret is required for the OIDC Policy to authenticate with Keycloak. Without it, the OIDC authentication flow will fail.

### Step 5: Create OpenShift Route for Gateway (Manual)

The Gateway API Gateway resource (`neuralbank-gateway`) needs an OpenShift Route to expose it externally. This step must be done manually from the OpenShift console or CLI.

**Option 1: Using OpenShift Console**

1. Navigate to **Networking** → **Routes** in the `istio-system` namespace
2. Click **Create Route**
3. Configure the route:
   - **Name**: `neuralbank-external-route` (or your preferred name)
   - **Hostname**: `neuralbank.apps.<your-cluster-domain>` (or use a wildcard `*.apps.<your-cluster-domain>`)
   - **Service**: Select `neuralbank-gateway-istio` service
   - **Target Port**: Select `http` (port 8080)
   - **TLS Termination**: **Edge**
   - **Insecure Traffic**: **Redirect**

**Option 2: Using CLI**

You can also create the route using `oc`:

```bash
oc create route edge neuralbank-external-route \
  --service=neuralbank-gateway-istio \
  --hostname=neuralbank.apps.<your-cluster-domain> \
  --port=http \
  --namespace=istio-system
```

**For Wildcard Route:**

If you want to use a wildcard route to access both frontend and backend through the same hostname:

```bash
oc create route edge neuralbank-external-route \
  --service=neuralbank-gateway-istio \
  --hostname="*.apps.<your-cluster-domain>" \
  --port=http \
  --namespace=istio-system
```

**Note:** The wildcard route allows you to access the application using any subdomain under `apps.<your-cluster-domain>`, which is useful for development and testing. The Gateway and HTTPRoute resources will handle the actual routing based on the `hostnames` specified in the HTTPRoute manifests.

## 📁 Repository Structure

### Top-Level Files

- [`applicationset-instance.yaml`](applicationset-instance.yaml) — ArgoCD ApplicationSet/instance manifest that ties multiple applications together
- [`update-cluster-domain.sh`](update-cluster-domain.sh) — Bash script to automatically update cluster domain references (legacy method; **recommended**: use ApplicationSets with Kustomize patches as described in [Configuration](#-configuration-pre-configure-dns-with-applicationsets))

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

#### HTTPRoute Resources

The HTTPRoute resources define how traffic is routed from the Gateway to backend services. These routes use the Kubernetes Gateway API standard and are managed by the Istio Gateway implementation.

**Structure:**
- **`parentRefs`**: References the Gateway resource (`neuralbank-gateway` in `istio-system` namespace) that will handle the traffic
- **`hostnames`**: Specifies the hostname(s) that this route will match (must match the OpenShift Route hostname)
- **`rules`**: Defines path-based routing rules:
  - **`matches`**: Path patterns to match (e.g., `/api`, `/q`, `/`)
  - **`backendRefs`**: Kubernetes Service to route matched traffic to

**Example HTTPRoute (`neuralbank-api-route`):**
```yaml
spec:
  parentRefs:
    - name: neuralbank-gateway
      namespace: istio-system
  hostnames:
    - "neuralbank.apps.<your-cluster-domain>"
  rules:
    - matches:
        - path:
            type: PathPrefix
            value: /api
      backendRefs:
        - name: neuralbank-backend-svc
          port: 8080
```

This route matches requests to `/api/*` and `/q/*` and forwards them to the `neuralbank-backend-svc` service on port 8080.

#### OIDC Policy Configuration

The OIDCPolicy resource configures OIDC authentication for protected routes. It integrates with Authorino (via Kuadrant) to enforce authentication at the gateway level.

**Key Configuration Fields:**

1. **`provider.issuerURL`**: The Keycloak realm issuer URL
   - Format: `https://<keycloak-host>/realms/<realm-name>`
   - Example: `https://rhbk.apps.<your-cluster-domain>/realms/neuralbank`

2. **`provider.clientID`**: The Keycloak client ID (must match the client configured in Keycloak)
   - Example: `neuralbank`

3. **`provider.clientSecret`**: **⚠️ IMPORTANT** — The client secret generated from Keycloak console
   - This must be obtained from Keycloak after enabling client authentication
   - Steps to get the secret:
     1. Log into Keycloak console
     2. Navigate to your realm → Clients → Select your client
     3. Go to the **Credentials** tab
     4. Copy the **Client secret** value
     5. Update the `clientSecret` field in `oidc-policy.yaml`
   - **Security Note**: Consider using a Kubernetes Secret to store the client secret instead of hardcoding it in the YAML file

4. **`provider.authorizationEndpoint`**: Keycloak authorization endpoint
   - Format: `https://<keycloak-host>/realms/<realm-name>/protocol/openid-connect/auth`

5. **`provider.redirectURI`**: OAuth callback URL (must match a redirect URI configured in Keycloak client)
   - Example: `https://neuralbank.apps.<your-cluster-domain>/auth/callback`

6. **`provider.tokenEndpoint`**: Keycloak token endpoint
   - Format: `https://<keycloak-host>/realms/<realm-name>/protocol/openid-connect/token`

7. **`targetRef`**: References the HTTPRoute resource that should be protected by this OIDC policy
   - Example: `neuralbank-api-route` (protects the `/api` and `/q` endpoints)

8. **`auth.tokenSource`**: Defines where to look for the authentication token
   - **`authorizationHeader`**: Token in `Authorization: Bearer <token>` header
   - **`cookie`**: Token stored in a cookie (e.g., `jwt` cookie)

**Example OIDC Policy:**
```yaml
spec:
  provider:
    issuerURL: "https://rhbk.apps.<your-cluster-domain>/realms/neuralbank"
    clientID: neuralbank
    clientSecret: "<your-client-secret-from-keycloak>"  # ⚠️ Update this!
    authorizationEndpoint: "https://rhbk.apps.<your-cluster-domain>/realms/neuralbank/protocol/openid-connect/auth"
    redirectURI: "https://neuralbank.apps.<your-cluster-domain>/auth/callback"
    tokenEndpoint: "https://rhbk.apps.<your-cluster-domain>/realms/neuralbank/protocol/openid-connect/token"
  targetRef:
    group: gateway.networking.k8s.io
    kind: HTTPRoute
    name: neuralbank-api-route
  auth:
    tokenSource:
      authorizationHeader:
        prefix: Bearer
        name: Authorization
      cookie:
        name: jwt
```

**Important Notes:**
- The `clientSecret` must be updated after generating it from the Keycloak console (see [Step 4](#step-4-configure-keycloak-client-settings-manual))
- The `redirectURI` must exactly match one of the redirect URIs configured in the Keycloak client
- The `hostnames` in HTTPRoute resources must match the hostname used in the OpenShift Route
- All URLs (issuer, endpoints) must use HTTPS and match your cluster's domain configuration

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

### System Architecture

The following diagram illustrates the complete system architecture, showing how all components interact:

<div align="center">
  <img src="{{ site.baseurl }}/system-architecture.png" alt="System architecture diagram" width="900"/>
</div>

*Source: `docs/diagrams/system-architecture.mmd`. Regenerate PNG with `./docs/generate-diagrams.sh`.*

### OIDC Authentication Flow

The following sequence diagram illustrates the complete OIDC authentication flow using Keycloak and Authorino:

<div align="center">
  <img src="{{ site.baseurl }}/oidc-auth-flow.png" alt="OIDC authentication flow sequence diagram" width="900"/>
</div>

*Source: `docs/diagrams/oidc-auth-flow.mmd`. Regenerate PNG with `./docs/generate-diagrams.sh`.*

### Installation Flow

The following diagram shows the automated installation process (`install.sh` and Ansible playbook):

<div align="center">
  <img src="{{ site.baseurl }}/installation-flow.png" alt="Installation flow diagram" width="900"/>
</div>

*Source: `docs/diagrams/installation-flow.mmd`. Regenerate PNG with `./docs/generate-diagrams.sh`.*

### The Application Solution without Auth 🙌:

<div align="center">
  <img src="{{ site.baseurl }}/rhcl.png" width="900"/>
</div>

### The Application Solution with Auth 🔐 powered by Red Hat Build of Keycloak & Authorino:

<div align="center">
  <img src="{{ site.baseurl }}/rhcl-policy-topogy.png" width="900"/>
</div>

## 🌟 Benefits of Cloud Native Integration with Kuadrant

Integrating with a **cloud native strategy** and the **Kuadrant project** brings significant advantages to modern application deployment and security. The simplicity of this approach is remarkable: by adding just a few manifest files with the appropriate configuration, you can transform your application's security posture. **GitOps** plays a crucial role in orchestrating these changes in a clean environment within seconds, enabling a true **Zero Trust** architecture implementation.

The power of this solution lies in its declarative nature—you define the desired state through Kubernetes manifests, and the GitOps workflow ensures that state is achieved and maintained automatically. This approach eliminates manual configuration errors, provides complete audit trails through Git history, and enables rapid deployment across multiple environments with consistency. The **Zero Trust** model is enforced at every layer: authentication through Keycloak, authorization via Authorino, rate limiting for API protection, and service mesh policies for inter-service communication. With **Connectivity Link** and **Kuadrant**, you're establishing a comprehensive security framework that scales with your infrastructure, creating a robust foundation for modern, secure microservices architectures.

---

## 📢 Share This Content

If you found this guide helpful, please share it with your network! Help others discover how to implement Zero Trust security with Connectivity Link and GitOps.

<div align="center" style="margin: 2rem 0;">
  <a href="https://www.linkedin.com/sharing/share-offsite/?url=https://maximilianopizarro.github.io/connectivity-link/" target="_blank" rel="noopener noreferrer" style="display: inline-block; margin: 0 0.5rem; text-decoration: none;">
    <img src="https://img.shields.io/badge/Share%20on-LinkedIn-0077B5?style=for-the-badge&logo=linkedin&logoColor=white" alt="Share on LinkedIn" style="margin: 0.25rem;">
  </a>
  <a href="https://twitter.com/intent/tweet?url=https://maximilianopizarro.github.io/connectivity-link/&text=Security%20Microservice%20with%20Connectivity%20Link%20using%20OpenID%20Connect%20%28OIDC%29%20-%20Zero%20Trust%20Architecture" target="_blank" rel="noopener noreferrer" style="display: inline-block; margin: 0 0.5rem; text-decoration: none;">
    <img src="https://img.shields.io/badge/Share%20on-Twitter-1DA1F2?style=for-the-badge&logo=twitter&logoColor=white" alt="Share on Twitter" style="margin: 0.25rem;">
  </a>
  <a href="https://www.facebook.com/sharer/sharer.php?u=https://maximilianopizarro.github.io/connectivity-link/" target="_blank" rel="noopener noreferrer" style="display: inline-block; margin: 0 0.5rem; text-decoration: none;">
    <img src="https://img.shields.io/badge/Share%20on-Facebook-1877F2?style=for-the-badge&logo=facebook&logoColor=white" alt="Share on Facebook" style="margin: 0.25rem;">
  </a>
  <a href="https://api.whatsapp.com/send?text=Security%20Microservice%20with%20Connectivity%20Link%20-%20https://maximilianopizarro.github.io/connectivity-link/" target="_blank" rel="noopener noreferrer" style="display: inline-block; margin: 0 0.5rem; text-decoration: none;">
    <img src="https://img.shields.io/badge/Share%20on-WhatsApp-25D366?style=for-the-badge&logo=whatsapp&logoColor=white" alt="Share on WhatsApp" style="margin: 0.25rem;">
  </a>
  <a href="mailto:?subject=Security%20Microservice%20with%20Connectivity%20Link&body=Check%20out%20this%20great%20resource%3A%20https://maximilianopizarro.github.io/connectivity-link/" style="display: inline-block; margin: 0 0.5rem; text-decoration: none;">
    <img src="https://img.shields.io/badge/Share%20via-Email-D14836?style=for-the-badge&logo=gmail&logoColor=white" alt="Share via Email" style="margin: 0.25rem;">
  </a>
</div>

<div align="center" style="margin-top: 1.5rem;">
  <p style="font-size: 0.9rem; color: #888; margin-bottom: 1rem;">Connect with the author:</p>
  <a href="https://www.linkedin.com/in/maximiliano-gregorio-pizarro-consultor-it" target="_blank" rel="noopener noreferrer" style="display: inline-block; margin: 0 0.5rem; text-decoration: none;">
    <img src="https://img.shields.io/badge/LinkedIn-Maximiliano%20Pizarro-0077B5?style=for-the-badge&logo=linkedin&logoColor=white" alt="LinkedIn Profile" style="margin: 0.25rem;">
  </a>
  <a href="https://github.com/maximilianoPizarro/connectivity-link" target="_blank" rel="noopener noreferrer" style="display: inline-block; margin: 0 0.5rem; text-decoration: none;">
    <img src="https://img.shields.io/badge/GitHub-Repository-181717?style=for-the-badge&logo=github&logoColor=white" alt="GitHub Repository" style="margin: 0.25rem;">
  </a>
</div>

<p align="center" style="margin-top: 1.5rem; color: #888; font-size: 0.9rem;">
  <strong>Thank you for sharing!</strong> Your support helps the community grow and learn together.
</p>

---
