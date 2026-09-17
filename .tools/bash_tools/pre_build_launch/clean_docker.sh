#!/bin/bash

# Reclaim Docker disk space without touching unrelated Docker workloads.
#
# Default cleanup is intentionally scoped to objects created by
# DL4MicEverywhere and carrying this ownership label:
#   org.dl4miceverywhere.managed=true
#
# Only objects older than 24 hours are considered. Docker volumes are never
# pruned here. Shared Docker build cache is also left alone unless the caller
# explicitly opts in with --include-build-cache.

set -u

MANAGED_LABEL="org.dl4miceverywhere.managed=true"
INCLUDE_BUILD_CACHE=0

usage() {
    cat <<'USAGE'
Usage: clean_docker.sh [--include-build-cache]

Without options, remove only unused DL4MicEverywhere-labelled Docker resources
older than 24 hours. Docker volumes and shared Docker build cache are preserved.

--include-build-cache
    Also prune unused Docker build cache older than 24 hours. Build cache is a
    Docker-wide shared resource and cannot be scoped reliably to this project.
USAGE
}

while [ "$#" -gt 0 ]; do
    case "$1" in
        --include-build-cache)
            INCLUDE_BUILD_CACHE=1
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo "ERROR: Unknown Docker cleanup option: $1" >&2
            usage >&2
            exit 2
            ;;
    esac
    shift
done

echo "Reclaiming DL4MicEverywhere Docker disk space ..."
echo "Only unused resources labelled '$MANAGED_LABEL' and older than 24 hours will be removed."
echo "Docker volumes are not removed."
if [ "$INCLUDE_BUILD_CACHE" -eq 1 ]; then
    echo "Shared Docker build cache older than 24 hours WILL also be pruned."
else
    echo "Shared Docker build cache is not removed."
fi
echo ""

if ! docker info >/dev/null 2>&1; then
    echo "ERROR: Docker is not available to the current user." >&2
    echo "Start Docker Desktop (or the Docker daemon) and try again." >&2
    exit 1
fi

run_prune() {
    local description="$1"
    shift

    echo "--- $description ---"
    if ! "$@"; then
        echo "ERROR: Docker cleanup failed while processing: $description" >&2
        return 1
    fi
    echo ""
}

# Order matters: remove stopped managed containers first so their locally-built
# managed images can become unused and eligible for image pruning.
run_prune \
    "Stopped DL4MicEverywhere containers" \
    docker container prune -f \
        --filter "label=$MANAGED_LABEL" \
        --filter "until=24h" || exit 1

# -a removes any unused managed image, not only dangling layers. The label
# filter prevents this from touching unlabelled images belonging to users or
# other applications. Pulled historical images from older releases may not have
# this label and are intentionally left untouched by routine cleanup.
run_prune \
    "Unused DL4MicEverywhere images" \
    docker image prune -a -f \
        --filter "label=$MANAGED_LABEL" \
        --filter "until=24h" || exit 1

# DL4MicEverywhere does not currently create dedicated networks, but keeping a
# labelled network prune here makes the ownership contract future-proof without
# broadening cleanup to unrelated Docker networks.
run_prune \
    "Unused DL4MicEverywhere networks" \
    docker network prune -f \
        --filter "label=$MANAGED_LABEL" \
        --filter "until=24h" || exit 1

if [ "$INCLUDE_BUILD_CACHE" -eq 1 ]; then
    echo "--- Shared Docker build cache (explicit opt-in) ---"
    echo "NOTE: Docker build cache is daemon-wide and cannot be reliably attributed"
    echo "to DL4MicEverywhere alone. Only cache older than 24 hours is considered."
    if ! docker builder prune -f --filter "until=24h"; then
        echo "ERROR: Shared Docker build-cache cleanup failed." >&2
        exit 1
    fi
    echo ""
fi

echo "Docker cleanup completed successfully."
if [ "$INCLUDE_BUILD_CACHE" -eq 1 ]; then
    echo "DL4MicEverywhere-labelled resources and opted-in shared Docker build cache were considered."
else
    echo "Only DL4MicEverywhere-labelled resources were considered."
fi
echo "Docker volumes were not removed."
echo ""
echo "################################"
echo ""
