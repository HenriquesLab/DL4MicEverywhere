#!/bin/bash

# Reclaim Docker disk space using the same conservative policy for both the
# automatic startup cleanup and the manual GUI action.
#
# Removed resources are limited to items older than 24 hours:
# - stopped containers
# - networks not used by any container
# - dangling images
# - unused build cache
#
# Volumes are intentionally NOT pruned.

echo "Releasing Docker disk space ..."
echo "Only unused Docker resources older than 24 hours will be removed."
echo "Docker volumes are not removed."
echo ""

if ! docker info >/dev/null 2>&1; then
    echo "ERROR: Docker is not available to the current user." >&2
    echo "Start Docker Desktop (or the Docker daemon) and try again." >&2
    exit 1
fi

if ! docker system prune -f --filter "until=24h"; then
    echo "ERROR: Docker cleanup failed." >&2
    exit 1
fi

echo ""
echo "Docker cleanup completed successfully."
echo ""
echo "################################"
echo ""
