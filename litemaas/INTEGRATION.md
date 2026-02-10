# LiteMaaS Integration in Connectivity Link

## Summary

LiteMaaS is integrated into the connectivity-link GitOps flow. The **cluster domain** is defined in one place; deployments and namespace are static YAML (no `.local`). Only the three secret files are generated from templates (as `.yaml`).

## Changes

### 1. Single file for cluster domain

- **`cluster-config.env`**: Holds all domain-dependent URLs:
  - `CORS_ORIGIN`, `OAUTH_ISSUER`, `OAUTH_CALLBACK_URL`, `LITELLM_API_URL`, `FRONTEND_HOST`
- Kustomize builds the **`litemaas-cluster-config`** ConfigMap from this file.
- The backend gets `CORS_ORIGIN`, `OAUTH_ISSUER`, `OAUTH_CALLBACK_URL`, and `LITELLM_API_URL` via **envFrom** from that ConfigMap (not from the Secret).

### 2. Setting the cluster domain

**Recommended** (from repo root):

```bash
./update-cluster-domain.sh apps.your-cluster.example.com
```

The script updates the domain in:

- All repo YAMLs that contain the domain (including `litemaas/`)
- **`litemaas/cluster-config.env`** (`*.env` is included)
- `litemaas/OAuthClient.yaml`
- `litemaas/litemaas-gateway.yaml`

So the domain is set once and applied everywhere.

### 3. YAML layout: no `.local` for deployments

| Before | Now |
|--------|-----|
| `namespace.yaml.template` → `.local` | **`namespace.yaml`** static with `name: litemaas` |
| `backend-deployment.yaml.template` → `.local` | **`backend-deployment.yaml`** static; URLs from ConfigMap |
| `frontend-deployment.yaml.template` → `.local` | **`frontend-deployment.yaml`** static |
| Secret templates → `.local` | **`backend-secret.yaml`**, **`postgres-secret.yaml`**, **`litellm-secret.yaml`** (placeholders in repo; run `preparation.sh` to fill from `user-values.env`) |

Only the three secrets are generated: `preparation.sh` overwrites the `.yaml` files from the `.template` files using `user-values.env`.

### 4. Kustomization

- **configMapGenerator** creates `litemaas-cluster-config` from `cluster-config.env`.
- **resources** include `namespace.yaml`, `rolebinding.yaml`, and the three secret `.yaml` files (plus other static manifests).
- Deployments and namespace are static YAML; no `.local` files.

### 5. Argo CD integration

- LiteMaaS is part of the **ApplicationSet** in `applicationset-instance.yaml`:
  - `name: litemaas`, `namespace: litemaas`, `path: litemaas`, `sync_wave: "6"`.
- Argo CD deploys the app from the `litemaas/` path (Kustomize).
- **RoleBinding**: `rolebinding.yaml` defines a Role and RoleBinding so the Argo CD application controller (`openshift-gitops-argocd-application-controller`) can create and update resources (Secrets, ConfigMaps, Deployments, StatefulSets, Routes, etc.) in the `litemaas` namespace. Sync-wave is set to `"1"` so RBAC is applied early.

## Recommended flow

1. **First time or new cluster**  
   From repo root:
   ```bash
   ./update-cluster-domain.sh apps.your-domain.com
   ```

2. **Secrets**  
   In `litemaas/`:
   ```bash
   cp user-values.env.example user-values.env
   # Edit user-values.env with real passwords and keys
   ./preparation.sh
   ```

3. **Deploy**  
   - GitOps: commit and push; Argo CD syncs the `litemaas` application.  
   - Manual: `oc apply -k litemaas/`.

## Files involved

- **Added**: `cluster-config.env`, `namespace.yaml`, `backend-deployment.yaml`, `frontend-deployment.yaml`, `rolebinding.yaml`, `INTEGRATION.md`
- **Updated**: `kustomization.yaml`, `backend-secret.yaml.template`, `preparation.sh`, `README.md`, `update-cluster-domain.sh`, `applicationset-instance.yaml`
- **Unchanged usage**: `OAuthClient.yaml`, `litemaas-gateway.yaml` (domain still updated via `update-cluster-domain.sh`)
