#!/bin/bash

# Lightweight smoke tests performed after an image has been built/pulled.
# Usage: post_build_test.sh <docker_tag>

docker_tag="${1:-}"

print_error() {
    echo ""
    echo "------------------------------------"
    echo "Post-build check failed"
    echo "$1"
    if [ -n "${2:-}" ]; then
        echo ""
        echo "Details:"
        printf '%s\n' "$2"
    fi
    echo "------------------------------------"
}

run_container_check() {
    label="$1"
    message="$2"
    shift 2

    output=$(docker run --rm "$docker_tag" "$@" 2>&1)
    status=$?

    if [ "$status" -ne 0 ]; then
        print_error "$message" "$output"
        return 1
    fi

    echo "  [OK] $label"
    return 0
}

if [ -z "$docker_tag" ]; then
    print_error "The Docker image tag is empty, so the image cannot be verified."
    exit 1
fi

echo "Post-build checks:"

run_container_check \
    "Python starts correctly." \
    "Python could not be started inside the Docker image." \
    python --version || exit 1

run_container_check \
    "Python packages are consistent." \
    "Python reported missing or incompatible package dependencies." \
    python -m pip check || exit 1

run_container_check \
    "Jupyter starts correctly." \
    "Jupyter could not be started inside the Docker image." \
    jupyter --version || exit 1

echo "Post-build checks: OK"
echo ""

exit 0
