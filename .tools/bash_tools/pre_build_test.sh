#!/bin/bash

# Lightweight checks performed immediately before looking for/building the image.
# Usage: pre_build_test.sh <docker_tag>

docker_tag="${1:-}"

print_error() {
    echo ""
    echo "------------------------------------"
    echo "Pre-build check failed"
    echo "$1"
    if [ -n "${2:-}" ]; then
        echo ""
        echo "Details:"
        echo "$2"
    fi
    echo "------------------------------------"
}

echo "Pre-build checks:"

# 1. Docker must be installed and the daemon must answer.
if ! command -v docker >/dev/null 2>&1; then
    print_error "Docker could not be found. Please make sure Docker is installed and try again."
    exit 1
fi

if ! docker info >/dev/null 2>&1; then
    print_error "Docker is installed, but it is not responding. Please start or restart Docker Desktop/Docker and try again."
    exit 1
fi

echo "  [OK] Docker is responding."

# 2. Let Docker itself validate the image reference. A valid tag that does not
#    exist locally returns 'No such image', which is fine at this stage.
if [ -z "$docker_tag" ]; then
    print_error "The Docker image tag is empty. Please check the selected notebook configuration."
    exit 1
fi

# Docker references cannot contain whitespace or control characters. This also
# catches accidental Windows carriage returns (\r) before they reach Docker.
if [[ "$docker_tag" =~ [[:space:][:cntrl:]] ]]; then
    print_error "The Docker image tag contains an invalid whitespace or hidden character. Please check the selected notebook configuration." "$docker_tag"
    exit 1
fi

tag_check=$(docker image inspect "$docker_tag" 2>&1)
tag_status=$?

if [ "$tag_status" -ne 0 ] && printf '%s\n' "$tag_check" | grep -Eqi 'invalid (reference format|tag|repository name)'; then
    print_error "The Docker image tag is not valid. Please check the selected notebook configuration." "$docker_tag"
    exit 1
fi

echo "  [OK] Docker image tag is valid."
echo "Pre-build checks: OK"
echo ""

exit 0
