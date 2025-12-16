#!/bin/bash
# Pobiera kubeconfig z mastera K3s

set -e

MASTER_IP="${1:-}"
USER="${2:-k8s}"

if [ -z "$MASTER_IP" ]; then
    echo "Użycie: $0 <MASTER_IP> [USER]"
    echo "Przykład: $0 192.168.1.100 k8s"
    exit 1
fi

echo "Pobieram kubeconfig z ${USER}@${MASTER_IP}..."

# Pobierz kubeconfig
scp -o StrictHostKeyChecking=no ${USER}@${MASTER_IP}:/etc/rancher/k3s/k3s.yaml ./kubeconfig

# Zmień IP na zewnętrzne
sed -i "s/127.0.0.1/${MASTER_IP}/g" ./kubeconfig

echo ""
echo "✓ Kubeconfig zapisany do ./kubeconfig"
echo ""
echo "Użyj:"
echo "  export KUBECONFIG=\$(pwd)/kubeconfig"
echo "  kubectl get nodes"
