#!/bin/bash

set -e

# Colors for output
BOLD="\033[1m"
GREEN="\033[0;32m"
YELLOW="\033[0;33m"
RED="\033[0;31m"
BLUE="\033[0;34m"
RESET="\033[0m"

log_info() {
    printf "${BOLD}${BLUE}==>${RESET} ${BOLD}%s${RESET}\n" "$1"
}

log_success() {
    printf "${BOLD}${GREEN}==> SUCCESS:${RESET} %s\n" "$1"
}

log_error() {
    printf "${BOLD}${RED}==> ERROR:${RESET} %s\n" "$1" >&2
}

check_dependencies() {
    if ! command -v kubectl &> /dev/null; then
        log_error "kubectl is not installed. Please install kubectl first."
        exit 1
    fi
}

install_yq_from_local() {
    log_info "Installing yq from local package..."
    
    if [ ! -f "install_yq/yq_linux_amd64.tar.gz" ]; then
        log_error "Local yq package not found: install_yq/yq_linux_amd64.tar.gz"
        exit 1
    fi
    
    # Extract yq binary from tar.gz
    if tar -xzf "install_yq/yq_linux_amd64.tar.gz" -C /tmp; then
        mv /tmp/yq_linux_amd64 /usr/local/bin/yq
        chmod +x /usr/local/bin/yq
        log_success "yq installed successfully from local package"
    else
        log_error "Failed to extract yq from local package"
        exit 1
    fi
}

install_yq_from_remote() {
    log_info "Installing yq from remote..."
    
    # Latest yq version
    VERSION=$(curl -s https://api.github.com/repos/mikefarah/yq/releases/latest | grep '"tag_name":' | sed -E 's/.*"v([^"]+)".*/\1/')
    
    if [ -z "${VERSION}" ]; then
        log_error "Failed to get latest yq version"
        exit 1
    fi
    
    # Download URL for ARM64
    BINARY_URL="https://github.com/mikefarah/yq/releases/download/v${VERSION}/yq_linux_arm64"
    
    # Download and install yq
    if curl -L "${BINARY_URL}" -o "/usr/local/bin/yq"; then
        chmod +x "/usr/local/bin/yq"
        log_success "yq v${VERSION} installed successfully"
    else
        log_error "Failed to download yq"
        exit 1
    fi
}

install_yq() {
    # Detect architecture
    ARCH=$(uname -m)
    
    case "${ARCH}" in
        x86_64|amd64)
            install_yq_from_local
            ;;
        aarch64|arm64)
            log_info "Detected ARM64 architecture, installing from remote..."
            install_yq_from_remote
            ;;
        *)
            log_error "Unsupported architecture: ${ARCH}"
            exit 1
            ;;
    esac
}

install_k8s_export_yaml() {
    log_info "Installing k8s-export-yaml..."
    
    # Copy the script to /usr/local/bin
    if cp "k8s-export-yaml.sh" "/usr/local/bin/k8s-export-yaml"; then
        chmod +x "/usr/local/bin/k8s-export-yaml"
        log_success "k8s-export-yaml installed successfully"
    else
        log_error "Failed to install k8s-export-yaml"
        exit 1
    fi
}

main() {
    # Check if running as root
    if [ "$(id -u)" -ne 0 ]; then
        log_error "This script must be run as root (sudo)"
        exit 1
    fi
    
    # Check dependencies
    check_dependencies
    
    # Install yq if not present or update if requested
    if ! command -v yq &> /dev/null; then
        install_yq
    else
        CURRENT_VERSION=$(yq --version | awk '{print $4}')
        log_info "yq ${CURRENT_VERSION} is already installed"
        read -p "Do you want to update yq? [y/N] " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            install_yq
        fi
    fi
    
    # Install k8s-export-yaml
    install_k8s_export_yaml
    
    echo
    log_success "Installation completed successfully!"
    echo
    printf "${BOLD}Usage:${RESET}\n"
    printf "  ${BLUE}k8s-export-yaml -n <namespace>${RESET}\n"
    echo
}

main "$@" 