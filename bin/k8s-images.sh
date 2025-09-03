#!/bin/bash

set -euo pipefail

# Script to extract unique container images from Kubernetes deployments and statefulsets

readonly SCRIPT_NAME=$(basename "$0")

# Global variables
declare -a KUBECTL_ARGS=()
PREFIX=""

show_help() {
    cat << EOF
Usage: $SCRIPT_NAME [kubectl-options] [prefix]

Extract unique container images from Kubernetes deployments and statefulsets.

Options:
  -h, --help              Show this help message
  
Kubectl options:
  --context CONTEXT       Kubernetes context to use
  --namespace NAMESPACE   Kubernetes namespace (default: all namespaces in current context)  
  -n NAMESPACE           Short form of --namespace
  --kubeconfig PATH      Path to kubeconfig file
  --cluster CLUSTER      Kubernetes cluster to use
  --user USER            Kubernetes user to use

Arguments:
  prefix                  Optional prefix to filter resource names (e.g., 'dev-', 'prod-')
                         Must be the last argument

Examples:
  $SCRIPT_NAME                                    # All images from current context
  $SCRIPT_NAME dev-                               # Images from resources starting with 'dev-'
  $SCRIPT_NAME --context production              # All images from 'production' context  
  $SCRIPT_NAME --context prod --namespace app    # Images from 'app' namespace in 'prod' context
  $SCRIPT_NAME --context staging prod-           # Images with 'prod-' prefix in 'staging' context

Output:
  One unique image per line, sorted alphabetically
  
Requirements:
  - kubectl (configured and accessible)
  - jq (JSON processor)

Exit codes:
  0 - Success
  1 - Missing dependencies or invalid arguments
  2 - kubectl command failed
  3 - No resources found
EOF
}

check_dependencies() {
    local missing_deps=()
    
    command -v kubectl >/dev/null 2>&1 || missing_deps+=("kubectl")
    command -v jq >/dev/null 2>&1 || missing_deps+=("jq")
    
    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        echo "Error: Missing required dependencies: ${missing_deps[*]}" >&2
        echo "Please install the missing tools and try again." >&2
        exit 1
    fi
}

parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            --context|--kubeconfig|--namespace|-n|--cluster|--user)
                if [[ $# -lt 2 ]]; then
                    echo "Error: $1 requires a value" >&2
                    echo "Use '$SCRIPT_NAME --help' for usage information." >&2
                    exit 1
                fi
                KUBECTL_ARGS+=("$1" "$2")
                shift 2
                ;;
            --*)
                KUBECTL_ARGS+=("$1")
                shift
                ;;
            -*)
                echo "Error: Unknown option '$1'" >&2
                echo "Use '$SCRIPT_NAME --help' for usage information." >&2
                exit 1
                ;;
            *)
                if [[ -n "$PREFIX" ]]; then
                    echo "Error: Multiple prefixes specified. Only one prefix is allowed." >&2
                    echo "Use '$SCRIPT_NAME --help' for usage information." >&2
                    exit 1
                fi
                PREFIX="$1"
                shift
                ;;
        esac
    done
}

build_jq_filter() {
    local filter='.items[]'
    
    # Add prefix filter if specified
    if [[ -n "$PREFIX" ]]; then
        filter+=" | select(.metadata.name | startswith(\"$PREFIX\"))"
    fi
    
    # Extract container image
    filter+=' | .spec.template.spec.containers[0].image'
    
    echo "$filter"
}

get_images() {
    local jq_filter
    jq_filter=$(build_jq_filter)
    
    # Build kubectl command - handle empty array properly
    local kubectl_cmd=(kubectl)
    if [[ ${#KUBECTL_ARGS[@]} -gt 0 ]]; then
        kubectl_cmd+=("${KUBECTL_ARGS[@]}")
    fi
    kubectl_cmd+=(get deployments,statefulsets -o json)
    
    # Execute kubectl command and capture both stdout and stderr
    local kubectl_output kubectl_exit_code
    kubectl_output=$("${kubectl_cmd[@]}" 2>&1)
    kubectl_exit_code=$?
    
    if [[ $kubectl_exit_code -ne 0 ]]; then
        echo "Error: kubectl command failed:" >&2
        echo "$kubectl_output" >&2
        exit 2
    fi
    
    # Process JSON output
    local images
    images=$(echo "$kubectl_output" | jq -r "$jq_filter" 2>/dev/null | sort | uniq | grep -v "^$" || true)
    
    if [[ -z "$images" ]]; then
        if [[ -n "$PREFIX" ]]; then
            echo "Warning: No resources found with prefix '$PREFIX'" >&2
        else
            echo "Warning: No deployments or statefulsets found" >&2
        fi
        exit 3
    fi
    
    echo "$images"
}

main() {
    # Check dependencies first
    check_dependencies
    
    # Parse command line arguments  
    parse_arguments "$@"
    
    # Get and output images
    get_images
}

# Run main function with all arguments
main "$@"