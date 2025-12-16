#!/bin/bash
# Pobiera token do logowania do Kubernetes Dashboard

set -e

export KUBECONFIG="${KUBECONFIG:-./kubeconfig}"

if [ ! -f "$KUBECONFIG" ]; then
    echo "Błąd: Nie znaleziono kubeconfig w $KUBECONFIG"
    echo "Uruchom najpierw: make provision"
    exit 1
fi

echo "Pobieram token do Kubernetes Dashboard..."
echo ""
echo "================================"

TOKEN=$(kubectl get secret admin-user-token -n kubernetes-dashboard -o jsonpath='{.data.token}' 2>/dev/null | base64 -d)

if [ -z "$TOKEN" ]; then
    echo "Błąd: Nie można pobrać tokena."
    echo "Sprawdź czy dashboard jest zainstalowany: kubectl get pods -n kubernetes-dashboard"
    exit 1
fi

echo "$TOKEN"
echo "================================"
echo ""
echo "Dashboard URL: http://$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}'):30090"
echo ""
echo "1. Otwórz powyższy URL w przeglądarce"
echo "2. Wybierz 'Token' i wklej powyższy token"
