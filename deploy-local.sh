#!/bin/bash
set -e

HUB_IP="10.10.10.110"
BRIDGE_DIR="$HOME/hub-bridge"
BRIDGE_DATA="$HOME/bridge-data"
HUB_DATA="$HOME/hub-data"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

step() { echo; echo "==============================================================="; echo "  $*"; echo "==============================================================="; }

# ---------------------------------------------------------------------------
step "1/5  Clone & build hub-bridge"
# ---------------------------------------------------------------------------
if [ ! -d "$BRIDGE_DIR" ]; then
    git clone https://github.com/firerpa/hub-bridge "$BRIDGE_DIR"
fi
docker build -t hub-bridge "$BRIDGE_DIR"

# ---------------------------------------------------------------------------
step "2/5  Initialize hub-bridge (one-time only)"
# ---------------------------------------------------------------------------
mkdir -p "$BRIDGE_DATA"

if [ ! -f "$BRIDGE_DATA/environment" ]; then
    docker run -it --rm \
        -v "$BRIDGE_DATA:/data" \
        --network host \
        hub-bridge bash -c "
            # Force local IP instead of fetching from ipv4.ip.sb
            sed -i '/ipv4.ip.sb/c\\IPV4=${HUB_IP}' /service/setup.sh
            # Disable IPv6 detection
            sed -i '/ipv6.ip.sb/c\\IPV6=' /service/setup.sh
            bash /service/setup.sh
        "
else
    echo "Already initialized — skipping (delete $BRIDGE_DATA to redo)"
fi

# ---------------------------------------------------------------------------
step "3/5  Write .env with TOP credentials"
# ---------------------------------------------------------------------------
source "$BRIDGE_DATA/environment"
# pub.der is written by setup.sh to /data (= $BRIDGE_DATA on host)
CKEY=$(cat "$BRIDGE_DATA/pub.der" | base64 -w0)

cat > "$SCRIPT_DIR/.env" <<EOF
WEB_PORT=8000
DOMAIN=${HUB_IP}
API_PORT=65000
TOP_ENDPOINT=http://127.0.0.1:${API}
TOP_CLIENT_KEY=${CKEY}
TOP_SECRET=${SECRET}
EOF

echo "Credentials written to $SCRIPT_DIR/.env"
echo
echo "  TOP_ENDPOINT  = http://127.0.0.1:${API}"
echo "  TOP_SECRET    = ${SECRET}"
echo "  TOP_CLIENT_KEY= ${CKEY:0:40}..."

# ---------------------------------------------------------------------------
step "4/5  Build hub"
# ---------------------------------------------------------------------------
cd "$SCRIPT_DIR"
if ! img_exists hub || [ "$REBUILD_HUB" = "1" ]; then
    docker build -t hub .
else
    echo "Image hub already exists — skipping (use --rebuild-hub to force)"
fi

# ---------------------------------------------------------------------------
step "5/5  Start all services"
# ---------------------------------------------------------------------------
mkdir -p "$HUB_DATA"
docker compose up -d

echo
echo "================================================================"
echo "  Hub dashboard  →  http://${HUB_IP}:8000"
echo "  Login          →  admin / ******firerpa"
echo "================================================================"
echo
