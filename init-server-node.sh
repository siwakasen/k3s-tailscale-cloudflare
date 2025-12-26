#!/usr/bin/env bash
set -e

# Get Tailscale IPv4 (take first one)
TAILSCALE_IP=$(tailscale ip -4 | head -n 1)
if [ -z "$TAILSCALE_IP" ]; then
  echo "❌ Failed to get Tailscale IP"
  exit 1
fi

HOSTNAME_DEFAULT=$(hostname)
echo "✅ Tailscale IP: $TAILSCALE_IP"
echo "🖥  Default node name: $HOSTNAME_DEFAULT"

# ====== USER INPUT ======
read -rp "Enter node name (leave empty to use hostname): " NODE_NAME
if [ -z "$NODE_NAME" ]; then
  NODE_NAME="$HOSTNAME_DEFAULT"
fi

# Create K3s config
sudo mkdir -p /etc/rancher/k3s
sudo tee /etc/rancher/k3s/config.yaml <<EOF
node-name: "${NODE_NAME}"
node-ip: "${TAILSCALE_IP}"
node-external-ip: "${TAILSCALE_IP}"
advertise-address: "${TAILSCALE_IP}"
tls-san:
  - "${TAILSCALE_IP}"
  - "$(hostname -f)"
cluster-init: true
flannel-iface: "tailscale0"
etcd-expose-metrics: true
EOF

curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="server --cluster-init" sh -

echo "✅ K3s cluster initialized successfully"
echo "🛠️ KUBECONFIG: /etc/rancher/k3s/k3s.yaml"
echo ""
echo "🔑 Node token (for joining agents):"
sudo cat /var/lib/rancher/k3s/server/node-token
