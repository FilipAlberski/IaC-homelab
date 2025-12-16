# Architektura Klastra K3s

## Przegląd

Projekt tworzy kompletny klaster Kubernetes oparty na K3s, działający na wirtualnych maszynach w Proxmoxie.

## Komponenty

### 1. Infrastruktura (Proxmox)

```
Proxmox VE
├── k3s-master-1    (2 CPU, 4GB RAM, 32GB disk)
├── k3s-worker-1    (2 CPU, 4GB RAM, 32GB disk)
└── k3s-worker-2    (2 CPU, 4GB RAM, 32GB disk)
```

**Cechy:**
- VM klonowane z template'a cloud-init
- Statyczne IP dla przewidywalności
- Virtio dla najlepszej wydajności
- QEMU guest agent dla integracji z Proxmoxem

### 2. K3s Control Plane (Master)

```
k3s-master-1
├── kube-apiserver         - API endpoint
├── etcd (embedded)        - Baza danych klastra
├── kube-scheduler         - Planowanie podów
├── kube-controller-manager - Kontrolery
└── kubelet                - Zarządzanie kontenerami
```

**Konfiguracja:**
- Disabled: traefik, servicelb (instalujemy własne)
- Write kubeconfig mode: 644 (łatwy dostęp)
- TLS SAN: IP mastera (dostęp zewnętrzny)

### 3. K3s Workers

```
k3s-worker-{1,2}
├── kubelet        - Zarządzanie kontenerami
├── kube-proxy     - Networking
└── containerd     - Container runtime
```

**Join do klastra:**
- URL: https://MASTER_IP:6443
- Token: z /var/lib/rancher/k3s/server/node-token

### 4. Networking

```
Pod Network:     10.42.0.0/16  (Flannel CNI)
Service Network: 10.43.0.0/16  (ClusterIP range)
Node Network:    192.168.1.0/24 (twoja sieć)
```

**Flannel (CNI):**
- Backend: VXLAN
- Automatyczna konfiguracja
- Brak potrzeby dodatkowej konfiguracji

**Traefik (Ingress):**
- NodePort 30080 (HTTP)
- NodePort 30443 (HTTPS)
- NodePort 30880 (Dashboard)

### 5. Storage

```
local-path-provisioner (domyślny w K3s)
├── Dynamiczne provisioning PVC
├── Lokalne dyski na każdym node'dzie
└── ReclaimPolicy: Delete
```

**Path:** /var/lib/rancher/k3s/storage/

## Flow Instalacji

### 1. Terraform Phase

```
terraform apply
    ↓
├── Tworzy 1 master VM
├── Tworzy 2 worker VMs
├── Konfiguruje cloud-init (IP, SSH key, user)
└── Generuje ansible/inventory/hosts.ini
```

### 2. Ansible Phase - Base Setup

```
Playbook: site.yml (base role)
    ↓
├── Ustawia timezone (Europe/Warsaw)
├── Instaluje pakiety (vim, htop, curl, etc.)
├── Konfiguruje hostname
└── Wyłącza firewall (dla uproszczenia w homelabie)
```

### 3. Ansible Phase - K3s Prerequisites

```
Playbook: site.yml (k3s-prereqs role)
    ↓
├── Wyłącza swap
├── Ładuje moduły kernela (br_netfilter, overlay)
├── Ustawia sysctl (ip_forward, bridge-nf-call-iptables)
└── Ustawia SELinux na permissive (RHEL)
```

### 4. Ansible Phase - K3s Master

```
Playbook: site.yml (k3s-master role)
    ↓
├── Pobiera install script (get.k3s.io)
├── Instaluje K3s jako server
├── Czeka na gotowość API
├── Pobiera node-token
├── Kopiuje kubeconfig lokalnie
└── Aktualizuje kubeconfig (127.0.0.1 → MASTER_IP)
```

**Instalacja:**
```bash
curl -sfL https://get.k3s.io | sh -s - server \
  --disable=traefik \
  --disable=servicelb \
  --write-kubeconfig-mode=644
```

### 5. Ansible Phase - K3s Workers

```
Playbook: site.yml (k3s-worker role)
    ↓
├── Pobiera token z mastera
├── Pobiera install script
├── Instaluje K3s jako agent
└── Czeka na rejestrację w klastrze
```

**Instalacja:**
```bash
curl -sfL https://get.k3s.io | \
  K3S_URL=https://MASTER_IP:6443 \
  K3S_TOKEN=xxx \
  sh -s - agent
```

### 6. Ansible Phase - Deploy Apps

```
Playbook: apps-deploy.yml
    ↓
├── Kopiuje manifesty na mastera
├── Apliko namespaces (monitoring, apps)
├── Apliku Traefik (Ingress Controller)
├── Apliku Kubernetes Dashboard
├── Apliku Whoami (test app)
└── Apliku Uptime Kuma (monitoring)
```

## Komunikacja w klastrze

### Control Plane ↔ Workers

```
Master:6443 (API Server)
    ↑
    │ kubectl commands
    │
    ├── Worker-1 (kubelet)
    └── Worker-2 (kubelet)
```

**Porty:**
- 6443: API Server (HTTPS)
- 10250: kubelet API
- 8472: Flannel VXLAN

### External Access

```
User Browser
    ↓
    ├─ http://MASTER_IP:30090  → K8s Dashboard
    ├─ http://MASTER_IP:30880  → Traefik Dashboard
    ├─ http://MASTER_IP:30081  → Whoami App
    └─ http://MASTER_IP:30082  → Uptime Kuma
```

**NodePort Range:** 30000-32767

## Bezpieczeństwo

### Obecne (Homelab)
- SSH key authentication
- No firewall (dla prostoty)
- Insecure dashboards (no TLS)
- Token-based auth dla dashboard

### Produkcja (TODO)
- [ ] Firewall z ograniczonymi portami
- [ ] TLS dla wszystkich serwisów
- [ ] RBAC policies
- [ ] Network policies
- [ ] Pod Security Standards
- [ ] Regular updates

## Skalowanie

### Dodanie Workera

```bash
# 1. Zwiększ worker_count w terraform.tfvars
worker_count = 3

# 2. Apply zmian
make apply
make provision
```

### Dodanie Mastera (HA - zaawansowane)

Wymaga:
- Etcd external lub embedded multi-master
- Load balancer przed API
- Shared storage (opcjonalnie)

## Monitoring

### Wbudowane
```bash
# Sprawdź nodes
kubectl get nodes -o wide

# Sprawdź pody
kubectl get pods -A

# Sprawdź eventy
kubectl get events -A

# Logi
kubectl logs <pod> -n <namespace>
```

### Dashboard K8s
- Graficzny przegląd klastra
- Logi, eventy, zasoby
- Token auth

## Backup

### Ręczne Backup
```bash
# Backup etcd (na masterze)
sudo k3s etcd-snapshot save

# Pliki: /var/lib/rancher/k3s/server/db/snapshots/
```

### Restore (disaster recovery)
```bash
sudo k3s server \
  --cluster-reset \
  --cluster-reset-restore-path=/var/lib/rancher/k3s/server/db/snapshots/on-demand-snapshot
```

## Troubleshooting

### Node NotReady
```bash
# Sprawdź na node'dzie
sudo systemctl status k3s  # lub k3s-agent
sudo journalctl -u k3s -f

# Sprawdź network
kubectl get nodes -o wide
kubectl describe node <node-name>
```

### Pod CrashLoop
```bash
kubectl logs <pod> -n <namespace>
kubectl describe pod <pod> -n <namespace>
kubectl get events -n <namespace> --sort-by='.lastTimestamp'
```

### Connectivity Issues
```bash
# Sprawdź czy Flannel działa
kubectl get pods -n kube-system -l app=flannel

# Sprawdź czy coredns działa
kubectl get pods -n kube-system -l k8s-app=kube-dns

# Test connectivity między podami
kubectl run test --rm -it --image=busybox -- ping <pod-ip>
```

## Performance Tuning

### Dla Homelab (obecne)
- CPU: host type (maksymalna wydajność)
- Memory: bez limitu swap
- Disk: virtio-scsi z iothread

### Dla Produkcji
- CPU reservations
- Memory limits per namespace
- Resource quotas
- QoS classes (Guaranteed, Burstable, BestEffort)

## Przydatne Komendy

```bash
# Info o klastrze
kubectl cluster-info
kubectl version

# Zasoby
kubectl top nodes
kubectl top pods -A

# Namespace
kubectl get all -n <namespace>

# Config
kubectl config view
kubectl config use-context <context>

# Debug
kubectl run debug --rm -it --image=busybox -- sh
```

## Następne Kroki

1. **Monitoring Stack** - Prometheus + Grafana
2. **GitOps** - ArgoCD dla continuous deployment
3. **Service Mesh** - Linkerd dla advanced networking
4. **Cert Manager** - Automatyczne TLS certificates
5. **Backup Solution** - Velero dla cluster backup
