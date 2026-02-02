# Installation Guide

This guide explains how to install Connectivity Link using the automated installation script.

## Prerequisites

1. **OpenShift CLI (oc)**: Must be installed and configured
   ```bash
   # Verify installation
   oc version
   ```

2. **Ansible**: Required for installing the OpenShift GitOps Operator
   ```bash
   # Install Ansible and required Python packages
   pip install -r requirements.txt
   
   # Or using system package manager
   dnf install ansible python3-kubernetes
   ```

3. **Cluster Access**: Must be authenticated to an OpenShift cluster with cluster-admin privileges
   ```bash
   oc login <cluster-url>
   oc whoami
   ```

## Installation Steps

### Quick Start

```bash
# Make script executable
chmod +x install.sh

# Run installation
./install.sh
```

### What the Script Does

1. **Pre-flight Checks**:
   - Verifies `oc` CLI is installed
   - Checks authentication to OpenShift cluster
   - Verifies cluster-admin privileges
   - Detects cluster domain automatically

2. **Install OpenShift GitOps Operator** (using Ansible):
   - Ensures CatalogSource is healthy
   - Creates OperatorGroup if needed
   - Creates/updates Subscription
   - Waits for InstallPlan and CSV
   - Waits for ArgoCD server to be ready

3. **Apply ApplicationSet**:
   - Updates `applicationset-instance.yaml` with detected cluster domain
   - Applies the ApplicationSet to deploy all components

### Manual Installation (Alternative)

If you prefer to install manually:

1. **Install OpenShift GitOps Operator**:
   ```bash
   # Via Ansible
   ansible-playbook -i localhost, -c local install-gitops.yaml
   
   # Or via OpenShift Console:
   # Operators → OperatorHub → Search "OpenShift GitOps" → Install
   ```

2. **Apply ApplicationSet**:
   ```bash
   # Update cluster domain in applicationset-instance.yaml first
   # Then apply:
   oc apply -f applicationset-instance.yaml
   ```

### Troubleshooting

#### Ansible Not Found
```bash
# Install Ansible
pip install ansible kubernetes

# Or
dnf install ansible python3-kubernetes
```

#### CatalogSource Issues
If the CatalogSource is unhealthy:
```bash
# Check CatalogSource status
oc get catalogsource redhat-operators -n openshift-marketplace -o yaml

# Force update
oc patch catalogsource redhat-operators -n openshift-marketplace \
  --type=merge -p '{"metadata":{"annotations":{"olm.catalogSource.forceUpdate":"'$(date +%s)'"}}}'
```

#### Operator Not Installing
```bash
# Check subscription status
oc get subscription openshift-gitops-operator -n openshift-operators -o yaml

# Check CSV status
oc get csv -n openshift-operators | grep gitops

# Check InstallPlan
oc get installplan -n openshift-operators | grep gitops
```

#### ArgoCD Not Ready
```bash
# Check ArgoCD deployment
oc get deployment argocd-server -n openshift-gitops

# Check pods
oc get pods -n openshift-gitops

# Check logs
oc logs -n openshift-gitops -l app.kubernetes.io/name=argocd-server
```

## Post-Installation

After installation, you can:

1. **Access ArgoCD UI**:
   ```bash
   oc get route argocd-server -n openshift-gitops -o jsonpath='{.spec.host}'
   ```

2. **Monitor Applications**:
   ```bash
   oc get applications -n openshift-gitops
   ```

3. **Check Application Status**:
   ```bash
   oc get applications -n openshift-gitops -w
   ```

## Uninstallation

To remove all components:

```bash
./uninstall-applicationset.sh
```

Then manually remove the OpenShift GitOps Operator via the console or:

```bash
oc delete subscription openshift-gitops-operator -n openshift-operators
```
