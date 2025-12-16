# 🎉 Upgrade: Monitoring Stack Dodany!

## Co się zmieniło?

### ✅ Dodane

**Prometheus + Grafana Stack:**
- ✅ Prometheus (30090) - zbieranie metryk
- ✅ Grafana (30300) - wizualizacja
- ✅ Node Exporter (DaemonSet) - metryki systemowe **na każdym node**
- ✅ kube-state-metrics - metryki obiektów K8s
- ✅ AlertManager (30093) - zarządzanie alertami

**Automatyczne Alerty:**
- 🚨 NodeDown - node nie odpowiada
- 🚨 HighCPUUsage - CPU > 80%
- 🚨 HighMemoryUsage - Memory > 85%
- 🚨 DiskSpaceLow - Disk < 15%
- 🚨 PodCrashLooping - pod restartuje
- 🚨 PodNotReady - pod nie ready
- 🚨 DeploymentReplicasMismatch - replicas mismatch

**Nowe Komendy:**
```bash
make grafana    # Info o Grafana + jak importować dashboardy
make status     # Status klastra (bez zmian)
```

**Dokumentacja:**
- 📚 [docs/monitoring.md](docs/monitoring.md) - Kompletny przewodnik

### ❌ Usunięte

- Uptime Kuma (zastąpione przez profesjonalny monitoring)

---

## Jak to działa?

### 1. Automatyczna Detekcja

**Node Exporter (DaemonSet):**
- Automatycznie deployuje się na **każdym node** (master + workery)
- Zbiera metryki systemowe: CPU, RAM, Disk, Network
- Nie wymaga konfiguracji - działa od razu!

**Prometheus Service Discovery:**
```yaml
# Prometheus automatycznie znajduje:
- Kubernetes API
- Wszystkie node'y (kubelet + cadvisor)
- Wszystkie pody z annotation prometheus.io/scrape: "true"
- Node Exporter na każdym node
- kube-state-metrics
```

### 2. Co jest Monitorowane?

**Poziom Node (każdy node osobno):**
- CPU usage per core
- Memory (used, available, cached, buffers)
- Disk space i I/O
- Network traffic (RX/TX)
- Load average
- System uptime

**Poziom Kubernetes:**
- Pod status (running/pending/failed)
- Container restarts
- Deployments status
- Resource requests vs actual usage
- API server latency

**Poziom Aplikacji:**
- Custom metrics (jeśli aplikacja eksponuje /metrics)

### 3. Zero Configuration

Prometheus automatycznie wykrywa wszystko przez:
- **Service Discovery** - skanuje Kubernetes API
- **Annotations** - `prometheus.io/scrape: "true"`
- **Labels** - automatyczne tagowanie

**Nie musisz ręcznie dodawać target'ów!** ✨

---

## Quick Start

### Po deployu (make up)

```bash
# 1. Sprawdź czy działa
kubectl get pods -n monitoring

# Powinno być:
# prometheus-xxx         Running
# grafana-xxx            Running
# node-exporter-xxx      Running (3 pody - jeden per node)
# kube-state-metrics-xxx Running
# alertmanager-xxx       Running

# 2. Info o Grafana
make grafana

# 3. Otwórz Grafana
# http://MASTER_IP:30300
# Login: admin / admin
```

### Zaimportuj Dashboardy (5 min)

**W Grafana:**
1. Dashboards → Import
2. Wpisz ID: **1860**
3. Load → wybierz datasource **Prometheus** → Import
4. Powtórz dla innych:
   - **7249** - Kubernetes Cluster
   - **315** - Kubernetes (Prometheus)
   - **12114** - Kubernetes Pods

**Gotowe!** Masz kompletne dashboardy z metrykami! 🎉

---

## Przykładowe Query (PromQL)

```promql
# CPU usage per node
100 - (avg by (instance) (irate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)

# Memory usage
(node_memory_MemTotal_bytes - node_memory_MemAvailable_bytes) / node_memory_MemTotal_bytes * 100

# Pod count per namespace
count by (namespace) (kube_pod_info)

# Top 5 pods by CPU
topk(5, rate(container_cpu_usage_seconds_total[5m]))

# Pods not running
count(kube_pod_status_phase{phase!="Running"})
```

Testuj w Prometheus: http://MASTER_IP:30090/graph

---

## Alerty

### Sprawdź Aktywne Alerty

**Prometheus:**
```
http://MASTER_IP:30090/alerts
```

**AlertManager:**
```
http://MASTER_IP:30093
```

### Dodaj Powiadomienia (Slack/Email)

```bash
# Edytuj AlertManager config
kubectl edit configmap alertmanager-config -n monitoring

# Dodaj receiver (przykład - Slack)
receivers:
  - name: 'slack'
    slack_configs:
      - api_url: 'https://hooks.slack.com/services/YOUR/WEBHOOK'
        channel: '#alerts'

# Restart
kubectl rollout restart deployment alertmanager -n monitoring
```

---

## Na Rozmowie Rekrutacyjnej

**Możesz pokazać:**

1. **Live Grafana Dashboard** - metryki w real-time
2. **Prometheus Targets** - auto-discovery w akcji
3. **Alerty** - skonfigurowane thresholdy
4. **PromQL** - napisz query na żywo

**Możesz powiedzieć:**

> "Zaimplementowałem production-grade monitoring stack z Prometheus i Grafana.
>
> **Prometheus** zbiera metryki przez Kubernetes service discovery - automatycznie
> wykrywa wszystkie node'y, pody i serwisy. Mam **Node Exporter jako DaemonSet**,
> więc każdy node (master i workery) eksponuje metryki systemowe.
>
> **kube-state-metrics** daje mi visibility na poziomie obiektów Kubernetes -
> pod status, deployment health, resource usage.
>
> Skonfigurowałem **alerty** dla krytycznych scenariuszy: high CPU/memory,
> low disk space, pod crash looping. AlertManager routing pozwala na różne
> kanały powiadomień w zależności od severity.
>
> W **Grafana** mam pre-configured dashboardy pokazujące metryki systemowe
> i Kubernetes w jednym miejscu. Wszystko persistent i działa out-of-the-box."

**To pokazuje:**
- ✅ Cloud-native monitoring (Prometheus + Grafana)
- ✅ Service discovery i auto-configuration
- ✅ DaemonSet pattern (jeden pod per node)
- ✅ PromQL queries
- ✅ Alerting strategy
- ✅ Observability best practices

**= Profesjonalny monitoring jak w produkcji!** 💯

---

## Troubleshooting

### Node Exporter nie działa na którymś node

```bash
# Sprawdź DaemonSet
kubectl get ds -n monitoring node-exporter

# Powinno pokazać: DESIRED=3, CURRENT=3, READY=3
# Jeśli nie, sprawdź logi
kubectl logs -n monitoring -l app=node-exporter --tail=50

# Debug konkretnego poda
kubectl describe pod -n monitoring node-exporter-xxx
```

### Grafana "No data"

```bash
# 1. Sprawdź datasource
# Grafana UI → Settings → Data Sources → Prometheus → Test

# 2. Sprawdź czy Prometheus ma metryki
# http://MASTER_IP:30090/graph
# Query: up
# Powinno pokazać wszystkie targety

# 3. Ustaw właściwy time range w Grafana (Last 15 minutes)
```

### Więcej w dokumentacji

Zobacz [docs/monitoring.md](docs/monitoring.md) dla szczegółów!

---

## Resources

- [Prometheus Docs](https://prometheus.io/docs/)
- [Grafana Dashboards](https://grafana.com/grafana/dashboards/)
- [PromQL Basics](https://prometheus.io/docs/prometheus/latest/querying/basics/)
- [Node Exporter](https://github.com/prometheus/node_exporter)

---

**Enjoy your monitoring stack!** 📊🚀
