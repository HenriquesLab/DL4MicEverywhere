echo "Releasing Docker memory ..."

# This will remove:
# - all stopped containers
# - all networks not used by at least one container
# - all dangling images
# - unused build cache

# This will only be applied to items older than 24 hours
docker system prune -f --filter "until=24h" # >/dev/null2>&1

echo ""
echo "################################"
echo ""