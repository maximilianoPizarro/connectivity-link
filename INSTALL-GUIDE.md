# Guía de Instalación - Connectivity Link

Este script automatiza la instalación completa de Connectivity Link en OpenShift usando GitOps.

## Requisitos Previos

1. **OpenShift 4.20+** con acceso de cluster-admin
2. **oc CLI** instalado y configurado
3. **Autenticación** al cluster OpenShift (`oc login`)

## Uso del Script

### En Linux/macOS o Git Bash (Windows)

```bash
# Hacer el script ejecutable
chmod +x install.sh

# Ejecutar el script
./install.sh
```

### En Windows PowerShell

Si estás usando PowerShell en Windows, puedes ejecutar el script usando Git Bash o WSL:

```powershell
# Opción 1: Usar Git Bash (si está instalado)
bash install.sh

# Opción 2: Usar WSL
wsl bash install.sh
```

## ¿Qué hace el script?

El script `install.sh` automatiza los siguientes pasos:

### 1. Verificaciones Previas
- ✅ Verifica que `oc` esté instalado
- ✅ Verifica autenticación al cluster
- ✅ Verifica permisos de cluster-admin

### 2. Detección del Dominio del Cluster
- 🔍 Detecta automáticamente el dominio del cluster
- 📝 Actualiza `applicationset-instance.yaml` con los valores correctos:
  - `keycloak_host`: `rhbk.apps.<cluster-domain>`
  - `app_host`: `neuralbank.apps.<cluster-domain>`

### 3. Instalación de OpenShift GitOps Operator
- 📦 Crea la suscripción del operador
- ⏳ Espera a que el operador esté listo (hasta 5 minutos)

### 4. Espera por GitOps
- ⏳ Espera a que el namespace `openshift-gitops` esté disponible
- ⏳ Espera a que el servidor ArgoCD esté listo

### 5. Aplicación del ApplicationSet
- 🚀 Aplica `applicationset-instance.yaml`
- 📊 Muestra el estado inicial de las aplicaciones

## Proceso de Instalación

El script instalará los siguientes componentes en orden:

1. **OpenShift GitOps Operator** (sync_wave: 0)
2. **Namespaces** (sync_wave: 1)
3. **Operators** (sync_wave: 2)
   - Red Hat Build of Keycloak
   - Red Hat Connectivity Link Operator
   - Red Hat Developer Hub
   - Service Mesh Operator
   - Dev Spaces Operator
   - OpenShift Pipelines Operator
4. **Developer Hub** (sync_wave: 2)
5. **Service Mesh & RHCL** (sync_wave: 3)
6. **NeuralBank Stack** (sync_wave: 5)
7. **Workshop Pipelines** (sync_wave: 5)
8. **DotNet Demo** (sync_wave: 6)
9. **LibreChat** (sync_wave: 7)
10. **Dev Spaces** (sync_wave: 7)

## Monitoreo del Progreso

### Durante la Instalación

El script mostrará el progreso en tiempo real. Una vez completado, puedes monitorear con:

```bash
# Ver todas las aplicaciones
oc get applications -n openshift-gitops

# Monitorear en tiempo real
oc get applications -n openshift-gitops -w

# Ver detalles de una aplicación específica
oc get application <app-name> -n openshift-gitops -o yaml
```

### Interfaz Web de ArgoCD

Accede a la interfaz web de ArgoCD:

```bash
# Obtener la URL de ArgoCD
oc get route argocd-server -n openshift-gitops -o jsonpath='{.spec.host}'

# O abrir directamente en el navegador
oc get route argocd-server -n openshift-gitops
```

Luego accede a: `https://<argocd-route>`

## Solución de Problemas

### El script falla al verificar autenticación

```bash
# Asegúrate de estar autenticado
oc login <cluster-url>
```

### El script no puede detectar el dominio del cluster

El script te pedirá que ingreses el dominio manualmente. Puedes obtenerlo con:

```bash
oc get ingress.config/cluster -o jsonpath='{.spec.domain}'
```

### El operador de GitOps no se instala

Verifica que tengas acceso al catálogo de operadores:

```bash
oc get catalogsource -n openshift-marketplace | grep redhat-operators
```

### Las aplicaciones no se sincronizan

1. Verifica que ArgoCD esté funcionando:
   ```bash
   oc get pods -n openshift-gitops
   ```

2. Verifica los logs de ArgoCD:
   ```bash
   oc logs -n openshift-gitops -l app.kubernetes.io/name=argocd-server --tail=50
   ```

3. Verifica que el repositorio esté accesible desde ArgoCD

## Restaurar el Archivo Original

Si necesitas restaurar el `applicationset-instance.yaml` original:

```bash
# El script crea un backup automáticamente
cp applicationset-instance.yaml.backup applicationset-instance.yaml
```

## Desinstalación

Para desinstalar todos los componentes, usa el script de desinstalación:

```bash
chmod +x uninstall-applicationset.sh
./uninstall-applicationset.sh
```

## Notas Importantes

- ⏱️ La instalación completa puede tomar **15-30 minutos** dependiendo del cluster
- 🔐 Asegúrate de tener permisos de **cluster-admin**
- 🌐 El script actualiza automáticamente los dominios en `applicationset-instance.yaml`
- 💾 Se crea un backup automático antes de modificar el archivo
- 📝 Después de la instalación, necesitarás configurar manualmente Keycloak (ver README.md)

## Siguiente Paso Después de la Instalación

Una vez que la instalación esté completa, sigue las instrucciones en el [README.md](README.md) para:

1. Configurar Keycloak Client Settings
2. Crear la Route para el Gateway
3. Verificar que todo esté funcionando
