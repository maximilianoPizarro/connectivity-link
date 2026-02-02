#!/bin/bash

# Script para desinstalar aplicaciones y operadores generados por applicationset-instance.yaml
# Autor: Generado para connectivity-link
# Uso: ./uninstall-applicationset.sh [--dry-run] [--force] [--clean-all]

set -euo pipefail

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Variables
APPLICATIONSET_NAMESPACE="openshift-gitops"
DRY_RUN=false
FORCE=false
CLEAN_ALL=false

# ApplicationSets a eliminar (en orden inverso de creación)
declare -a APPLICATIONSETS=(
    "librechat-helm"
    "connectivity-apps-helm-external"
    "connectivity-infra-all-in-one"
)

# Aplicaciones en orden inverso de sync_wave para desinstalación
# Orden: sync_wave 7 -> 6 -> 5 -> 4 -> 3 -> 2 -> 1 -> 0
declare -a APPLICATIONS=(
    # Applications sync_wave 7
    "librechat"
    "devspaces"
    # Applications sync_wave 6
    "dotnet-demo"
    # Applications sync_wave 5
    "neuralbank-stack"
    "workshop-pipelines"
    # Applications sync_wave 3
    "developer-hub"
    # Applications sync_wave 2
    "servicemeshoperator3"
    "rhcl-operator"
    "rhbk"
    "workshop-pipelines-rbac"
    # Applications sync_wave 1
    "operators"
    # Applications sync_wave 0
    "namespaces"
    "openshift-gitops"
)

# Namespaces a limpiar (si --clean-all)
declare -a NAMESPACES_TO_CLEAN=(
    "neuralbank-stack"
    "workshop-pipelines"
    "developer-hub"
    "rhbk-operator"
    "rhdh-operator"
    "kuadrant-operator"
    "istio-system"
    "dotnet-demo"
    "librechat"
    "devspaces"
    "nexus2"
)

# Subscriptions a eliminar (si --clean-all)
declare -a SUBSCRIPTIONS=(
    "rhcl-operator"
    "servicemeshoperator3"
    "devspaces"
    "openshift-pipelines-operator-rh"
    "rhbk-operator"
    "rhdh-operator"
    "kubernetes-imagepuller-operator"
)

# Funciones de utilidad
print_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_header() {
    echo -e "\n${BLUE}════════════════════════════════════════${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}════════════════════════════════════════${NC}\n"
}

# Verificar dependencias
check_dependencies() {
    print_info "Verificando dependencias..."
    
    if ! command -v oc &> /dev/null; then
        print_error "oc (OpenShift CLI) no está instalado o no está en PATH"
        exit 1
    fi
    
    if ! oc whoami &> /dev/null; then
        print_error "No hay sesión activa de OpenShift. Ejecuta 'oc login' primero"
        exit 1
    fi
    
    print_success "Dependencias verificadas"
}

# Verificar que existen ApplicationSets
check_applicationsets() {
    local found=false
    for aset in "${APPLICATIONSETS[@]}"; do
        if oc get applicationset "${aset}" -n "${APPLICATIONSET_NAMESPACE}" &> /dev/null; then
            found=true
            break
        fi
    done
    
    if [ "$found" = false ]; then
        print_warning "No se encontraron ApplicationSets en namespace '${APPLICATIONSET_NAMESPACE}'"
        return 1
    fi
    return 0
}

# Listar ApplicationSets existentes
list_applicationsets() {
    print_info "ApplicationSets encontrados:"
    for aset in "${APPLICATIONSETS[@]}"; do
        if oc get applicationset "${aset}" -n "${APPLICATIONSET_NAMESPACE}" &> /dev/null; then
            echo "  - ${aset}"
        fi
    done
}

# Eliminar aplicación de ArgoCD
delete_application() {
    local app_name=$1
    local namespace=$2
    
    print_info "Eliminando aplicación: ${app_name}"
    
    if [ "$DRY_RUN" = true ]; then
        print_warning "[DRY-RUN] Se eliminaría: oc delete application ${app_name} -n ${namespace}"
        return 0
    fi
    
    if oc get application "${app_name}" -n "${namespace}" &> /dev/null; then
        # Primero, deshabilitar sync automático y finalizar sync
        oc patch application "${app_name}" -n "${namespace}" \
            --type=json \
            -p='[{"op": "remove", "path": "/spec/syncPolicy"}]' 2>/dev/null || true
        
        # Esperar a que termine cualquier sync en progreso
        print_info "Esperando a que termine cualquier sync en progreso..."
        local timeout=60
        local elapsed=0
        while [ $elapsed -lt $timeout ]; do
            local status=$(oc get application "${app_name}" -n "${namespace}" -o jsonpath='{.status.sync.status}' 2>/dev/null || echo "Unknown")
            if [ "$status" != "Syncing" ]; then
                break
            fi
            sleep 2
            elapsed=$((elapsed + 2))
        done
        
        # Eliminar la aplicación
        oc delete application "${app_name}" -n "${namespace}" --wait=true --timeout=120s
        
        # Esperar a que los recursos se eliminen
        print_info "Esperando a que los recursos se eliminen..."
        sleep 5
        
        print_success "Aplicación ${app_name} eliminada"
    else
        print_warning "Aplicación ${app_name} no existe, omitiendo"
    fi
}

# Eliminar ApplicationSets
delete_applicationsets() {
    print_header "Eliminando ApplicationSets"
    
    for aset in "${APPLICATIONSETS[@]}"; do
        if [ "$DRY_RUN" = true ]; then
            if oc get applicationset "${aset}" -n "${APPLICATIONSET_NAMESPACE}" &> /dev/null; then
                print_warning "[DRY-RUN] Se eliminaría: oc delete applicationset ${aset} -n ${APPLICATIONSET_NAMESPACE}"
            fi
            continue
        fi
        
        if oc get applicationset "${aset}" -n "${APPLICATIONSET_NAMESPACE}" &> /dev/null; then
            print_info "Eliminando ApplicationSet: ${aset}"
            oc delete applicationset "${aset}" -n "${APPLICATIONSET_NAMESPACE}" --wait=true --timeout=60s || true
            print_success "ApplicationSet ${aset} eliminado"
        else
            print_warning "ApplicationSet ${aset} no existe, omitiendo"
        fi
    done
}

# Eliminar ConsoleLinks
delete_consolelinks() {
    print_header "Eliminando ConsoleLinks"
    
    declare -a consolelinks=(
        "openshift-gitops"
        "connectivity-link"
        "devspaces"
    )
    
    for cl in "${consolelinks[@]}"; do
        if [ "$DRY_RUN" = true ]; then
            if oc get consolelink "${cl}" &> /dev/null; then
                print_warning "[DRY-RUN] Se eliminaría: oc delete consolelink ${cl}"
            fi
            continue
        fi
        
        if oc get consolelink "${cl}" &> /dev/null; then
            print_info "Eliminando ConsoleLink: ${cl}"
            oc delete consolelink "${cl}" --wait=true --timeout=30s || true
            print_success "ConsoleLink ${cl} eliminado"
        else
            print_warning "ConsoleLink ${cl} no existe, omitiendo"
        fi
    done
}

# Limpiar subscriptions de operadores
clean_subscriptions() {
    if [ "$CLEAN_ALL" != true ]; then
        return 0
    fi
    
    print_header "Limpiando Subscriptions de Operadores"
    
    for sub in "${SUBSCRIPTIONS[@]}"; do
        print_info "Eliminando subscription: ${sub}"
        
        if [ "$DRY_RUN" = true ]; then
            print_warning "[DRY-RUN] Se eliminaría subscription ${sub} del namespace openshift-operators"
            continue
        fi
        
        if oc get subscription "${sub}" -n openshift-operators &> /dev/null; then
            oc delete subscription "${sub}" -n openshift-operators --wait=true --timeout=60s || true
            print_success "Subscription ${sub} eliminada"
        else
            print_warning "Subscription ${sub} no existe, omitiendo"
        fi
    done
}

# Limpiar namespaces
clean_namespaces() {
    if [ "$CLEAN_ALL" != true ]; then
        return 0
    fi
    
    print_header "Limpiando Namespaces"
    
    for ns in "${NAMESPACES_TO_CLEAN[@]}"; do
        print_info "Eliminando namespace: ${ns}"
        
        if [ "$DRY_RUN" = true ]; then
            print_warning "[DRY-RUN] Se eliminaría namespace ${ns}"
            continue
        fi
        
        if oc get namespace "${ns}" &> /dev/null; then
            # Intentar eliminar el namespace (puede tomar tiempo si hay finalizers)
            oc delete namespace "${ns}" --wait=false --timeout=30s || true
            print_info "Comando de eliminación enviado para namespace ${ns} (puede tomar tiempo)"
        else
            print_warning "Namespace ${ns} no existe, omitiendo"
        fi
    done
}

# Mostrar ayuda
show_help() {
    cat << EOF
Uso: $0 [OPCIONES]

Desinstala las aplicaciones y operadores generados por applicationset-instance.yaml

OPCIONES:
    --dry-run       Muestra qué se haría sin ejecutar cambios
    --force         Omite confirmaciones interactivas
    --clean-all     Limpia también subscriptions y namespaces (más agresivo)
    -h, --help      Muestra esta ayuda

EJEMPLOS:
    $0                    # Desinstalación normal con confirmación
    $0 --dry-run          # Ver qué se eliminaría sin hacer cambios
    $0 --force            # Desinstalación sin confirmaciones
    $0 --clean-all        # Desinstalación completa incluyendo limpieza de recursos

EOF
}

# Parsear argumentos
parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --dry-run)
                DRY_RUN=true
                shift
                ;;
            --force)
                FORCE=true
                shift
                ;;
            --clean-all)
                CLEAN_ALL=true
                shift
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            *)
                print_error "Opción desconocida: $1"
                show_help
                exit 1
                ;;
        esac
    done
}

# Confirmación del usuario
confirm_action() {
    if [ "$FORCE" = true ]; then
        return 0
    fi
    
    echo ""
    print_warning "Esta acción eliminará:"
    echo ""
    print_info "ApplicationSets:"
    for aset in "${APPLICATIONSETS[@]}"; do
        if oc get applicationset "${aset}" -n "${APPLICATIONSET_NAMESPACE}" &> /dev/null; then
            echo "  - ${aset}"
        fi
    done
    echo ""
    print_info "Aplicaciones de ArgoCD:"
    for app in "${APPLICATIONS[@]}"; do
        echo "  - ${app}"
    done
    echo ""
    
    if [ "$CLEAN_ALL" = true ]; then
        print_warning "Modo --clean-all activado: también se eliminarán:"
        echo "  - ConsoleLinks"
        echo "  - Subscriptions de operadores"
        echo "  - Namespaces"
    fi
    
    if [ "$DRY_RUN" = true ]; then
        print_info "Modo DRY-RUN: no se realizarán cambios reales"
        return 0
    fi
    
    read -p "¿Continuar? (s/N): " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Ss]$ ]]; then
        print_info "Operación cancelada"
        exit 0
    fi
}

# Función principal
main() {
    print_header "Desinstalación de Connectivity Link Demo"
    
    parse_arguments "$@"
    check_dependencies
    
    # Listar ApplicationSets existentes
    list_applicationsets
    
    if ! check_applicationsets && [ "$DRY_RUN" = false ]; then
        print_warning "No se encontraron ApplicationSets. Verificando si hay aplicaciones huérfanas..."
    fi
    
    confirm_action
    
    # Eliminar aplicaciones en orden inverso
    print_header "Eliminando Aplicaciones de ArgoCD"
    for app in "${APPLICATIONS[@]}"; do
        # Determinar el namespace basado en el nombre de la aplicación
        local namespace="${APPLICATIONSET_NAMESPACE}"
        case $app in
            "rhbk")
                namespace="rhbk-operator"
                ;;
            "developer-hub")
                namespace="developer-hub"
                ;;
            "servicemeshoperator3"|"rhcl-operator")
                namespace="openshift-operators"
                ;;
            "neuralbank-stack")
                namespace="neuralbank-stack"
                ;;
            "workshop-pipelines"|"workshop-pipelines-rbac")
                namespace="workshop-pipelines"
                ;;
            "dotnet-demo")
                namespace="dotnet-demo"
                ;;
            "librechat"|"librechat-rbac")
                namespace="librechat"
                ;;
            "devspaces")
                namespace="devspaces"
                ;;
            "openshift-gitops"|"namespaces"|"operators")
                namespace="openshift-gitops"
                ;;
            *)
                namespace="${APPLICATIONSET_NAMESPACE}"
                ;;
        esac
        
        delete_application "${app}" "${namespace}"
    done
    
    # Eliminar ApplicationSets
    delete_applicationsets
    
    # Eliminar ConsoleLinks
    delete_consolelinks
    
    # Limpieza adicional si se solicita
    if [ "$CLEAN_ALL" = true ]; then
        clean_subscriptions
        clean_namespaces
    fi
    
    print_header "Desinstalación Completada"
    print_success "Todas las aplicaciones han sido eliminadas"
    
    if [ "$CLEAN_ALL" = true ]; then
        print_warning "Nota: Los namespaces pueden tardar en eliminarse completamente debido a finalizers"
        print_info "Puedes verificar el estado con: oc get namespaces"
    fi
}

# Ejecutar función principal
main "$@"