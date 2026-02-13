# OpenShift OAuth – HTPasswd identity provider (GitOps)

This folder defines an HTPasswd identity provider for OpenShift so you can log in with a username and password (e.g. `admin` / `password`) without an external IdP.

## Contents

- **htpasswd-secret.yaml** – Secret in `openshift-config` with the htpasswd file (default user: `admin`, password: `password`).
- **oauth-cluster-htpasswd.yaml** – OAuth `cluster` resource adding the HTPasswd identity provider.
- **kustomization.yaml** – Kustomize wiring for Argo CD or `kubectl apply -k`.

## GitOps (Argo CD)

1. **Add an Application** that points to this path, with destination suitable for cluster-scoped resources:
   - **Path:** `oauth-ocp`
   - **Destination server:** `https://kubernetes.default.svc`
   - **Destination namespace:** leave empty or set to `openshift-config` (the Secret has its own namespace; the OAuth is cluster-scoped).

2. Add `oauth-ocp` to your ApplicationSet (see below) or create a one-off Application:

   ```yaml
   spec:
     source:
       path: oauth-ocp
       repoURL: https://github.com/your-org/connectivity-link.git
       targetRevision: main
     destination:
       server: https://kubernetes.default.svc
       namespace: ""   # empty for cluster-scoped OAuth; Secret specifies openshift-config
   ```

3. Sync the application. After sync, the OAuth server will reload; log in at the OpenShift console with the htpasswd user (default: `admin` / `password`).

## Important

- **Replacing other IDPs:** Applying `oauth-cluster-htpasswd.yaml` sets `spec.identityProviders` to only this HTPasswd entry. If the cluster already has other identity providers (e.g. KubeAdmin, LDAP), they will be replaced unless you merge them into this file or patch the OAuth manually.
- **Change default password:** The default Secret contains a hash for `admin` / `password`. For any real use, regenerate and replace:
  ```bash
  htpasswd -cb - admin yourpassword | base64 -w0
  ```
  Put the result in `htpasswd-secret.yaml` under `data.htpasswd`, then commit and sync.

## Adding more users

Append lines to the htpasswd file, then base64 the whole file and update the Secret:

```bash
htpasswd -b htpasswd_file newuser newpass
base64 -w0 htpasswd_file
```

Update `data.htpasswd` in `htpasswd-secret.yaml` with that value and sync.

## Manual apply (without GitOps)

```bash
kubectl apply -k oauth-ocp
# Or apply files directly:
kubectl apply -f htpasswd-secret.yaml
kubectl apply -f oauth-cluster-htpasswd.yaml
```

## Default credentials (change in production)

- **User:** admin  
- **Password:** password  
