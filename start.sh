#!/bin/bash
# start.sh — everyday start of hub-bridge + hub (no rebuild)
# First time? Run ./deploy-local.sh instead
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

if [ ! -f .env ]; then
    echo "ERROR: .env not found. Run ./deploy-local.sh first."
    exit 1
fi

echo "Starting hub-bridge + hub..."
docker compose up -d

echo
docker compose ps
echo
echo "  hub  →  http://10.10.10.2:8000   (admin / firerpa)"
echo
echo "Logs:   docker logs -f hub"
echo "Stop:   docker compose down"
