#!/bin/bash
# Czeka aż klaster K3s będzie gotowy

set -e

export KUBECONFIG="${KUBECONFIG:-./kubeconfig}"
MAX_ATTEMPTS=60
SLEEP_TIME=5

if [ ! -f "$KUBECONFIG" ]; then
    echo "Błąd: Nie znaleziono kubeconfig w $KUBECONFIG"
    exit 1
fi

echo "Czekam na gotowość klastra K3s..."

# Czekaj aż API odpowiada
attempt=1
while ! kubectl get nodes &>/dev/null; do
    if [ $attempt -ge $MAX_ATTEMPTS ]; then
        echo "✗ Timeout - klaster nie odpowiada po $((MAX_ATTEMPTS * SLEEP_TIME)) sekundach"
        exit 1
    fi
    echo "  Próba $attempt/$MAX_ATTEMPTS..."
    sleep $SLEEP_TIME
    ((attempt++))
done

echo ""
echo "✓ API klastra odpowiada!"
echo ""
kubectl get nodes
echo ""

# Czekaj aż wszystkie node'y są Ready
echo "Czekam na gotowość wszystkich node'ów..."
attempt=1
while kubectl get nodes | grep -q "NotReady"; do
    if [ $attempt -ge $MAX_ATTEMPTS ]; then
        echo "✗ Timeout - nie wszystkie node'y gotowe"
        kubectl get nodes
        exit 1
    fi
    echo "  Próba $attempt/$MAX_ATTEMPTS..."
    sleep $SLEEP_TIME
    ((attempt++))
done

echo ""
echo "✓ Wszystkie node'y gotowe!"
echo ""
kubectl get nodes -o wide
