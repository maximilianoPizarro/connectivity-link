# Nexus Credentials Secret Setup

## Problem

The `nexus-credentials.env` file is in `.gitignore` and not in the Git repository, so ArgoCD cannot use Kustomize's `secretGenerator` to create the secret automatically.

## Solution: Create Secret Manually

Since ArgoCD manages this application, you need to create the secret manually in the cluster:

### Option 1: Using kubectl (Recommended for ArgoCD)

```bash
kubectl create secret generic nexus-credentials \
  --from-literal=username=admin \
  --from-literal=password=YOUR_NEXUS_PASSWORD \
  -n workshop-pipelines
```

### Option 2: Using OpenShift Console

1. Navigate to: **Workloads → Secrets** in namespace `workshop-pipelines`
2. Click **Create → Key/value secret**
3. Name: `nexus-credentials`
4. Add key-value pairs:
   - `username`: `admin`
   - `password`: `YOUR_NEXUS_PASSWORD`
5. Click **Create**

### Option 3: Using ArgoCD CLI

```bash
argocd app sync dotnet-demo -n openshift-gitops
# Then create secret manually as shown in Option 1
```

## Verify Secret

```bash
kubectl get secret nexus-credentials -n workshop-pipelines
kubectl describe secret nexus-credentials -n workshop-pipelines
```

## Update Secret (if password changes)

```bash
kubectl delete secret nexus-credentials -n workshop-pipelines
kubectl create secret generic nexus-credentials \
  --from-literal=username=admin \
  --from-literal=password=NEW_PASSWORD \
  -n workshop-pipelines
```

## Why Not Use secretGenerator?

- The `nexus-credentials.env` file is in `.gitignore` (security best practice)
- ArgoCD clones the Git repository, so the `.env` file is not available
- Kustomize fails when trying to read a non-existent file
- Manual secret creation is the standard approach for GitOps with sensitive data

## Alternative: External Secrets Operator

For production, consider using External Secrets Operator to manage secrets from external secret stores (Vault, AWS Secrets Manager, etc.).

