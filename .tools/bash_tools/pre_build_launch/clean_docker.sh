echo "Releasing Docker memory..."

docker image prune -a -f # >/dev/null2>&1

echo ""
echo "################################"
echo ""