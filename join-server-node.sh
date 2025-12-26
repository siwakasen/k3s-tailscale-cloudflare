#!/usr/bin/env bash
set -e

# ====== CHECK DEPENDENCIES ======
if ! command -v tailscale >/dev/null 2>&1; then
  echo "❌ tailscale not found. Install and login first."
  exit 1
fi

# ====== GET TAILSCALE IP ======
TAILSCALE_IP=$(tailscale ip -4 | head -n 1)
if [ -z "$TAILSCALE_IP" ]; then
  echo "❌ Failed to get Tailscale IP"
  exit 1
fi

HOSTNAME_DEFAULT=$(hostname)
echo "✅ Tailscale IP: $TAILSCALE_IP"
echo "🖥 Default node name: $HOSTNAME_DEFAULT"

# ====== USER INPUT ======
read -rp "Enter node name (leave empty to use hostname): " NODE_NAME
if [ -z "$NODE_NAME" ]; then
  NODE_NAME="$HOSTNAME_DEFAULT"
fi

read -rp "Enter INITIAL SERVER Tailscale IP: " INITIAL_SERVER_TAILSCALE_IP
if [ -z "$INITIAL_SERVER_TAILSCALE_IP" ]; then
  echo "❌ INITIAL_SERVER_TAILSCALE_IP cannot be empty"
  exit 1
fi

read -rp "Enter K3s Token: " K3S_TOKEN
echo
if [ -z "$K3S_TOKEN" ]; then
  echo "❌ K3S token cannot be empty"
  exit 1
fi

# Create K3s config
sudo mkdir -p /etc/rancher/k3s
sudo tee /etc/rancher/k3s/config.yaml <<EOF
server: "https://${INITIAL_SERVER_TAILSCALE_IP}:6443"
token: "${K3S_TOKEN}"
node-name: "${NODE_NAME}"
node-ip: "${TAILSCALE_IP}"
node-external-ip: "${TAILSCALE_IP}"
advertise-address: "${TAILSCALE_IP}"
tls-san:
  - "${TAILSCALE_IP}"
  - "$(hostname -f)"
flannel-iface: "tailscale0"
EOF

# ====== INSTALL K3S SERVER ======
echo "🚀 Installing K3s server node..."
curl -sfL https://get.k3s.io | K3S_TOKEN="$K3S_TOKEN" sh -s - server

echo ""
echo "✅ K3s server node '$NODE_NAME' successfully joined the cluster!"
echo "📍 Node External IP: $TAILSCALE_IP"
echo "🔗 Connected to: https://${INITIAL_SERVER_TAILSCALE_IP}:6443"
