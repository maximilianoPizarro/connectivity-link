# Troubleshooting Tekton Pipelines

## Problema: Pipelines no se ven en Developer Hub y no terminan

### Diagnóstico

1. **Verificar PipelineRuns colgados:**
   ```bash
   oc get pipelineruns -n dotnet-demo
   oc describe pipelinerun <nombre> -n dotnet-demo
   ```

2. **Verificar TaskRuns:**
   ```bash
   oc get taskruns -n dotnet-demo
   oc describe taskrun <nombre> -n dotnet-demo
   ```

3. **Verificar Pods:**
   ```bash
   oc get pods -n dotnet-demo
   oc logs <pod-name> -n dotnet-demo
   ```

4. **Verificar permisos de Backstage:**
   ```bash
   oc get role backstage-tekton-reader -n dotnet-demo
   oc get rolebinding backstage-tekton-reader-binding -n dotnet-demo
   ```

### Soluciones

#### Limpiar PipelineRuns colgados

```bash
# Listar PipelineRuns
oc get pipelineruns -n dotnet-demo

# Eliminar PipelineRuns específicos
oc delete pipelinerun <nombre> -n dotnet-demo

# Eliminar todos los PipelineRuns colgados (cuidado!)
oc delete pipelineruns --all -n dotnet-demo
```

#### Verificar Service Account de Backstage

```bash
# Verificar service account en developer-hub
oc get sa -n developer-hub

# Verificar pods de Backstage
oc get pods -n developer-hub
oc describe pod <backstage-pod-name> -n developer-hub | grep ServiceAccount
```

Si el service account es diferente a `developer-hub`, actualizar `backstage-rbac.yaml`:

```yaml
subjects:
  - kind: ServiceAccount
    name: <nombre-real-del-service-account>
    namespace: developer-hub
```

#### Verificar configuración de Kubernetes plugin

Asegúrate de que `app-config.yaml` tenga:
- `kubernetes.customResources` configurado para Tekton
- `tekton.namespace: dotnet-demo`
- `backstage.io/kubernetes-namespace: dotnet-demo` en `catalog-info.yaml`

#### Reiniciar Backstage (si es necesario)

```bash
# Reiniciar deployment de Backstage
oc rollout restart deployment -n developer-hub
```

### Problemas comunes

1. **PipelineRuns colgados:** Eliminar y crear nuevos
2. **Permisos insuficientes:** Verificar RBAC en `backstage-rbac.yaml`
3. **Service Account incorrecto:** Verificar nombre real del SA
4. **Namespace incorrecto:** Verificar que `tekton.namespace` en `app-config.yaml` sea `dotnet-demo`

