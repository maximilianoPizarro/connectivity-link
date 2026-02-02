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

# Install OpenShift GitOps Operator
install_gitops_operator() {
    print_info "Installing OpenShift GitOps Operator..."
    
    # Check if operator is already installed
    if oc get subscription "${GITOPS_SUBSCRIPTION_NAME}" -n openshift-operators &> /dev/null; then
        print_warning "OpenShift GitOps Operator subscription already exists"
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
    
    while [ $attempt -lt $max_attempts ]; do
        # Check if CSV is installed and ready
        CSV_NAME=$(oc get csv -n openshift-operators -o name | grep "${GITOPS_CSV_PREFIX}" | head -n1 | cut -d'/' -f2 2>/dev/null || echo "")
        
        if [ -n "$CSV_NAME" ]; then
            CSV_PHASE=$(oc get csv "$CSV_NAME" -n openshift-operators -o jsonpath='{.status.phase}' 2>/dev/null || echo "")
            if [ "$CSV_PHASE" == "Succeeded" ]; then
                print_success "OpenShift GitOps Operator is ready"
                return 0
            fi
        fi
        
        attempt=$((attempt + 1))
        echo -n "."
        sleep 5
    done
    
    echo
    print_warning "OpenShift GitOps Operator may not be fully ready, but continuing..."
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

# Apply applicationset-instance.yaml
apply_applicationset() {
    print_info "Applying applicationset-instance.yaml..."
    
    if [ ! -f "${APPLICATIONSET_FILE}" ]; then
        print_error "File ${APPLICATIONSET_FILE} not found!"
        exit 1
    fi
    
    # Wait a bit more to ensure GitOps is ready
    sleep 10
    
    if oc apply -f "${APPLICATIONSET_FILE}"; then
        print_success "ApplicationSet applied successfully"
    else
        print_error "Failed to apply applicationset-instance.yaml"
        exit 1
    fi
}

# Monitor ApplicationSet progress
monitor_progress() {
    print_info "Monitoring ApplicationSet progress..."
    print_info "You can check the status in ArgoCD UI or with: oc get applications -n ${GITOPS_NAMESPACE}"
    
    # Wait a moment for applications to be created
    sleep 15
    
    # Show initial status
    print_info "Current Application status:"
    oc get applications -n "${GITOPS_NAMESPACE}" 2>/dev/null || print_warning "No applications found yet. They may still be creating..."
    
    print_info ""
    print_info "To monitor progress, run:"
    print_info "  oc get applications -n ${GITOPS_NAMESPACE} -w"
    print_info ""
    print_info "Or access ArgoCD UI:"
    ARGOCD_ROUTE=$(oc get route argocd-server -n "${GITOPS_NAMESPACE}" -o jsonpath='{.spec.host}' 2>/dev/null || echo "")
    if [ -n "$ARGOCD_ROUTE" ]; then
        print_info "  https://${ARGOCD_ROUTE}"
    else
        print_info "  (Route will be available once ArgoCD is fully deployed)"
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
    
    # Get cluster domain
    get_cluster_domain
    
    # Update applicationset with domain
    update_applicationset_domain
    
    echo ""
    print_info "Starting installation process..."
    echo ""
    
    # Step 1: Install GitOps Operator
    print_info "Step 1/4: Installing OpenShift GitOps Operator"
    install_gitops_operator
    wait_for_gitops_operator
    
    # Step 2: Wait for GitOps namespace
    print_info ""
    print_info "Step 2/4: Waiting for GitOps namespace"
    wait_for_gitops_namespace
    
    # Step 3: Wait for ArgoCD server
    print_info ""
    print_info "Step 3/4: Waiting for ArgoCD server"
    wait_for_argocd_server
    
    # Step 4: Apply ApplicationSet
    print_info ""
    print_info "Step 4/4: Applying ApplicationSet"
    apply_applicationset
    
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
