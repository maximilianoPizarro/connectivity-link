# Demo Instructions: .NET Pipeline with Nexus Integration

This document provides step-by-step instructions for demonstrating the .NET application pipeline that publishes artifacts to Nexus and visualizes them in Developer Hub.

## Prerequisites Checklist

- [ ] Nexus Repository Manager running at: `http://nexus-nexus2.apps.cluster-gpzvq.gpzvq.sandbox670.opentlc.com`
- [ ] Nexus repository named `releases` created (or update configuration)
- [ ] Nexus admin credentials available
- [ ] Tekton Pipelines installed in cluster
- [ ] Access to `workshop-pipelines` namespace
- [ ] Developer Hub (Backstage) running and accessible
- [ ] GitHub repository access

## Step 1: Prepare Nexus Repository

1. **Access Nexus UI**
   ```
   http://nexus-nexus2.apps.cluster-gpzvq.gpzvq.sandbox670.opentlc.com
   ```

2. **Create Repository (if needed)**
   - Login with admin credentials
   - Navigate to: Settings → Repositories → Create repository
   - Select: `maven2 (hosted)` or `nuget (hosted)`
   - Name: `releases`
   - Version policy: `Release`
   - Save

3. **Verify Repository Access**
   - Test URL: `http://nexus-nexus2.apps.cluster-gpzvq.gpzvq.sandbox670.opentlc.com/repository/releases/`
   - Should show empty repository or existing artifacts

## Step 2: Configure Kubernetes Secret

### Option A: Using Kustomize (Recommended - GitOps Friendly)

1. **Create credentials file**:
   ```bash
   cd dotnet-demo
   cp nexus-credentials.env.example nexus-credentials.env
   ```

2. **Edit `nexus-credentials.env`** with your actual Nexus credentials:
   ```bash
   username=admin
   password=YOUR_ACTUAL_NEXUS_PASSWORD
   ```

3. **Apply with Kustomize** (this will create both the secret and pipeline):
   ```bash
   kubectl apply -k .
   ```

   Kustomize will automatically:
   - Generate the `nexus-credentials` secret from the `.env` file
   - Apply the Tekton pipeline resources
   - Set the correct namespace (`workshop-pipelines`)

### Option B: Using kubectl (Alternative)

If you prefer manual secret creation:

```bash
kubectl create secret generic nexus-credentials \
  --from-literal=username=admin \
  --from-literal=password=YOUR_NEXUS_PASSWORD \
  -n workshop-pipelines
```

**Security Note:** 
- The `nexus-credentials.env` file is in `.gitignore` and should **never** be committed to Git
- For production, consider using Sealed Secrets or External Secrets Operator
- The example file (`nexus-credentials.env.example`) is safe to commit as it contains no real credentials

## Step 3: Deploy Tekton Pipeline

1. **Apply Pipeline Resources**
   ```bash
   kubectl apply -f dotnet-demo/tekton-pipeline.yaml -n workshop-pipelines
   ```

2. **Verify Resources Created**
   ```bash
   kubectl get pipeline,pipeline,task,secret -n workshop-pipelines | grep dotnet
   ```

   Expected output:
   - `pipeline.tekton.dev/dotnet-demo-pipeline`
   - `task.tekton.dev/dotnet-build-nuget`
   - `task.tekton.dev/nexus-upload`
   - `secret/nexus-credentials`

## Step 4: Run the Pipeline

### Option A: Using Tekton CLI (Recommended)

```bash
tkn pipeline start dotnet-demo-pipeline \
  -p git-url=https://github.com/maximilianoPizarro/connectivity-link.git \
  -p git-revision=main \
  -p nexus-url=http://nexus-nexus2.apps.cluster-gpzvq.gpzvq.sandbox670.opentlc.com \
  -p nexus-repository=releases \
  -p nexus-username=admin \
  -p nexus-group-id=com.example \
  -p nexus-artifact-id=dotnet-demo \
  -p nexus-version=1.0.0 \
  -w name=source,volumeClaimTemplateFile=- <<EOF
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: dotnet-source-pvc
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
EOF \
  -w name=cache,volumeClaimTemplateFile=- <<EOF
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: dotnet-cache-pvc
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 500Mi
EOF \
  -n workshop-pipelines \
  --showlog
```

### Option B: Using kubectl

```bash
kubectl create -f - <<EOF
apiVersion: tekton.dev/v1beta1
kind: PipelineRun
metadata:
  name: dotnet-demo-pipeline-run-$(date +%s)
  namespace: workshop-pipelines
spec:
  pipelineRef:
    name: dotnet-demo-pipeline
  params:
    - name: git-url
      value: "https://github.com/maximilianoPizarro/connectivity-link.git"
    - name: git-revision
      value: "main"
    - name: nexus-url
      value: "http://nexus-nexus2.apps.cluster-gpzvq.gpzvq.sandbox670.opentlc.com"
    - name: nexus-repository
      value: "releases"
    - name: nexus-username
      value: "admin"
    - name: nexus-group-id
      value: "com.example"
    - name: nexus-artifact-id
      value: "dotnet-demo"
    - name: nexus-version
      value: "1.0.0"
  workspaces:
    - name: source
      volumeClaimTemplate:
        spec:
          accessModes:
            - ReadWriteOnce
          resources:
            requests:
              storage: 1Gi
    - name: cache
      volumeClaimTemplate:
        spec:
          accessModes:
            - ReadWriteOnce
          resources:
            requests:
              storage: 500Mi
EOF
```

## Step 5: Monitor Pipeline Execution

1. **Watch Pipeline Run**
   ```bash
   tkn pipelinerun list -n workshop-pipelines
   tkn pipelinerun logs <pipeline-run-name> -n workshop-pipelines -f
   ```

2. **Check Pipeline Status**
   ```bash
   kubectl get pipelinerun -n workshop-pipelines
   ```

3. **View Task Logs**
   ```bash
   tkn taskrun list -n workshop-pipelines
   tkn taskrun logs <task-run-name> -n workshop-pipelines
   ```

## Step 6: Verify Artifact in Nexus

1. **Access Nexus UI**
   ```
   http://nexus-nexus2.apps.cluster-gpzvq.gpzvq.sandbox670.opentlc.com
   ```

2. **Browse Repository**
   - Navigate to: Browse → `releases`
   - Path: `com/example/dotnet-demo/1.0.0/`
   - Verify `.nupkg` file is present

3. **Verify Artifact Details**
   - Click on the artifact
   - Check version: `1.0.0`
   - Verify package type: `.nupkg`

## Step 7: View in Developer Hub

1. **Access Developer Hub**
   ```
   https://developer-hub.apps.<cluster-domain>
   ```

2. **Search for Component**
   - Navigate to: Catalog → Components
   - Search: `dotnet-demo`
   - Click on the component

3. **View Component Details**
   - **Overview Tab**: Shows component information
   - **Links Section**: 
     - Nexus Repository link
     - View Artifacts in Nexus link
     - Source Code link
   - **Dependencies**: Shows dependency on `workshop-pipelines`

4. **Verify Nexus Integration**
   - Check annotations show Nexus URL
   - Verify links point to correct Nexus repository
   - Confirm artifact path matches Nexus structure

## Troubleshooting

### Pipeline Fails at Clone Step

**Problem:** Cannot clone repository

**Solution:**
```bash
# Verify Git URL is accessible
curl -I https://github.com/maximilianoPizarro/connectivity-link.git

# Check Tekton git-clone task is available
kubectl get clustertask git-clone
```

### Pipeline Fails at Build Step

**Problem:** .NET SDK not found or build fails

**Solution:**
```bash
# Check if s2i-dotnet task exists
kubectl get clustertask s2i-dotnet

# If not available, use alternative build approach
# Update tekton-pipeline.yaml to use mcr.microsoft.com/dotnet/sdk:8.0 image directly
```

### Pipeline Fails at Upload Step

**Problem:** Cannot upload to Nexus

**Solution:**
```bash
# Verify Nexus credentials
kubectl get secret nexus-credentials -n workshop-pipelines -o yaml

# Test Nexus connectivity from cluster
kubectl run nexus-test --image=curlimages/curl:latest --rm -it -- \
  curl -u admin:password http://nexus-nexus2.apps.cluster-gpzvq.gpzvq.sandbox670.opentlc.com/service/rest/v1/status

# Check Nexus repository exists
curl -u admin:password http://nexus-nexus2.apps.cluster-gpzvq.gpzvq.sandbox670.opentlc.com/service/rest/v1/repositories
```

### Component Not Visible in Developer Hub

**Problem:** Component doesn't appear in catalog

**Solution:**
```bash
# Verify catalog-info.yaml is registered
# Check Developer Hub logs
kubectl logs -n developer-hub -l app=backstage-backend --tail=100 | grep dotnet

# Verify GitHub provider is configured
# Check app-config.yaml includes dotnet-demo location

# Force catalog refresh
# Restart Backstage pod or wait for scheduled refresh (30 minutes)
```

## Demo Script

### Quick Demo Flow

1. **Show Nexus Repository** (empty or existing artifacts)
   ```
   http://nexus-nexus2.apps.cluster-gpzvq.gpzvq.sandbox670.opentlc.com/#browse/browse:releases
   ```

2. **Trigger Pipeline**
   ```bash
   tkn pipeline start dotnet-demo-pipeline ... (as shown above)
   ```

3. **Show Pipeline Execution** (in Tekton Dashboard or CLI)
   - Clone step
   - Build step
   - Package step
   - Upload step

4. **Show Artifact in Nexus**
   ```
   http://nexus-nexus2.apps.cluster-gpzvq.gpzvq.sandbox670.opentlc.com/#browse/browse:releases:com/example/dotnet-demo/1.0.0
   ```

5. **Show Component in Developer Hub**
   - Navigate to component
   - Show links to Nexus
   - Show dependencies
   - Show annotations

### Key Points to Highlight

- ✅ **Automated CI/CD**: Pipeline automatically builds and publishes
- ✅ **Artifact Management**: Centralized artifact storage in Nexus
- ✅ **Visibility**: Developer Hub provides single pane of glass
- ✅ **Traceability**: Links between source, build, and artifacts
- ✅ **Integration**: Seamless integration between Tekton, Nexus, and Backstage

## Next Steps

- Configure webhook to trigger pipeline on Git push
- Add versioning strategy (semantic versioning)
- Configure artifact promotion workflow
- Add security scanning in pipeline
- Configure notifications for build status

