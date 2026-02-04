# Installation Guide

This guide explains how to install Connectivity Link using the automated installation script and Ansible playbook.

## Prerequisites

### 1. Python 3.11+

Required for Ansible Core and the Kubernetes/OpenShift collections.

```bash
# Verify version
python3 --version   # or: python --version
# Must be 3.11 or higher
```

On RHEL/Fedora you can use the system Python if it is 3.11+; otherwise use a virtual environment or `pyenv`.

### 2. OpenShift CLI (oc)

Must be installed and configured to talk to your OpenShift cluster.

```bash
# Verify installation
oc version

# Authenticate (cluster-admin required for installation)
oc login <cluster-url>
oc whoami
```

### 3. Ansible Core and collections

Install Ansible Core (or `ansible-core`) and the required collections for Kubernetes/OpenShift.

```bash
# Option A: Using requirements.txt (recommended)
pip install -r requirements.txt

# Install required collections
ansible-galaxy collection install kubernetes.core community.kubernetes

# Verify
ansible-playbook --version
```

```bash
# Option B: Using system package manager (if Python 3.11+ and packages available)
dnf install ansible-core python3-kubernetes
ansible-galaxy collection install kubernetes.core community.kubernetes
```

**Note:** `requirements.txt` lists `ansible` (or use `ansible-core`); both work with Python 3.11+. The playbook uses modules from `kubernetes.core` (e.g. `k8s`, `k8s_info`).

### 4. Cluster access

- You must be authenticated to an OpenShift cluster.
- **cluster-admin** privileges are required to install the GitOps operator, create namespaces, and let ArgoCD manage cluster resources.

```bash
oc whoami
oc auth can-i '*' '*' --all-namespaces   # should be "yes" for cluster-admin
```

## Installation Steps

### Quick Start (recommended)

The **`install.sh`** script performs pre-flight checks, detects the cluster domain, updates all manifest files with the correct domain, and then runs the Ansible playbook.

```bash
# Make script executable
chmod +x install.sh

# Run installation
./install.sh
```

### What the script does

1. **Pre-flight checks**
   - Verifies `oc` CLI is installed
   - Checks authentication to OpenShift
   - Verifies cluster-admin privileges
   - Verifies Ansible is installed
   - Detects cluster domain and sets Keycloak/app hosts

2. **Domain updates** (before applying anything)
   - `applicationset-instance.yaml` — keycloak_host, app_host
   - `rhbk/keycloak.yaml` — hostname
   - `rhbk/keycloak-neuralbank-realm.yaml` — redirect URIs and URLs
   - `neuralbank-stack/values.yaml` — Keycloak/app URLs (clientSecret filled by playbook later)
   - `rhcl-operator/oidc-policy.yaml` — provider URLs (clientSecret filled by playbook later)
   - `servicemeshoperator3/gateway-route.yaml` — host

3. **Ansible playbook** (`install-gitops.yaml`)
   - If GitOps is already installed and ArgoCD is Available, skips operator installation
   - Installs OpenShift GitOps Operator (subscription with channel only, no `startingCSV`; `installPlanApproval: Automatic`)
   - Applies ApplicationSet and waits for applications (includes **observability** app: Cluster Observability Operator + MonitoringStack for Prometheus)
   - Removes any Connectivity Link ConsoleLink; enables **dynamic console plugins** (GitOps and Connectivity Link) via `spec.plugins`
   - When Keycloak and realm `neuralbank` are ready: gets client secret for client `neuralbank`, updates values/oidc-policy files, patches OIDCPolicy, creates Secrets
   - Fixes operator configurations (e.g. rhbk-operator OperatorGroup, duplicate devspaces subscriptions)

### Run only the Ansible playbook

If you have already updated cluster domain references (e.g. via `update-cluster-domain.sh` or manually), you can run only the playbook:

```bash
ansible-playbook -i localhost, -c local install-gitops.yaml
```

Optional variables:

```bash
# Override cluster domain (if not auto-detected)
ansible-playbook -i localhost, -c local install-gitops.yaml -e cluster_domain=apps.mycluster.example.com

# Skip GitOps install prompt / use existing GitOps
# (playbook auto-detects if ArgoCD is already Available and skips install)
```

### Manual installation (no script)

1. **Update cluster domain** in all manifests (see main [README.md](README.md) Configuration section).
2. **Install OpenShift GitOps Operator** (Console → OperatorHub → OpenShift GitOps, or OLM/CLI).
3. **Apply ApplicationSet:**
   ```bash
   oc apply -f applicationset-instance.yaml
   ```
4. **Keycloak/OIDC:** Create client `neuralbank` in realm `neuralbank`, then set the client secret in `neuralbank-stack/values.yaml` and `rhcl-operator/oidc-policy.yaml`, or run the playbook later to fetch the secret from Keycloak.

## Post-Installation

### Console (Connectivity Link view)

Connectivity Link is exposed via the **dynamic console plugin**, not ConsoleLink. Enable it:

- **UI:** Administration → Cluster Settings → Console → add `connectivity-link-plugin` to spec.plugins (and `gitops-plugin` for GitOps).
- **CLI:**
  ```bash
  oc patch console.operator.openshift.io cluster --type merge -p '{"spec":{"plugins":["gitops-plugin","connectivity-link-plugin"]}}'
  oc get console.operator.openshift.io cluster -o jsonpath='{.spec.plugins}'
  ```

### ArgoCD and applications

```bash
# ArgoCD route
oc get route -n openshift-gitops -o jsonpath='{.items[?(@.metadata.name=="openshift-gitops-server")].spec.host}'

# Applications
oc get applications -n openshift-gitops
oc get applications -n openshift-gitops -w
```

### OIDC (after Keycloak is ready)

If the playbook ran after Keycloak was ready, it will have updated `neuralbank-stack/values.yaml` and `rhcl-operator/oidc-policy.yaml` with the client secret and patched the OIDCPolicy. **Commit and push** those file changes so ArgoCD syncs the correct configuration.

## Troubleshooting

### Python or Ansible version

```bash
# Ensure Python 3.11+
python3 --version

# Reinstall in a venv if needed
python3.11 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
ansible-galaxy collection install kubernetes.core community.kubernetes
```

### oc not found or not authenticated

```bash
# Install oc (see OpenShift documentation)
# Login
oc login --server=<cluster-url> -u <user>
oc whoami
```

### Ansible / collection errors

```bash
# Install collections
ansible-galaxy collection install kubernetes.core community.kubernetes

# Run playbook with verbose output
ansible-playbook -i localhost, -c local install-gitops.yaml -vv
```

### CatalogSource unhealthy

```bash
oc get catalogsource redhat-operators -n openshift-marketplace -o yaml
oc patch catalogsource redhat-operators -n openshift-marketplace \
  --type=merge -p '{"metadata":{"annotations":{"olm.catalogSource.forceUpdate":"'$(date +%s)'"}}}'
```

### GitOps subscription / CSV

```bash
oc get subscription openshift-gitops-operator -n openshift-operators -o yaml
oc get csv -n openshift-operators | grep gitops
oc get installplan -n openshift-operators | grep gitops
```

### ArgoCD not ready

```bash
oc get deployment argocd-server -n openshift-gitops
oc get pods -n openshift-gitops
oc get argocd openshift-gitops -n openshift-gitops -o yaml
```

### "Gateway API provider (istio / envoy gateway) is not installed" / Kuadrant

The playbook **does not** wait for or restart Kuadrant. Installation order is: **Service Mesh first** (sync_wave 3), then **Connectivity Link** (sync_wave 6), so the Istio Gateway and Gateway API provider should exist before RHCL syncs. If you still see this message or `neuralbank-authorino` fails to sync:

1. Ensure **servicemeshoperator3** is **Synced** and the Gateway exists:
   ```bash
   oc get gateway -n istio-system
   ```
2. If the Gateway exists but Kuadrant (RHCL) started before it, restart the Kuadrant controller in `kuadrant-system`:
   ```bash
   oc rollout restart deployment -n kuadrant-system $(oc get deployment -n kuadrant-system -o jsonpath='{.items[0].metadata.name}')
   ```
3. In ArgoCD, refresh and sync **rhcl-operator** again.

## Uninstallation

To remove applications and optional resources:

```bash
./uninstall-applicationset.sh
```

Options: `--dry-run`, `--force`, `--clean-all`. See script help. To remove the GitOps operator:

```bash
oc delete subscription openshift-gitops-operator -n openshift-operators
```
