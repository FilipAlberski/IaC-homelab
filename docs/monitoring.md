# Monitoring Stack - Prometheus + Grafana

Kompletny monitoring klastra K3s z automatyczną detekcją i alertami.

## Komponenty

### 1. Prometheus
- **Port:** 30090
- **Rola:** Zbieranie i przechowywanie metryk
- **Retencja:** 15 dni
- **Storage:** 10Gi PVC

**Co monitoruje:**
- ✅ Kubernetes API Server
- ✅ Node metrics (kubelet, cadvisor)
- ✅ Container metrics
- ✅ Pod metrics
- ✅ Service endpoints
- ✅ Node Exporter metrics (system)
- ✅ kube-state-metrics (K8s objects)

### 2. Grafana
- **Port:** 30300
- **Login:** admin / admin (ZMIEŃ!)
- **Datasource:** Prometheus (auto-configured)
- **Storage:** 2Gi PVC

**Features:**
- Gotowy datasource do Prometheus
- Import dashboardów przez ID
- Persistent storage dla dashboardów

### 3. Node Exporter
- **Type:** DaemonSet (jeden pod na każdym node)
- **Port:** 9100
- **Auto-discovery:** Tak

**Metryki:**
- CPU usage per core
- Memory (used, available, cached)
- Disk I/O i przestrzeń
- Network traffic
- Load average
- File descriptors
- Inne system metrics

### 4. kube-state-metrics
- **Port:** 8080
- **Rola:** Eksponuje stan obiektów Kubernetes

**Metryki:**
- Deployments status
- Pods status (running, pending, failed)
- Node conditions
- Resource quotas
- Persistent volumes
- ConfigMaps, Secrets (count)

### 5. AlertManager
- **Port:** 30093
- **Rola:** Zarządzanie alertami
- **Config:** Routing, grouping, inhibition

## Dostęp

```bash
# Po deployu
export KUBECONFIG=$(pwd)/kubeconfig

# URLs (zastąp MASTER_IP)
Prometheus:   http://MASTER_IP:30090
Grafana:      http://MASTER_IP:30300
AlertManager: http://MASTER_IP:30093

# Lub użyj Makefile
make grafana  # Pokaże wszystkie info
```

## Grafana - Quick Start

### 1. Pierwsze logowanie

```bash
# Otwórz w przeglądarce
http://MASTER_IP:30300

# Login
Username: admin
Password: admin

# ⚠️ Zmień hasło przy pierwszym logowaniu!
```

### 2. Zaimportuj Dashboardy

Grafana umożliwia import gotowych dashboardów przez ID:

**Polecane dashboardy:**

| ID | Nazwa | Opis |
|----|-------|------|
| **1860** | Node Exporter Full | Kompletne metryki systemowe |
| **7249** | Kubernetes Cluster Monitoring | Przegląd klastra K8s |
| **315** | Kubernetes Cluster (Prometheus) | Alternatywny dashboard klastra |
| **12114** | Kubernetes Pods | Szczegółowe metryki podów |
| **6417** | Kubernetes Cluster (Prometheus) | Bardzo szczegółowy |

**Jak zaimportować:**

1. W Grafana: **Dashboards → Import**
2. Wpisz ID (np. `1860`)
3. Kliknij **Load**
4. Wybierz datasource: **Prometheus**
5. Kliknij **Import**

### 3. Gotowe Dashboardy

Po zaimportowaniu znajdziesz:

**Node Exporter Full (1860):**
- CPU usage per core + średnia
- Memory usage (used, cached, buffers)
- Disk I/O operations
- Network traffic (RX/TX)
- Load average (1m, 5m, 15m)
- Disk space per filesystem
- System uptime

**Kubernetes Cluster Monitoring (7249):**
- Nodes status i resources
- Pods running/pending/failed
- CPU/Memory requests vs limits
- Namespace resource usage
- Top pods by CPU/Memory
- Network I/O per pod

## Prometheus Queries (PromQL)

### Przykłady podstawowych query:

```promql
# CPU usage per node
100 - (avg by (instance) (irate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)

# Memory usage per node
(node_memory_MemTotal_bytes - node_memory_MemAvailable_bytes) / node_memory_MemTotal_bytes * 100

# Disk space usage
(node_filesystem_size_bytes - node_filesystem_avail_bytes) / node_filesystem_size_bytes * 100

# Pod count per namespace
count by (namespace) (kube_pod_info)

# Pods not running
count(kube_pod_status_phase{phase!="Running"})

# Container restarts
rate(kube_pod_container_status_restarts_total[5m])

# Top 5 pods by CPU
topk(5, rate(container_cpu_usage_seconds_total[5m]))

# Top 5 pods by Memory
topk(5, container_memory_usage_bytes)
```

### Testowanie Query

1. Otwórz Prometheus: http://MASTER_IP:30090
2. Kliknij **Graph**
3. Wpisz query w polu
4. Kliknij **Execute**
5. Zobacz wyniki (Graph lub Table)

## Alerty

### Skonfigurowane Alerty

**Node Alerts:**
- ⚠️ `NodeDown` - Node nie odpowiada > 2 min (critical)
- ⚠️ `HighCPUUsage` - CPU > 80% przez 5 min (warning)
- ⚠️ `HighMemoryUsage` - Memory > 85% przez 5 min (warning)
- ⚠️ `DiskSpaceLow` - Disk < 15% przez 5 min (warning)

**Kubernetes Alerts:**
- ⚠️ `PodCrashLooping` - Pod restartuje się często (warning)
- ⚠️ `PodNotReady` - Pod nie jest Ready > 10 min (warning)
- ⚠️ `DeploymentReplicasMismatch` - Replicas != desired > 10 min (warning)

### Sprawdzenie Alertów

**W Prometheus:**
```
http://MASTER_IP:30090/alerts
```

**W AlertManager:**
```
http://MASTER_IP:30093
```

### Konfiguracja Powiadomień

Domyślnie alerty tylko logują. Aby dodać powiadomienia (email, Slack, webhook):

```bash
# Edytuj AlertManager config
kubectl edit configmap alertmanager-config -n monitoring

# Przykład - Slack webhook
receivers:
  - name: 'slack'
    slack_configs:
      - api_url: 'https://hooks.slack.com/services/YOUR/WEBHOOK/URL'
        channel: '#alerts'
        text: '{{ range .Alerts }}{{ .Annotations.description }}{{ end }}'

# Apply zmian
kubectl rollout restart deployment alertmanager -n monitoring
```

## Troubleshooting

### Prometheus nie zbiera metryk

```bash
# Sprawdź targets
# Otwórz: http://MASTER_IP:30090/targets
# Wszystkie powinny być "UP"

# Jeśli są "DOWN", sprawdź logi
kubectl logs -n monitoring -l app=prometheus

# Sprawdź konfigurację
kubectl get configmap prometheus-config -n monitoring -o yaml
```

### Node Exporter nie działa

```bash
# Sprawdź DaemonSet
kubectl get ds -n monitoring node-exporter

# Powinno być 3/3 (jeden pod na node)
# Jeśli nie, sprawdź logi
kubectl logs -n monitoring -l app=node-exporter

# Test ręczny (z mastera)
curl http://NODE_IP:9100/metrics
```

### Grafana nie łączy się z Prometheus

```bash
# Sprawdź datasource w Grafana
# Settings → Data Sources → Prometheus
# Test Connection

# Sprawdź czy Prometheus odpowiada
kubectl exec -n monitoring -it deployment/grafana -- \
  wget -O- http://prometheus:9090/api/v1/query?query=up

# Restart Grafany
kubectl rollout restart deployment grafana -n monitoring
```

### Brak danych na dashboardach

```bash
# Sprawdź czy są metryki w Prometheus
# http://MASTER_IP:30090/graph
# Query: up
# Powinno pokazać wszystkie targety

# Sprawdź time range w Grafana (prawy górny róg)
# Ustaw "Last 5 minutes" lub "Last 15 minutes"

# Odśwież dashboard (Ctrl+R lub przycisk refresh)
```

### Dashboard "No data"

**Możliwe przyczyny:**
1. Zły datasource - wybierz "Prometheus"
2. Brak metryk - sprawdź czy Node Exporter działa
3. Zły time range - ustaw na "Last 15 minutes"
4. Query error - sprawdź logi w Query Inspector

**Fix:**
```bash
# Sprawdź czy są metryki
kubectl exec -n monitoring deployment/prometheus -- \
  wget -qO- localhost:9090/api/v1/query?query=up

# Restart wszystkich komponentów
kubectl rollout restart deployment -n monitoring
```

## Best Practices

### 1. Zmień hasło Grafana

```bash
# W Grafana UI
Settings → Profile → Change Password

# Lub przez kubectl
kubectl exec -n monitoring deployment/grafana -- \
  grafana-cli admin reset-admin-password NOWE_HASLO
```

### 2. Backup dashboardów

```bash
# Export dashboardu (z Grafana UI)
Dashboard Settings → JSON Model → Copy

# Lub backup całego storage
kubectl exec -n monitoring deployment/grafana -- \
  tar -czf /tmp/grafana-backup.tar.gz /var/lib/grafana
kubectl cp monitoring/grafana-xxx:/tmp/grafana-backup.tar.gz ./grafana-backup.tar.gz
```

### 3. Zwiększ retencję Prometheus

```bash
# Edytuj deployment
kubectl edit deployment prometheus -n monitoring

# Zmień arg:
- '--storage.tsdb.retention.time=15d'
# Na np.:
- '--storage.tsdb.retention.time=30d'

# Zwiększ PVC jeśli potrzeba
kubectl edit pvc prometheus-storage -n monitoring
```

### 4. Dodaj custom metryki

**Dla aplikacji z endpoint /metrics:**

```yaml
# Dodaj annotation do poda
apiVersion: v1
kind: Pod
metadata:
  annotations:
    prometheus.io/scrape: "true"
    prometheus.io/port: "8080"
    prometheus.io/path: "/metrics"
```

Prometheus automatycznie wykryje i zacznie scrape'ować!

## Metryki do śledzenia

### Dla stabilności:
- ✅ Node CPU/Memory usage
- ✅ Disk space remaining
- ✅ Pod restart count
- ✅ Pods not ready
- ✅ API server latency

### Dla performance:
- ✅ Container CPU throttling
- ✅ Memory OOM kills
- ✅ Network errors/drops
- ✅ Disk I/O latency

### Dla capacity planning:
- ✅ Resource requests vs actual usage
- ✅ Storage growth trend
- ✅ Pod count trend
- ✅ Network bandwidth usage

## Przydatne Linki

- [PromQL Documentation](https://prometheus.io/docs/prometheus/latest/querying/basics/)
- [Grafana Dashboards](https://grafana.com/grafana/dashboards/)
- [Node Exporter](https://github.com/prometheus/node_exporter)
- [kube-state-metrics](https://github.com/kubernetes/kube-state-metrics)

## Na Rozmowie Rekrutacyjnej

**Możesz powiedzieć:**

> "Zaimplementowałem kompletny monitoring stack z Prometheus i Grafana.
> Prometheus automatycznie wykrywa wszystkie komponenty Kubernetes przez
> service discovery i zbiera metryki z Node Exporter (system metrics) oraz
> kube-state-metrics (K8s objects). Skonfigurowałem alerty dla krytycznych
> scenariuszy jak high CPU, low disk space czy pod crash looping.
>
> W Grafana mam zaimportowane standardowe dashboardy pokazujące metryki
> na poziomie node'ów, podów i całego klastra. Wszystko jest persistent
> i działa out-of-the-box po deployment."

**To pokazuje że:**
- ✅ Rozumiesz monitoring w Kubernetes
- ✅ Znasz Prometheus + Grafana
- ✅ Potrafisz konfigurować alerty
- ✅ Myślisz o observability

**Bonus points:** Pokaż live dashboard podczas rozmowy! 🎯
