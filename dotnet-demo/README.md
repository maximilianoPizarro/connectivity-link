# .NET Demo Application - Nexus Integration

This demo application demonstrates a complete CI/CD pipeline that builds a .NET application and publishes artifacts to Nexus Repository Manager, with visualization in Red Hat Developer Hub (Backstage).

## Overview

This demo includes:
- A simple .NET 8.0 Web API application
- Tekton Pipeline for building and publishing NuGet packages to Nexus
- Backstage/Developer Hub integration to visualize artifacts

## Architecture

```
┌─────────────────┐
│   GitLab Repo   │
│  (Source Code)  │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Tekton Pipeline │
│  (CI/CD Build)  │
└────────┬────────┘
         │
         ├──► Build .NET App
         │
         ├──► Create NuGet Package
         │
         └──► Upload to Nexus
                 │
                 ▼
         ┌───────────────┐
         │  Nexus Repo   │
         │  (Artifacts)  │
         └───────┬───────┘
                 │
                 ▼
         ┌───────────────┐
         │ Developer Hub │
         │ (Visualization)│
         └───────────────┘
```

## Prerequisites

1. **Nexus Repository Manager** running at:
   - URL: `http://nexus-nexus2.apps.cluster-gpzvq.gpzvq.sandbox670.opentlc.com`
   - A repository named `releases` (or update the configuration)
   - Credentials configured in Kubernetes secret

2. **Tekton Pipelines** installed in the cluster
   - Namespace: `workshop-pipelines`

3. **Red Hat Developer Hub** with Nexus plugin configured

## Setup Instructions

### 1. Configure Nexus Repository

1. Log in to Nexus at: http://nexus-nexus2.apps.cluster-gpzvq.gpzvq.sandbox670.opentlc.com
2. Create a repository named `releases` (if it doesn't exist)
   - Type: `maven2 (hosted)` or `nuget (hosted)` depending on your preference
   - For NuGet packages, use NuGet repository type
   - For Maven-compatible format, use Maven2 repository type

3. Note your Nexus admin credentials (default: admin/admin123)

### 2. Create Nexus Credentials Secret

#### Option A: Using Kustomize (Recommended)

1. **Create credentials file** (not committed to Git):
   ```bash
   cp nexus-credentials.env.example nexus-credentials.env
   ```

2. **Edit `nexus-credentials.env`** with your actual Nexus password:
   ```bash
   username=admin
   password=YOUR_ACTUAL_NEXUS_PASSWORD
   ```

3. **Apply with Kustomize**:
   ```bash
   kubectl apply -k dotnet-demo/
   ```

   Kustomize will automatically generate the secret from the `.env` file.

#### Option B: Using kubectl (Alternative)

If you prefer not to use Kustomize:

```bash
kubectl create secret generic nexus-credentials \
  --from-literal=username=admin \
  --from-literal=password=YOUR_NEXUS_PASSWORD \
  -n workshop-pipelines
```

**Note:** The `nexus-credentials.env` file is in `.gitignore` and should not be committed to Git.

### 3. Deploy the Tekton Pipeline

Apply the pipeline resources:

```bash
kubectl apply -f dotnet-demo/tekton-pipeline.yaml -n workshop-pipelines
```

### 4. Run the Pipeline

Trigger the pipeline manually:

```bash
kubectl create -f dotnet-demo/tekton-pipeline.yaml -n workshop-pipelines
```

Or use Tekton CLI:

```bash
tkn pipeline start dotnet-demo-pipeline \
  -p git-url=https://gitlab.com/maximilianoPizarro/connectivity-link.git \
  -p git-revision=main \
  -p nexus-url=http://nexus-nexus2.apps.cluster-gpzvq.gpzvq.sandbox670.opentlc.com \
  -p nexus-repository=releases \
  -p nexus-username=admin \
  -p nexus-group-id=com.example \
  -p nexus-artifact-id=dotnet-demo \
  -p nexus-version=1.0.0 \
  -w name=source,volumeClaimTemplateFile=source-pvc.yaml \
  -w name=cache,volumeClaimTemplateFile=cache-pvc.yaml \
  -n workshop-pipelines
```

### 5. Verify Artifact Upload

Check Nexus repository:

1. Navigate to: http://nexus-nexus2.apps.cluster-gpzvq.gpzvq.sandbox670.opentlc.com
2. Browse to: `releases` repository
3. Look for: `com/example/dotnet-demo/1.0.0/`

### 6. View in Developer Hub

1. Navigate to Developer Hub
2. Search for component: `dotnet-demo`
3. View the component details
4. Check the Nexus integration tab (if plugin is configured)

## Pipeline Tasks

The pipeline consists of the following tasks:

1. **clone-repo**: Clones the Git repository
2. **build-dotnet**: Builds the .NET application
3. **build-nuget-package**: Creates a NuGet package (.nupkg)
4. **publish-to-nexus**: Uploads the package to Nexus

## Customization

### Update Nexus URL

Edit `dotnet-demo/tekton-pipeline.yaml` and update:
- `nexus-url` parameter
- `NEXUS_URL` in the upload task

### Update Repository Name

Edit `dotnet-demo/tekton-pipeline.yaml` and update:
- `nexus-repository` parameter
- `NEXUS_REPOSITORY` in the upload task

### Update Artifact Coordinates

Edit `dotnet-demo/tekton-pipeline.yaml` and update:
- `nexus-group-id`: Maven group ID (e.g., `com.example`)
- `nexus-artifact-id`: Artifact ID (e.g., `dotnet-demo`)
- `nexus-version`: Version number (e.g., `1.0.0`)

## Troubleshooting

### Pipeline Fails on Upload

1. Check Nexus credentials:
   ```bash
   kubectl get secret nexus-credentials -n workshop-pipelines -o yaml
   ```

2. Verify Nexus URL is accessible from the cluster:
   ```bash
   kubectl run curl-test --image=curlimages/curl:latest --rm -it -- \
     curl -u admin:password http://nexus-nexus2.apps.cluster-gpzvq.gpzvq.sandbox670.opentlc.com/service/rest/v1/status
   ```

3. Check pipeline logs:
   ```bash
   tkn pipelinerun logs dotnet-demo-pipeline-run -n workshop-pipelines
   ```

### Artifact Not Visible in Developer Hub

1. Verify the catalog-info.yaml is registered:
   - Check Developer Hub → Catalog → Components
   - Search for `dotnet-demo`

2. Verify Nexus plugin is configured in `app-config.yaml`

3. Check component annotations match Nexus repository structure

## References

- [Tekton Pipelines Documentation](https://tekton.dev/docs/)
- [Nexus Repository Manager REST API](https://help.sonatype.com/repomanager3/rest-and-integration-api)
- [Red Hat Developer Hub Documentation](https://developers.redhat.com/products/red-hat-developer-hub/overview)

