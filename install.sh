#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APPLICATIONSET_FILE="${SCRIPT_DIR}/applicationset-instance.yaml"
GITOPS_NAMESPACE="openshift-gitops"
GITOPS_OPERATOR_NAME="openshift-gitops-operator"
GITOPS_SUBSCRIPTION_NAME="openshift-gitops-operator"
GITOPS_CSV_PREFIX="openshift-gitops-operator"
AUTO_SYNC="${AUTO_SYNC:-false}"  # Set AUTO_SYNC=true to skip prompt and auto-sync

# Functions
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if oc is installed
check_oc_installed() {
    if ! command -v oc &> /dev/null; then
        print_error "oc (OpenShift CLI) is not installed. Please install it first."
        exit 1
    fi
    print_success "oc CLI is installed"
}

# Check if user is authenticated
check_authentication() {
    print_info "Checking OpenShift authentication..."
    if ! oc whoami &> /dev/null; then
        print_error "Not authenticated to OpenShift cluster. Please run 'oc login' first."
        exit 1
    fi
    print_success "Authenticated as: $(oc whoami)"
}

# Check if user has cluster-admin privileges
check_permissions() {
    print_info "Checking cluster-admin privileges..."
    if ! oc auth can-i '*' '*' --all-namespaces &> /dev/null; then
        print_warning "You may not have cluster-admin privileges. Some operations might fail."
        read -p "Continue anyway? (y/n) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    else
        print_success "Cluster-admin privileges confirmed"
    fi
}

# Get cluster domain
get_cluster_domain() {
    print_info "Detecting cluster domain..."
    CLUSTER_DOMAIN=$(oc get ingress.config/cluster -o jsonpath='{.spec.domain}' 2>/dev/null)
    
    if [ -z "$CLUSTER_DOMAIN" ]; then
        print_error "Could not detect cluster domain. Please provide it manually:"
        read -p "Enter cluster domain (e.g., apps.cluster-xxx.xxx.sandbox.opentlc.com): " CLUSTER_DOMAIN
        if [ -z "$CLUSTER_DOMAIN" ]; then
            print_error "Cluster domain is required. Exiting."
            exit 1
        fi
    else
        print_success "Cluster domain detected: ${CLUSTER_DOMAIN}"
    fi
    
    # Construct full domain with apps prefix
    if [[ ! "$CLUSTER_DOMAIN" =~ ^apps\. ]]; then
        APPS_DOMAIN="apps.${CLUSTER_DOMAIN}"
    else
        APPS_DOMAIN="${CLUSTER_DOMAIN}"
    fi
    
    KEYCLOAK_HOST="rhbk.${APPS_DOMAIN}"
    APP_HOST="neuralbank.${APPS_DOMAIN}"
    
    print_info "Keycloak host: ${KEYCLOAK_HOST}"
    print_info "Application host: ${APP_HOST}"
}

# Update applicationset-instance.yaml with cluster domain
update_applicationset_domain() {
    print_info "Updating applicationset-instance.yaml with cluster domain..."
    
    # Create backup
    cp "${APPLICATIONSET_FILE}" "${APPLICATIONSET_FILE}.backup"
    print_info "Backup created: ${APPLICATIONSET_FILE}.backup"
    
    # Update domain references in applicationset-instance.yaml
    # Update keycloak_host and app_host values
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        sed -i '' "s|keycloak_host: rhbk\.apps\.cluster-[^ ]*|keycloak_host: ${KEYCLOAK_HOST}|g" "${APPLICATIONSET_FILE}"
        sed -i '' "s|app_host: neuralbank\.apps\.cluster-[^ ]*|app_host: ${APP_HOST}|g" "${APPLICATIONSET_FILE}"
    else
        # Linux
        sed -i "s|keycloak_host: rhbk\.apps\.cluster-[^ ]*|keycloak_host: ${KEYCLOAK_HOST}|g" "${APPLICATIONSET_FILE}"
        sed -i "s|app_host: neuralbank\.apps\.cluster-[^ ]*|app_host: ${APP_HOST}|g" "${APPLICATIONSET_FILE}"
    fi
    
    # Verify the update was successful
    if grep -q "keycloak_host: ${KEYCLOAK_HOST}" "${APPLICATIONSET_FILE}" && \
       grep -q "app_host: ${APP_HOST}" "${APPLICATIONSET_FILE}"; then
        print_success "Updated applicationset-instance.yaml with cluster domain"
        print_info "  Keycloak host: ${KEYCLOAK_HOST}"
        print_info "  App host: ${APP_HOST}"
    else
        print_error "Failed to update applicationset-instance.yaml. Please check manually."
        exit 1
    fi
}

# Check CatalogSource health
check_catalog_source() {
    print_info "Checking CatalogSource health..."
    
    local catalog_source="redhat-operators"
    local catalog_namespace="openshift-marketplace"
    
    if ! oc get catalogsource "${catalog_source}" -n "${catalog_namespace}" &> /dev/null; then
        print_error "CatalogSource ${catalog_source} not found in namespace ${catalog_namespace}"
        return 1
    fi
    
    local catalog_status=$(oc get catalogsource "${catalog_source}" -n "${catalog_namespace}" -o jsonpath='{.status.connectionState.lastObservedState}' 2>/dev/null || echo "")
    local catalog_ready=$(oc get catalogsource "${catalog_source}" -n "${catalog_namespace}" -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' 2>/dev/null || echo "")
    local registry_service=$(oc get catalogsource "${catalog_source}" -n "${catalog_namespace}" -o jsonpath='{.spec.image}' 2>/dev/null || echo "")
    
    print_info "CatalogSource ${catalog_source} status: ${catalog_status}, Ready: ${catalog_ready}"
    print_info "Registry service: ${registry_service}"
    
    # Check CatalogSource pods
    local catalog_pods=$(oc get pods -n "${catalog_namespace}" -l olm.catalogSource="${catalog_source}" --no-headers 2>/dev/null | wc -l)
    print_info "CatalogSource pods: ${catalog_pods}"
    
    if [ "$catalog_status" != "READY" ] || [ "$catalog_ready" != "True" ]; then
        print_warning "CatalogSource ${catalog_source} is not healthy"
        print_info "Attempting to refresh CatalogSource..."
        
        # Try to delete and recreate the pod if it exists
        local catalog_pod=$(oc get pods -n "${catalog_namespace}" -l olm.catalogSource="${catalog_source}" -o name 2>/dev/null | head -n1)
        if [ -n "$catalog_pod" ]; then
            print_info "Deleting CatalogSource pod to force refresh: ${catalog_pod}"
            oc delete "${catalog_pod}" -n "${catalog_namespace}" --ignore-not-found=true
            sleep 5
        fi
        
        # Also try to force update the CatalogSource by patching it
        print_info "Forcing CatalogSource update..."
        oc patch catalogsource "${catalog_source}" -n "${catalog_namespace}" --type=merge -p '{"metadata":{"annotations":{"olm.catalogSource.forceUpdate":"'$(date +%s)'"}}}' 2>/dev/null || true
        sleep 3
        
        # Wait a bit for pod to restart
        print_info "Waiting for CatalogSource to become ready..."
        local max_wait=30
        local wait_count=0
        while [ $wait_count -lt $max_wait ]; do
            catalog_status=$(oc get catalogsource "${catalog_source}" -n "${catalog_namespace}" -o jsonpath='{.status.connectionState.lastObservedState}' 2>/dev/null || echo "")
            catalog_ready=$(oc get catalogsource "${catalog_source}" -n "${catalog_namespace}" -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' 2>/dev/null || echo "")
            if [ "$catalog_status" == "READY" ] && [ "$catalog_ready" == "True" ]; then
                print_success "CatalogSource is now ready"
                return 0
            fi
            wait_count=$((wait_count + 1))
            echo -n "."
            sleep 2
        done
        echo
        print_warning "CatalogSource may still not be ready, but continuing..."
        
        # Show pod status for debugging
        print_info "CatalogSource pod status:"
        oc get pods -n "${catalog_namespace}" -l olm.catalogSource="${catalog_source}" || true
    else
        print_success "CatalogSource ${catalog_source} is healthy"
    fi
    
    return 0
}

# Fix subscription if it has issues
fix_subscription() {
    local subscription_name="${GITOPS_SUBSCRIPTION_NAME}"
    local namespace="openshift-operators"
    
    print_info "Checking subscription for issues..."
    
    # Check for CatalogSourcesUnhealthy condition
    local unhealthy=$(oc get subscription "${subscription_name}" -n "${namespace}" -o jsonpath='{.status.conditions[?(@.type=="CatalogSourcesUnhealthy")].status}' 2>/dev/null || echo "")
    local resolution_failed=$(oc get subscription "${subscription_name}" -n "${namespace}" -o jsonpath='{.status.conditions[?(@.type=="ResolutionFailed")].status}' 2>/dev/null || echo "")
    local install_plan=$(oc get subscription "${subscription_name}" -n "${namespace}" -o jsonpath='{.status.installPlanRef.name}' 2>/dev/null || echo "")
    
    if [ "$unhealthy" == "True" ] || ([ "$resolution_failed" == "True" ] && [ -z "$install_plan" ]); then
        print_warning "Subscription has issues: CatalogSourcesUnhealthy=${unhealthy}, ResolutionFailed=${resolution_failed}, InstallPlan=${install_plan}"
        print_info "Attempting to fix by deleting and recreating subscription..."
        
        # Delete the subscription and any related InstallPlans
        print_info "Deleting subscription and related resources..."
        oc delete subscription "${subscription_name}" -n "${namespace}" --ignore-not-found=true
        
        # Also delete any failed InstallPlans
        local failed_plans=$(oc get installplan -n "${namespace}" -l operators.coreos.com/${subscription_name}.${namespace}="" -o name 2>/dev/null || echo "")
        if [ -n "$failed_plans" ]; then
            print_info "Cleaning up old InstallPlans..."
            echo "$failed_plans" | xargs -r oc delete -n "${namespace}" --ignore-not-found=true
        fi
        
        sleep 5
        
        # Also check and ensure OperatorGroup exists
        if ! oc get operatorgroup -n "${namespace}" | grep -q "global-operators"; then
            print_info "Creating OperatorGroup for ${namespace}..."
            cat <<EOF | oc apply -f -
apiVersion: operators.coreos.com/v1alpha2
kind: OperatorGroup
metadata:
  name: global-operators
  namespace: ${namespace}
spec: {}
EOF
            sleep 2
        fi
        
        # Recreate it
        print_info "Recreating subscription..."
        cat <<EOF | oc apply -f -
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: ${subscription_name}
  namespace: ${namespace}
spec:
  channel: stable
  name: ${GITOPS_OPERATOR_NAME}
  source: redhat-operators
  sourceNamespace: openshift-marketplace
  installPlanApproval: Automatic
EOF
        print_success "Subscription recreated"
        
        # Force CatalogSource refresh again after recreating subscription
        print_info "Forcing CatalogSource refresh after subscription recreation..."
        oc patch catalogsource redhat-operators -n openshift-marketplace --type=merge -p '{"metadata":{"annotations":{"olm.catalogSource.forceUpdate":"'$(date +%s)'"}}}' 2>/dev/null || true
        
        # Wait a bit longer for OLM to process
        print_info "Waiting for OLM to process subscription..."
        sleep 15
        
        # Check if CatalogSource is still healthy
        local catalog_status=$(oc get catalogsource redhat-operators -n openshift-marketplace -o jsonpath='{.status.connectionState.lastObservedState}' 2>/dev/null || echo "")
        if [ "$catalog_status" != "READY" ]; then
            print_warning "CatalogSource became unhealthy again. This may indicate a network or connectivity issue."
        fi
        
        # Check if InstallPlan was created
        local new_install_plan=$(oc get subscription "${subscription_name}" -n "${namespace}" -o jsonpath='{.status.installPlanRef.name}' 2>/dev/null || echo "")
        if [ -n "$new_install_plan" ]; then
            print_success "InstallPlan created: ${new_install_plan}"
        else
            print_warning "InstallPlan not yet created, but subscription is recreated"
        fi
        
        return 0
    fi
    
    return 0
}

# Install OpenShift GitOps Operator
install_gitops_operator() {
    print_info "Installing OpenShift GitOps Operator..."
    
    # Check CatalogSource first
    check_catalog_source
    
    # Check if operator is already installed
    if oc get subscription "${GITOPS_SUBSCRIPTION_NAME}" -n openshift-operators &> /dev/null; then
        print_warning "OpenShift GitOps Operator subscription already exists"
        
        # Check if subscription has issues and try to fix
        fix_subscription
    else
        # Create namespace if it doesn't exist
        oc create namespace openshift-operators --dry-run=client -o yaml | oc apply -f -
        
        # Create OperatorGroup if it doesn't exist
        if ! oc get operatorgroup -n openshift-operators | grep -q "global-operators"; then
            print_info "Creating OperatorGroup for openshift-operators..."
            cat <<EOF | oc apply -f -
apiVersion: operators.coreos.com/v1alpha2
kind: OperatorGroup
metadata:
  name: global-operators
  namespace: openshift-operators
spec: {}
EOF
        fi
        
        # Create Subscription
        print_info "Creating OpenShift GitOps Operator subscription..."
        cat <<EOF | oc apply -f -
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: ${GITOPS_SUBSCRIPTION_NAME}
  namespace: openshift-operators
spec:
  channel: stable
  name: ${GITOPS_OPERATOR_NAME}
  source: redhat-operators
  sourceNamespace: openshift-marketplace
  installPlanApproval: Automatic
EOF
        print_success "OpenShift GitOps Operator subscription created"
    fi
}

# Wait for GitOps operator to be ready
wait_for_gitops_operator() {
    print_info "Waiting for OpenShift GitOps Operator to be ready..."
    
    local max_attempts=60
    local attempt=0
    
    # First, check subscription status
    if ! oc get subscription "${GITOPS_SUBSCRIPTION_NAME}" -n openshift-operators &> /dev/null; then
        print_error "Subscription ${GITOPS_SUBSCRIPTION_NAME} not found!"
        print_info "Checking if subscription was created..."
        oc get subscription -n openshift-operators
        return 1
    fi
    
        # Check subscription conditions
        SUBSCRIPTION_CONDITIONS=$(oc get subscription "${GITOPS_SUBSCRIPTION_NAME}" -n openshift-operators -o jsonpath='{.status.conditions[*].type}:{.status.conditions[*].status}' 2>/dev/null || echo "")
        CATALOG_UNHEALTHY=$(oc get subscription "${GITOPS_SUBSCRIPTION_NAME}" -n openshift-operators -o jsonpath='{.status.conditions[?(@.type=="CatalogSourcesUnhealthy")].status}' 2>/dev/null || echo "")
        RESOLUTION_FAILED=$(oc get subscription "${GITOPS_SUBSCRIPTION_NAME}" -n openshift-operators -o jsonpath='{.status.conditions[?(@.type=="ResolutionFailed")].status}' 2>/dev/null || echo "")
        
        print_info "Subscription status: ${SUBSCRIPTION_CONDITIONS}"
        
        # If CatalogSource is unhealthy or no InstallPlan after many attempts, try to fix it
        if [ "$CATALOG_UNHEALTHY" == "True" ] && [ $attempt -ge 12 ] && [ $((attempt % 12)) -eq 0 ]; then
            echo
            print_warning "CatalogSource is unhealthy after ${attempt} attempts. Attempting to fix..."
            check_catalog_source
            fix_subscription
            echo -n "Retrying"
        elif [ -z "$CSV_NAME" ] && [ -z "$INSTALL_PLAN" ] && [ $attempt -ge 24 ] && [ $((attempt % 12)) -eq 0 ]; then
            echo
            print_warning "No InstallPlan created after ${attempt} attempts. Attempting to fix subscription..."
            fix_subscription
            echo -n "Retrying"
        fi
    
    while [ $attempt -lt $max_attempts ]; do
        # Check if CSV is installed and ready
        CSV_NAME=$(oc get csv -n openshift-operators -o name | grep "${GITOPS_CSV_PREFIX}" | head -n1 | cut -d'/' -f2 2>/dev/null || echo "")
        
        if [ -n "$CSV_NAME" ]; then
            CSV_PHASE=$(oc get csv "$CSV_NAME" -n openshift-operators -o jsonpath='{.status.phase}' 2>/dev/null || echo "")
            CSV_MESSAGE=$(oc get csv "$CSV_NAME" -n openshift-operators -o jsonpath='{.status.message}' 2>/dev/null || echo "")
            
            if [ "$CSV_PHASE" == "Succeeded" ]; then
                print_success "OpenShift GitOps Operator is ready (CSV: ${CSV_NAME})"
                return 0
            elif [ "$CSV_PHASE" == "Failed" ]; then
                echo
                print_error "CSV ${CSV_NAME} is in Failed state!"
                print_info "CSV Message: ${CSV_MESSAGE}"
                print_info "Checking CSV conditions..."
                oc get csv "$CSV_NAME" -n openshift-operators -o yaml | grep -A 10 "conditions:" || true
                return 1
            elif [ "$CSV_PHASE" == "Installing" ] || [ "$CSV_PHASE" == "PendingInstall" ]; then
                # Still installing, continue waiting
                if [ $((attempt % 6)) -eq 0 ]; then
                    echo -n " [${CSV_PHASE}]"
                fi
            else
                # Other phase, show it
                if [ $((attempt % 6)) -eq 0 ]; then
                    echo -n " [${CSV_PHASE}]"
                fi
            fi
        else
            # No CSV yet, check subscription and InstallPlan
            INSTALL_PLAN=$(oc get subscription "${GITOPS_SUBSCRIPTION_NAME}" -n openshift-operators -o jsonpath='{.status.installPlanRef.name}' 2>/dev/null || echo "")
            if [ -n "$INSTALL_PLAN" ]; then
                INSTALL_PLAN_APPROVAL=$(oc get installplan "$INSTALL_PLAN" -n openshift-operators -o jsonpath='{.spec.approved}' 2>/dev/null || echo "")
                INSTALL_PLAN_PHASE=$(oc get installplan "$INSTALL_PLAN" -n openshift-operators -o jsonpath='{.status.phase}' 2>/dev/null || echo "")
                if [ $((attempt % 6)) -eq 0 ]; then
                    echo -n " [InstallPlan: ${INSTALL_PLAN} - Approved: ${INSTALL_PLAN_APPROVAL}, Phase: ${INSTALL_PLAN_PHASE}]"
                fi
            else
                if [ $((attempt % 6)) -eq 0 ]; then
                    echo -n " [No InstallPlan yet]"
                fi
            fi
        fi
        
        attempt=$((attempt + 1))
        echo -n "."
        sleep 5
    done
    
    echo
    print_warning "OpenShift GitOps Operator may not be fully ready after ${max_attempts} attempts"
    
    # Show diagnostic information
    print_info "Diagnostic information:"
    echo "--- Subscription Status ---"
    oc get subscription "${GITOPS_SUBSCRIPTION_NAME}" -n openshift-operators -o yaml | grep -A 30 "status:" || true
    echo ""
    echo "--- Subscription Conditions ---"
    oc get subscription "${GITOPS_SUBSCRIPTION_NAME}" -n openshift-operators -o jsonpath='{range .status.conditions[*]}{.type}={.status} {.message}{"\n"}{end}' || true
    echo ""
    echo "--- CSV Status ---"
    oc get csv -n openshift-operators | grep "${GITOPS_CSV_PREFIX}" || print_warning "No CSV found"
    echo ""
    echo "--- InstallPlan Status ---"
    oc get installplan -n openshift-operators | grep -i gitops || print_warning "No InstallPlan found"
    if [ -n "$INSTALL_PLAN" ]; then
        echo "InstallPlan details:"
        oc get installplan "$INSTALL_PLAN" -n openshift-operators -o yaml | grep -A 20 "status:" || true
    fi
    echo ""
    echo "--- CatalogSource Status ---"
    oc get catalogsource redhat-operators -n openshift-marketplace -o yaml | grep -A 10 "status:" || true
    echo ""
    echo "--- OperatorGroup Status ---"
    oc get operatorgroup -n openshift-operators || print_warning "No OperatorGroup found"
    echo ""
    echo "--- CatalogSource Pod Logs (last 20 lines) ---"
    local catalog_pod=$(oc get pods -n openshift-marketplace -l olm.catalogSource=redhat-operators -o name 2>/dev/null | head -n1)
    if [ -n "$catalog_pod" ]; then
        oc logs "${catalog_pod}" -n openshift-marketplace --tail=20 || true
    else
        print_warning "No CatalogSource pod found"
    fi
    echo ""
    print_info "If the problem persists, try manually:"
    print_info "  1. Check CatalogSource: oc get catalogsource redhat-operators -n openshift-marketplace -o yaml"
    print_info "  2. Check subscription: oc get subscription ${GITOPS_SUBSCRIPTION_NAME} -n openshift-operators -o yaml"
    print_info "  3. Check OLM operator logs: oc logs -n openshift-operator-lifecycle-manager -l app=catalog-operator --tail=50"
    print_info "  4. Try installing via OpenShift Console: Operators → OperatorHub → OpenShift GitOps"
    
    print_warning "Continuing anyway, but operator may not be ready..."
}

# Wait for GitOps namespace and ArgoCD instance
wait_for_gitops_namespace() {
    print_info "Waiting for ${GITOPS_NAMESPACE} namespace to be created..."
    
    local max_attempts=30
    local attempt=0
    
    while [ $attempt -lt $max_attempts ]; do
        if oc get namespace "${GITOPS_NAMESPACE}" &> /dev/null; then
            print_success "Namespace ${GITOPS_NAMESPACE} exists"
            return 0
        fi
        
        attempt=$((attempt + 1))
        echo -n "."
        sleep 5
    done
    
    echo
    print_warning "Namespace ${GITOPS_NAMESPACE} not found. Creating it..."
    oc create namespace "${GITOPS_NAMESPACE}" || true
}

# Wait for ArgoCD server to be ready
wait_for_argocd_server() {
    print_info "Waiting for ArgoCD server to be ready..."
    
    local max_attempts=60
    local attempt=0
    
    while [ $attempt -lt $max_attempts ]; do
        if oc get deployment argocd-server -n "${GITOPS_NAMESPACE}" &> /dev/null; then
            READY_REPLICAS=$(oc get deployment argocd-server -n "${GITOPS_NAMESPACE}" -o jsonpath='{.status.readyReplicas}' 2>/dev/null || echo "0")
            if [ "$READY_REPLICAS" == "1" ]; then
                print_success "ArgoCD server is ready"
                return 0
            fi
        fi
        
        attempt=$((attempt + 1))
        echo -n "."
        sleep 5
    done
    
    echo
    print_warning "ArgoCD server may not be fully ready, but continuing..."
}

# Enable ConsoleLinks for GitOps and Connectivity Link
enable_consolelinks() {
    print_info "Enabling ConsoleLinks to show GitOps and Connectivity Link in OpenShift console menu..."
    
    # Get cluster domain
    local cluster_domain=$(oc get ingress.config/cluster -o jsonpath='{.spec.domain}' 2>/dev/null || echo "")
    if [ -z "$cluster_domain" ]; then
        print_warning "Could not detect cluster domain. ConsoleLinks may not work correctly."
        return 1
    fi
    
    # Determine apps domain
    local apps_domain="$cluster_domain"
    if [[ ! "$cluster_domain" =~ ^apps\. ]]; then
        apps_domain="apps.${cluster_domain}"
    fi
    
    # Get ArgoCD route
    local argocd_route=$(oc get route -n "${GITOPS_NAMESPACE}" -o jsonpath='{.items[?(@.metadata.name=="openshift-gitops-server")].spec.host}' 2>/dev/null || echo "")
    if [ -z "$argocd_route" ]; then
        argocd_route=$(oc get route -n "${GITOPS_NAMESPACE}" -o jsonpath='{.items[?(@.metadata.name=="argocd-server")].spec.host}' 2>/dev/null || echo "")
    fi
    
    # If route not found, construct expected route
    if [ -z "$argocd_route" ]; then
        argocd_route="openshift-gitops-server-${GITOPS_NAMESPACE}.${apps_domain}"
        print_info "ArgoCD route not found, using expected route: ${argocd_route}"
    fi
    
    # Get NeuralBank route (Connectivity Link app)
    local neuralbank_route=$(oc get route -n neuralbank-stack -o jsonpath='{.items[?(@.metadata.name=="neuralbank")].spec.host}' 2>/dev/null || echo "")
    
    # If route not found, construct expected route
    if [ -z "$neuralbank_route" ]; then
        neuralbank_route="neuralbank.${apps_domain}"
        print_info "NeuralBank route not found, using expected route: ${neuralbank_route}"
    fi
    
    # Create ConsoleLink for OpenShift GitOps
    print_info "Creating ConsoleLink for OpenShift GitOps..."
    if oc get consolelink openshift-gitops &>/dev/null; then
        print_info "ConsoleLink 'openshift-gitops' already exists, updating..."
        oc patch consolelink openshift-gitops --type merge -p "{\"spec\":{\"href\":\"https://${argocd_route}\"}}" &>/dev/null
        if [ $? -eq 0 ]; then
            print_success "ConsoleLink for OpenShift GitOps updated"
        else
            print_warning "Failed to update ConsoleLink for OpenShift GitOps"
        fi
    else
        cat <<EOF | oc apply -f -
apiVersion: console.openshift.io/v1
kind: ConsoleLink
metadata:
  name: openshift-gitops
spec:
  href: https://${argocd_route}
  location: ApplicationMenu
  applicationMenu:
    section: GitOps
  text: OpenShift GitOps
EOF
        if [ $? -eq 0 ]; then
            print_success "ConsoleLink for OpenShift GitOps created"
        else
            print_warning "Failed to create ConsoleLink for OpenShift GitOps"
        fi
    fi
    
    # Create ConsoleLink for Connectivity Link
    print_info "Creating ConsoleLink for Connectivity Link..."
    if oc get consolelink connectivity-link &>/dev/null; then
        print_info "ConsoleLink 'connectivity-link' already exists, updating..."
        oc patch consolelink connectivity-link --type merge -p "{\"spec\":{\"href\":\"https://${neuralbank_route}\"}}" &>/dev/null
        if [ $? -eq 0 ]; then
            print_success "ConsoleLink for Connectivity Link updated"
        else
            print_warning "Failed to update ConsoleLink for Connectivity Link"
        fi
    else
        cat <<EOF | oc apply -f -
apiVersion: console.openshift.io/v1
kind: ConsoleLink
metadata:
  name: connectivity-link
spec:
  href: https://${neuralbank_route}
  location: ApplicationMenu
  applicationMenu:
    section: Connectivity Link
  text: Connectivity Link
EOF
        if [ $? -eq 0 ]; then
            print_success "ConsoleLink for Connectivity Link created"
        else
            print_warning "Failed to create ConsoleLink for Connectivity Link"
        fi
    fi
    
    print_info ""
    print_success "ConsoleLinks enabled! They will appear in the OpenShift console Application Menu:"
    print_info "  - GitOps section: OpenShift GitOps → https://${argocd_route}"
    print_info "  - Connectivity Link section: Connectivity Link → https://${neuralbank_route}"
    print_info ""
    print_info "Note: ConsoleLinks are cluster-scoped resources and will be visible to all users."
}

# Wait for operators to be ready
wait_for_operators() {
    print_info "Waiting for operators to be installed and ready..."
    print_info "This ensures operators are ready before applications (sync_wave 5-7) are instantiated"
    
    # List of operators to check with their namespaces
    # Format: "operator-name:namespace"
    local operators=(
        "openshift-pipelines-operator-rh:openshift-operators"
        "servicemeshoperator:openshift-operators"
        "rhcl-operator:openshift-operators"
        "devspaces:openshift-operators"
        "rhbk-operator:rhbk-operator"
        "rhdh-operator:rhdh-operator"
    )
    
    local max_wait=600  # 10 minutes max (operators can take time)
    local wait_time=0
    local all_ready=false
    local total_count=${#operators[@]}
    
    while [ $wait_time -lt $max_wait ] && [ "$all_ready" == "false" ]; do
        all_ready=true
        local ready_count=0
        
        for operator_ns in "${operators[@]}"; do
            IFS=':' read -r operator namespace <<< "$operator_ns"
            
            # Check if CSV exists and is Succeeded
            CSV_NAME=$(oc get csv -n "$namespace" -o name 2>/dev/null | grep -i "$operator" | head -n1 | cut -d'/' -f2 || echo "")
            if [ -n "$CSV_NAME" ]; then
                CSV_PHASE=$(oc get csv "$CSV_NAME" -n "$namespace" -o jsonpath='{.status.phase}' 2>/dev/null || echo "")
                if [ "$CSV_PHASE" == "Succeeded" ]; then
                    ready_count=$((ready_count + 1))
                else
                    all_ready=false
                fi
            else
                # Check if subscription exists (operator may not be installed yet)
                if oc get subscription "$operator" -n "$namespace" &> /dev/null; then
                    all_ready=false
                fi
            fi
        done
        
        if [ "$all_ready" == "true" ] && [ $ready_count -eq $total_count ]; then
            print_success "All operators are ready (${ready_count}/${total_count})"
            print_info "Operators are now ready. Applications (sync_wave 5-7) can be instantiated."
            return 0
        fi
        
        if [ $((wait_time % 30)) -eq 0 ]; then
            print_info "Waiting for operators... (${ready_count}/${total_count} ready, ${wait_time}s elapsed)"
        fi
        
        wait_time=$((wait_time + 5))
        sleep 5
    done
    
    if [ "$all_ready" == "false" ]; then
        print_warning "Some operators may not be fully ready, but continuing..."
        print_info "Operator status:"
        for operator_ns in "${operators[@]}"; do
            IFS=':' read -r operator namespace <<< "$operator_ns"
            CSV_NAME=$(oc get csv -n "$namespace" -o name 2>/dev/null | grep -i "$operator" | head -n1 | cut -d'/' -f2 || echo "")
            if [ -n "$CSV_NAME" ]; then
                CSV_PHASE=$(oc get csv "$CSV_NAME" -n "$namespace" -o jsonpath='{.status.phase}' 2>/dev/null || echo "Unknown")
                print_info "  $operator ($namespace): $CSV_PHASE"
            else
                SUBSCRIPTION_EXISTS=$(oc get subscription "$operator" -n "$namespace" &> /dev/null && echo "Subscription exists" || echo "Not found")
                print_info "  $operator ($namespace): $SUBSCRIPTION_EXISTS"
            fi
        done
        print_info ""
        print_info "Applications will continue to deploy, but may wait for operators to be ready."
    fi
}

# Apply applicationset-instance.yaml
apply_applicationset() {
    print_info "Applying applicationset-instance.yaml..."
    
    if [ ! -f "${APPLICATIONSET_FILE}" ]; then
        print_error "File ${APPLICATIONSET_FILE} not found!"
        exit 1
    fi
    
    # Wait a bit more to ensure GitOps is ready
    print_info "Waiting for ArgoCD to be fully ready..."
    sleep 15
    
    # Verify ArgoCD is accessible
    if ! oc get applicationset -n "${GITOPS_NAMESPACE}" &> /dev/null; then
        print_warning "Cannot access ApplicationSet resource. ArgoCD may still be initializing..."
        sleep 10
    fi
    
    if oc apply -f "${APPLICATIONSET_FILE}"; then
        print_success "ApplicationSet applied successfully"
    else
        print_error "Failed to apply applicationset-instance.yaml"
        exit 1
    fi
    
    # Wait for ApplicationSet to be processed
    print_info "Waiting for ApplicationSet to be processed..."
    sleep 10
    
    # Verify ApplicationSet was created
    if oc get applicationset -n "${GITOPS_NAMESPACE}" &> /dev/null; then
        print_info "ApplicationSet resources:"
        oc get applicationset -n "${GITOPS_NAMESPACE}" || true
    else
        print_warning "Could not verify ApplicationSet creation"
    fi
    
    # Note: Operators will be installed by ArgoCD based on sync_wave 2-3
    # We'll wait for them in the main flow after applications are created
    print_info ""
    print_info "ApplicationSet applied. Operators will be installed via sync_wave 2-3."
    print_info "Waiting for applications to be created by ApplicationSet..."
}

# Monitor ApplicationSet progress
monitor_progress() {
    print_info "Monitoring ApplicationSet progress..."
    
    # Wait a moment for applications to be created
    print_info "Waiting for applications to be created by ApplicationSet..."
    sleep 20
    
    # Check ApplicationSet status
    print_info "ApplicationSet status:"
    oc get applicationset -n "${GITOPS_NAMESPACE}" -o wide 2>/dev/null || print_warning "Could not get ApplicationSet status"
    
    print_info ""
    print_info "Current Application status:"
    APPLICATIONS=$(oc get applications -n "${GITOPS_NAMESPACE}" 2>/dev/null || echo "")
    if [ -n "$APPLICATIONS" ]; then
        oc get applications -n "${GITOPS_NAMESPACE}" || true
        APP_COUNT=$(oc get applications -n "${GITOPS_NAMESPACE}" --no-headers 2>/dev/null | wc -l || echo "0")
        print_success "Found ${APP_COUNT} application(s)"
    else
        print_warning "No applications found yet. They may still be creating..."
        print_info "Checking ApplicationSet controller logs..."
        oc logs -n "${GITOPS_NAMESPACE}" -l app.kubernetes.io/name=argocd-applicationset-controller --tail=20 2>/dev/null || print_warning "Could not get ApplicationSet controller logs"
    fi
    
    # Check if repository is accessible
    print_info ""
    print_info "Verifying repository access..."
    REPO_URL=$(grep -A 5 "repoURL:" "${APPLICATIONSET_FILE}" | head -1 | sed 's/.*repoURL:.*\(https[^ ]*\).*/\1/' | tr -d "'" || echo "")
    if [ -n "$REPO_URL" ]; then
        print_info "Repository URL: ${REPO_URL}"
        # Try to verify repository is accessible (basic check)
        if echo "$REPO_URL" | grep -q "github.com"; then
            print_info "GitHub repository detected. Verifying access..."
            # Could add curl check here if needed
        fi
    fi
    
    print_info ""
    print_info "To monitor progress, run:"
    print_info "  oc get applications -n ${GITOPS_NAMESPACE} -w"
    print_info "  oc get applicationset -n ${GITOPS_NAMESPACE} -w"
    print_info ""
    print_info "To check ApplicationSet controller logs:"
    print_info "  oc logs -n ${GITOPS_NAMESPACE} -l app.kubernetes.io/name=argocd-applicationset-controller --tail=50 -f"
    print_info ""
    print_info "Or access ArgoCD UI:"
    # Try different route names
    ARGOCD_ROUTE=$(oc get route -n "${GITOPS_NAMESPACE}" -o jsonpath='{.items[?(@.metadata.name=="argocd-server")].spec.host}' 2>/dev/null || echo "")
    if [ -z "$ARGOCD_ROUTE" ]; then
        ARGOCD_ROUTE=$(oc get route -n "${GITOPS_NAMESPACE}" -o jsonpath='{.items[?(@.metadata.name=="openshift-gitops-server")].spec.host}' 2>/dev/null || echo "")
    fi
    if [ -z "$ARGOCD_ROUTE" ]; then
        ARGOCD_ROUTE=$(oc get route -n "${GITOPS_NAMESPACE}" -o jsonpath='{.items[0].spec.host}' 2>/dev/null || echo "")
    fi
    
    if [ -n "$ARGOCD_ROUTE" ]; then
        print_success "  https://${ARGOCD_ROUTE}"
        print_info "  Default username: admin"
        # Try different secret names for password
        ARGOCD_PASSWORD=$(oc extract secret/openshift-gitops-cluster -n "${GITOPS_NAMESPACE}" --to=- 2>/dev/null | grep "admin.password" | cut -d'=' -f2 || echo "")
        if [ -z "$ARGOCD_PASSWORD" ]; then
            ARGOCD_PASSWORD=$(oc get secret openshift-gitops-cluster -n "${GITOPS_NAMESPACE}" -o jsonpath='{.data.admin\.password}' 2>/dev/null | base64 -d || echo "")
        fi
        if [ -n "$ARGOCD_PASSWORD" ]; then
            print_info "  Password: ${ARGOCD_PASSWORD}"
        else
            print_info "  Get password with: oc get secret openshift-gitops-cluster -n ${GITOPS_NAMESPACE} -o jsonpath='{.data.admin\.password}' | base64 -d"
        fi
    else
        print_warning "  Route not found. ArgoCD may still be deploying..."
        print_info "  Check with: oc get route -n ${GITOPS_NAMESPACE}"
        print_info "  Or check ArgoCD instance: oc get argocd -n ${GITOPS_NAMESPACE}"
    fi
    
    # Show sync status summary
    print_info ""
    OUT_OF_SYNC=$(oc get applications -n "${GITOPS_NAMESPACE}" --no-headers 2>/dev/null | grep -c "OutOfSync" || echo "0")
    MISSING=$(oc get applications -n "${GITOPS_NAMESPACE}" --no-headers 2>/dev/null | grep -c "Missing" || echo "0")
    SYNCED=$(oc get applications -n "${GITOPS_NAMESPACE}" --no-headers 2>/dev/null | grep -c "Synced" || echo "0")
    
    if [ "$OUT_OF_SYNC" -gt 0 ] || [ "$MISSING" -gt 0 ]; then
        print_warning "Some applications need synchronization:"
        print_info "  OutOfSync: ${OUT_OF_SYNC}"
        print_info "  Missing: ${MISSING}"
        print_info "  Synced: ${SYNCED}"
        print_info ""
        
        # Ask if user wants to sync automatically (or use AUTO_SYNC env var)
        if [ "$AUTO_SYNC" == "true" ]; then
            SYNC_APPS=true
        elif [ -t 0 ]; then
            read -p "Do you want to sync all applications now? (y/n) " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                SYNC_APPS=true
            else
                SYNC_APPS=false
            fi
        else
            SYNC_APPS=false
        fi
        
        if [ "$SYNC_APPS" == "true" ]; then
            print_info "Syncing all applications..."
            SYNCED_COUNT=0
            FAILED_COUNT=0
            
            for app in $(oc get applications -n "${GITOPS_NAMESPACE}" -o jsonpath='{.items[*].metadata.name}'); do
                SYNC_STATUS=$(oc get application "$app" -n "${GITOPS_NAMESPACE}" -o jsonpath='{.status.sync.status}' 2>/dev/null || echo "")
                if [ "$SYNC_STATUS" != "Synced" ]; then
                    if oc patch application "$app" -n "${GITOPS_NAMESPACE}" --type merge -p '{"operation":{"initiatedBy":{"username":"admin"},"sync":{"revision":"HEAD"}}}' &> /dev/null; then
                        SYNCED_COUNT=$((SYNCED_COUNT + 1))
                        print_info "  ✓ Synced: $app"
                    else
                        FAILED_COUNT=$((FAILED_COUNT + 1))
                        print_warning "  ✗ Failed to sync: $app"
                    fi
                fi
            done
            
            print_info ""
            if [ "$SYNCED_COUNT" -gt 0 ]; then
                print_success "Successfully initiated sync for ${SYNCED_COUNT} application(s)"
            fi
            if [ "$FAILED_COUNT" -gt 0 ]; then
                print_warning "Failed to sync ${FAILED_COUNT} application(s)"
            fi
            
            print_info "Waiting for sync to complete..."
            sleep 10
            
            # Show updated status
            print_info ""
            print_info "Updated Application status:"
            oc get applications -n "${GITOPS_NAMESPACE}" || true
        else
            print_info "Skipping automatic sync. You can sync manually later."
            print_info ""
            print_info "To sync all applications:"
            print_info "  oc get applications -n ${GITOPS_NAMESPACE} -o name | xargs -I {} oc patch {} -n ${GITOPS_NAMESPACE} --type merge -p '{\"operation\":{\"initiatedBy\":{\"username\":\"admin\"},\"sync\":{\"revision\":\"HEAD\"}}}'"
        fi
        
        print_info ""
        print_info "Or sync individual applications:"
        print_info "  oc patch application <app-name> -n ${GITOPS_NAMESPACE} --type merge -p '{\"operation\":{\"initiatedBy\":{\"username\":\"admin\"},\"sync\":{\"revision\":\"HEAD\"}}}'"
        print_info ""
        print_info "Or use ArgoCD CLI:"
        print_info "  argocd app sync <app-name>"
        print_info "  argocd app sync --all"
    else
        print_success "All applications are synced!"
    fi
}

# Check if Ansible is installed
check_ansible_installed() {
    if ! command -v ansible-playbook &> /dev/null; then
        print_error "ansible-playbook is not installed. Please install Ansible first:"
        print_info "  pip install ansible kubernetes"
        print_info "  or: dnf install ansible python3-kubernetes"
        exit 1
    fi
    print_success "Ansible is installed"
}

# Install GitOps Operator using Ansible
install_gitops_with_ansible() {
    print_info "Installing OpenShift GitOps Operator using Ansible..."
    
    local ansible_playbook="${SCRIPT_DIR}/install-gitops.yaml"
    
    if [ ! -f "${ansible_playbook}" ]; then
        print_error "Ansible playbook not found: ${ansible_playbook}"
        exit 1
    fi
    
    # Export cluster domain if detected
    if [ -n "$CLUSTER_DOMAIN" ]; then
        export CLUSTER_DOMAIN
    fi
    
    if ansible-playbook -i localhost, -c local "${ansible_playbook}"; then
        print_success "OpenShift GitOps Operator installed successfully via Ansible"
        return 0
    else
        print_error "Failed to install OpenShift GitOps Operator with Ansible"
        exit 1
    fi
}

# Main installation flow
main() {
    echo "=========================================="
    echo "  Connectivity Link Installation Script  "
    echo "=========================================="
    echo ""
    
    # Pre-flight checks
    check_oc_installed
    check_authentication
    check_permissions
    check_ansible_installed
    
    # Get cluster domain
    get_cluster_domain
    
    # Update applicationset with domain
    update_applicationset_domain
    
    echo ""
    print_info "Starting installation process..."
    echo ""
    
    # Step 1: Install GitOps Operator and deploy operators/applications using Ansible
    print_info "Step 1/4: Installing OpenShift GitOps Operator and deploying operators/applications (using Ansible)"
    install_gitops_with_ansible
    
    # Step 2: Operators and Applications are now handled by Ansible playbook
    print_info ""
    print_info "Step 2/4: Operators and Applications will be installed by Ansible playbook"
    print_info "The Ansible playbook will:"
    print_info "  1. Apply operators ApplicationSet"
    print_info "  2. Wait for all operators to be ready"
    print_info "  3. Apply applications ApplicationSet"
    print_info ""
    print_info "Note: This step is handled automatically by the Ansible playbook."
    
    # Step 3: Enable ConsoleLinks for GitOps and Connectivity Link
    print_info ""
    print_info "Step 3/4: Enabling ConsoleLinks for GitOps and Connectivity Link"
    enable_consolelinks
    
    # Monitor progress
    echo ""
    monitor_progress
    
    echo ""
    print_success "Installation process completed!"
    print_info "The ApplicationSet will now deploy all components via GitOps."
    print_info "This may take several minutes. Monitor progress in ArgoCD UI."
    echo ""
}

# Run main function
main
