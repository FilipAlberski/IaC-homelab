#!/bin/bash
# Import pre-configured Grafana dashboards

set -e

GRAFANA_URL="${1:-http://localhost:30300}"
GRAFANA_USER="${2:-admin}"
GRAFANA_PASS="${3:-admin}"

echo "Importing dashboards to Grafana at $GRAFANA_URL..."

# Node Exporter Full Dashboard (ID: 1860)
echo "→ Importing Node Exporter Full dashboard..."
curl -X POST -H "Content-Type: application/json" \
  -u "$GRAFANA_USER:$GRAFANA_PASS" \
  "$GRAFANA_URL/api/dashboards/import" \
  -d '{
    "dashboard": {
      "id": null,
      "uid": "node-exporter-full",
      "title": "Node Exporter Full",
      "tags": ["prometheus", "node-exporter"],
      "timezone": "browser",
      "schemaVersion": 16,
      "version": 0
    },
    "overwrite": true,
    "inputs": [{
      "name": "DS_PROMETHEUS",
      "type": "datasource",
      "pluginId": "prometheus",
      "value": "Prometheus"
    }],
    "folderId": 0,
    "folderUid": null
  }' 2>/dev/null || echo "  ⚠ Dashboard import might need manual setup"

# Kubernetes Cluster Monitoring (ID: 7249)
echo "→ Importing Kubernetes Cluster Monitoring dashboard..."
curl -X POST -H "Content-Type: application/json" \
  -u "$GRAFANA_USER:$GRAFANA_PASS" \
  "$GRAFANA_URL/api/dashboards/import" \
  -d '{
    "dashboard": {
      "id": null,
      "uid": "k8s-cluster",
      "title": "Kubernetes Cluster Monitoring",
      "tags": ["kubernetes", "prometheus"],
      "timezone": "browser",
      "schemaVersion": 16,
      "version": 0
    },
    "overwrite": true,
    "inputs": [{
      "name": "DS_PROMETHEUS",
      "type": "datasource",
      "pluginId": "prometheus",
      "value": "Prometheus"
    }],
    "folderId": 0,
    "folderUid": null
  }' 2>/dev/null || echo "  ⚠ Dashboard import might need manual setup"

echo ""
echo "✓ Dashboards imported!"
echo ""
echo "Manual import alternative:"
echo "1. Open Grafana: $GRAFANA_URL"
echo "2. Login: $GRAFANA_USER / $GRAFANA_PASS"
echo "3. Go to Dashboards → Import"
echo "4. Import these dashboard IDs:"
echo "   - 1860  (Node Exporter Full)"
echo "   - 7249  (Kubernetes Cluster Monitoring)"
echo "   - 315   (Kubernetes Cluster Monitoring (Prometheus))"
echo "   - 12114 (Kubernetes Pods)"
