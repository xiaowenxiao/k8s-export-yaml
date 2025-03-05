#!/bin/bash

set -o pipefail

DRY_RUN=false
NAMESPACE=""
OUTPUT_DIR=""

BOLD=$(tput bold)
GREEN=$(tput setaf 2)
YELLOW=$(tput setaf 3)
RED=$(tput setaf 1)
BLUE=$(tput setaf 4)
MAGENTA=$(tput setaf 5)
CYAN=$(tput setaf 6)
RESET=$(tput sgr0)

declare -A RESOURCE_COUNTS

usage() {
    echo "Usage: $0 [-n namespace] [-o output-dir] [--dry-run]"
    echo
    echo "Options:"
    echo "  -n, --namespace    Target Kubernetes namespace (required)"
    echo "  -o, --output       Output directory for YAML files (default: ./<namespace>)"
    echo "  --dry-run          Preview mode without actual export"
    exit 1
}

log_info() {
    printf "${BOLD}${CYAN}==>${RESET} ${BOLD}%s${RESET}\n" "$1"
}

log_warn() {
    printf "${BOLD}${YELLOW}==> WARNING:${RESET} %s\n" "$1"
}

log_error() {
    printf "${BOLD}${RED}==> ERROR:${RESET} %s\n" "$1" >&2
}

log_step() {
    printf "${BOLD}${BLUE}==>${RESET} ${BOLD}${MAGENTA}%s${RESET}\n" "$1"
}

log_success() {
    printf "${BOLD}${GREEN}==> SUCCESS:${RESET} %s\n" "$1"
}

validate_namespace() {
    if ! kubectl get namespace "${NAMESPACE}" > /dev/null 2>&1; then
        log_error "Namespace ${NAMESPACE} does not exist"
        exit 1
    fi
}

export_resource_yaml() {
    local resource_type=$1
    local output_subdir=$2
    local del_fields=$3
    local api_group=${4:-""}
    
    log_step "Processing ${resource_type} resources..."
    
    local full_resource_type="${resource_type}"
    if [ -n "${api_group}" ]; then
        full_resource_type="${resource_type}.${api_group}"
    fi
    
    if ! kubectl get "${full_resource_type}" -n "${NAMESPACE}" > /dev/null 2>&1; then
        log_warn "No ${resource_type} resources found in ${NAMESPACE}"
        return
    fi
    
    local resources
    resources=$(kubectl get "${full_resource_type}" -n "${NAMESPACE}" --no-headers -o custom-columns=":metadata.name" 2>/dev/null | grep -v '^$')
    
    if [ -z "${resources}" ]; then
        log_warn "No ${resource_type} resources found in ${NAMESPACE}"
        return
    fi
    
    local count=$(echo "${resources}" | wc -l)
    RESOURCE_COUNTS["${resource_type}"]=$count
    
    local full_output_dir="${OUTPUT_DIR}/${output_subdir}"
    mkdir -p "${full_output_dir}"
    
    echo "${resources}" | while read -r resource; do
        [ -z "${resource}" ] && continue
        
        local output_file="${full_output_dir}/${resource}.yaml"
        log_info "Exporting ${resource_type}/${resource} → ${output_file}"
        
        if ${DRY_RUN}; then
            log_info "[Dry Run] Would create ${output_file}"
            continue
        fi
        
        if kubectl get "${full_resource_type}" "${resource}" -n "${NAMESPACE}" -o yaml 2>/dev/null | yq eval "${del_fields}" > "${output_file}"; then
            true
        else
            log_warn "Failed to export ${resource_type}/${resource} - resource may have been deleted"
            rm -f "${output_file}"
            ((RESOURCE_COUNTS["${resource_type}"]--))
        fi
    done
}

export_deployment_yaml() {
    export_resource_yaml "deployment" "deployment" '
        del(
            .metadata.annotations,
            .metadata.creationTimestamp,
            .metadata.generation,
            .metadata.resourceVersion,
            .metadata.selfLink,
            .metadata.uid, 
            .metadata.managedFields,
            .spec.progressDeadlineSeconds,
            .spec.strategy,
            .spec.revisionHistoryLimit,
            .spec.template.metadata.creationTimestamp,
            .spec.template.metadata.annotations,
            .spec.template.spec.containers[].terminationMessagePath,
            .spec.template.spec.containers[].terminationMessagePolicy,
            .spec.template.spec.containers[].securityContext,
            .status
        )' "apps"
}

export_service_yaml() {
    export_resource_yaml "service" "service" '
        del(
            .metadata.annotations,
            .metadata.creationTimestamp,
            .metadata.resourceVersion,
            .metadata.selfLink,
            .metadata.uid, 
            .metadata.ownerReferences,
            .metadata.managedFields,
            .spec.clusterIPs,
            .spec.clusterIP,
            .spec.externalTrafficPolicy,
            .status
        )'
}

export_ingress_yaml() {
    export_resource_yaml "ingress" "ingress" '
        del(
            .metadata.annotations."kubectl.kubernetes.io/last-applied-configuration",
            .metadata.creationTimestamp,
            .metadata.finalizers,
            .metadata.generation,
            .metadata.resourceVersion,
            .metadata.selfLink,
            .metadata.uid,
            .metadata.managedFields,
            .metadata.annotations."field.cattle.io/publicEndpoints",
            .status
        )' "networking.k8s.io"
}

export_configmap_yaml() {
    export_resource_yaml "configmap" "configmap" '
        del(
            .metadata.annotations,
            .metadata.creationTimestamp,
            .metadata.resourceVersion,
            .metadata.selfLink,
            .metadata.managedFields,
            .metadata.uid
        )'
}

export_secret_yaml() {
    export_resource_yaml "secret" "secret" '
        del(
            .metadata.creationTimestamp,
            .metadata.resourceVersion,
            .metadata.selfLink,
            .metadata.annotations,
            .metadata.managedFields,
            .metadata.uid
        )'
}

export_pv_yaml() {
    export_resource_yaml "pv" "pv" '
        del(
            .metadata.annotations,
            .metadata.creationTimestamp,
            .metadata.resourceVersion,
            .metadata.selfLink,
            .metadata.managedFields,
            .metadata.uid,
            .status
        )'
}

export_pvc_yaml() {
    export_resource_yaml "pvc" "pvc" '
        del(
            .metadata.annotations,
            .metadata.creationTimestamp,
            .metadata.resourceVersion,
            .metadata.selfLink,
            .metadata.managedFields,
            .metadata.uid,
            .status
        )'
}

export_storageclass_yaml() {
    export_resource_yaml "storageclass" "storageclass" '
        del(
            .metadata.annotations,
            .metadata.creationTimestamp,
            .metadata.resourceVersion,
            .metadata.selfLink,
            .metadata.managedFields,
            .metadata.uid
        )'
}

export_daemonset_yaml() {
    export_resource_yaml "daemonset" "daemonset" '
        del(
            .metadata.annotations,
            .metadata.creationTimestamp,
            .metadata.generation,
            .metadata.resourceVersion,
            .metadata.selfLink,
            .metadata.uid, 
            .metadata.managedFields,
            .spec.revisionHistoryLimit,
            .spec.template.metadata.creationTimestamp,
            .spec.template.metadata.annotations,
            .spec.template.spec.containers[].terminationMessagePath,
            .spec.template.spec.containers[].terminationMessagePolicy,
            .spec.template.spec.containers[].securityContext,
            .status
        )' "apps"
}

export_statefulset_yaml() {
    export_resource_yaml "statefulset" "statefulset" '
        del(
            .metadata.annotations,
            .metadata.creationTimestamp,
            .metadata.generation,
            .metadata.resourceVersion,
            .metadata.selfLink,
            .metadata.uid, 
            .metadata.managedFields,
            .spec.revisionHistoryLimit,
            .spec.template.metadata.creationTimestamp,
            .spec.template.metadata.annotations,
            .spec.template.spec.containers[].terminationMessagePath,
            .spec.template.spec.containers[].terminationMessagePolicy,
            .spec.template.spec.containers[].securityContext,
            .status
        )' "apps"
}

export_job_yaml() {
    export_resource_yaml "job" "job" '
        del(
            .metadata.annotations,
            .metadata.creationTimestamp,
            .metadata.generation,
            .metadata.resourceVersion,
            .metadata.selfLink,
            .metadata.uid, 
            .metadata.managedFields,
            .spec.template.metadata.creationTimestamp,
            .spec.template.metadata.annotations,
            .spec.template.spec.containers[].terminationMessagePath,
            .spec.template.spec.containers[].terminationMessagePolicy,
            .spec.template.spec.containers[].securityContext,
            .status
        )' "batch"
}

while [[ $# -gt 0 ]]; do
    case $1 in
        -n|--namespace)
            shift
            NAMESPACE=$1
            shift
            ;;
        -o|--output)
            shift
            OUTPUT_DIR=$1
            shift
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        -h|--help)
            usage
            ;;
        *)
            usage
            ;;
    esac
done

if [[ -z "${NAMESPACE}" ]]; then
    log_error "Namespace is required"
    usage
fi

# Set default output directory if not specified
if [[ -z "${OUTPUT_DIR}" ]]; then
    OUTPUT_DIR="./${NAMESPACE}"
fi

validate_namespace

export_deployment_yaml
export_service_yaml
export_ingress_yaml
export_configmap_yaml
export_secret_yaml
export_pv_yaml
export_pvc_yaml
export_storageclass_yaml
export_daemonset_yaml
export_statefulset_yaml
export_job_yaml

log_success "All resources exported from namespace ${NAMESPACE}"
echo
printf "${BOLD}Resource Statistics:${RESET}\n"
for resource_type in "${!RESOURCE_COUNTS[@]}"; do
    printf "  %-15s ${BLUE}%d${RESET}\n" "${resource_type}:" "${RESOURCE_COUNTS[$resource_type]}"
done
echo
printf "${BOLD}${GREEN}✔${RESET} ${BOLD}Export complete${RESET}\n"
printf "  Namespace: ${BLUE}%s${RESET}\n" "${NAMESPACE}"
printf "  Directory: ${BLUE}%s${RESET}\n" "${OUTPUT_DIR}"
echo
