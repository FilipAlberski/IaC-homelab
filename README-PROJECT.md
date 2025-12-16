# HomeLab Kubernetes (K3s) Infrastructure

![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)

> Infrastructure as Code dla homelabowego klastra Kubernetes opartego na K3s i Proxmox

## O projekcie

Automatyczne zarządzanie klastrem Kubernetes w homelabie przy użyciu nowoczesnych narzędzi DevOps. Jedno polecenie `make up` tworzy kompletną infrastrukturę od VM-ek po aplikacje.

### Co to robi?

```
make up
    ↓
├─ Terraform tworzy 3 VM na Proxmoxie (1 master + 2 workers)
├─ Ansible konfiguruje system i instaluje K3s
├─ Wdraża Traefik Ingress Controller
├─ Wdraża Kubernetes Dashboard
├─ Wdraża Monitoring Stack (Prometheus + Grafana + AlertManager)
└─ Wdraża przykładową aplikację (Whoami)
```

### Technologie

- **Terraform** - Infrastructure as Code dla Proxmox
- **Ansible** - Konfiguracja VM i instalacja K3s
- **K3s** - Lekka dystrybucja Kubernetes
- **Proxmox VE** - Hypervisor
- **Traefik** - Ingress Controller
- **Make** - Orkiestracja komend

## Architektura

```
┌─────────────────────────────────────────────────────────────────┐
│                         Proxmox VE                              │
│                                                                 │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐ │
│  │   k3s-master-1  │  │   k3s-worker-1  │  │   k3s-worker-2  │ │
│  │   192.168.1.100 │  │   192.168.1.101 │  │   192.168.1.102 │ │
│  │                 │  │                 │  │                 │ │
│  │  • API Server   │  │  • Kubelet      │  │  • Kubelet      │ │
│  │  • etcd         │  │  • Containerd   │  │  • Containerd   │ │
│  │  • Scheduler    │  │  • Pods         │  │  • Pods         │ │
│  │  • Controller   │  │                 │  │                 │ │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘ │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
                    ┌─────────────────┐
                    │   Twój Laptop   │
                    │   • kubectl     │
                    │   • terraform   │
                    │   • ansible     │
                    └─────────────────┘
```

## Wymagania

### System
- Proxmox VE 7.x lub 8.x
- Template VM z cloud-init (Rocky Linux 9 / Debian 12 / Ubuntu 22.04)
- Co najmniej 12 GB RAM i 96 GB dysku dla 3 VM

### Narzędzia (na twoim komputerze)
- Terraform >= 1.5.0
- Ansible >= 2.14
- kubectl >= 1.27
- Make
- jq (opcjonalne, do skryptów)

### Sieć
- Dostęp SSH do Proxmoxa
- Wolne adresy IP w twojej sieci (domyślnie 3)

## Quick Start

### 1. Przygotowanie Proxmox

Najpierw musisz mieć template z cloud-init. Zobacz [docs/architecture.md](docs/architecture.md) dla instrukcji.

### 2. Klonowanie projektu

```bash
git clone https://github.com/TWOJ_USERNAME/homelab-k8s.git
cd homelab-k8s
```

### 3. Konfiguracja

```bash
# Skopiuj przykładowy plik konfiguracji
cp terraform/terraform.tfvars.example terraform/terraform.tfvars

# Edytuj i uzupełnij własnymi wartościami
vim terraform/terraform.tfvars
```

Najważniejsze wartości do uzupełnienia:
- `proxmox_api_url` - URL twojego Proxmoxa
- `proxmox_api_token_id` - Token API
- `proxmox_api_token_secret` - Secret tokena
- `master_ip` - IP dla mastera
- `worker_ip_start` - Pierwszy IP dla workerów
- `ssh_public_key` - Twój klucz SSH publiczny

### 4. Deployment

```bash
# Inicjalizacja (tylko raz)
make init

# Pełny deployment (VM + K3s + Apps)
make up
```

Deployment zajmuje około 5-10 minut. Po zakończeniu zobaczysz:
```
╔════════════════════════════════════════════════════════╗
║           Deployment zakończony sukcesem!             ║
╚════════════════════════════════════════════════════════╝

Dostęp do serwisów:
  • Kubernetes Dashboard: http://192.168.1.100:30090
  • Traefik Dashboard:    http://192.168.1.100:30880
  • Whoami App:           http://192.168.1.100:30081
  • Uptime Kuma:          http://192.168.1.100:30082
```

### 5. Dostęp do klastra

```bash
# Eksportuj kubeconfig
export KUBECONFIG=$(pwd)/kubeconfig

# Sprawdź node'y
kubectl get nodes

# Sprawdź pody
kubectl get pods -A

# Token do dashboardu
make dashboard
```

## Komendy

Pełna lista komend - wpisz `make help`

### Podstawowe

| Komenda | Opis |
|---------|------|
| `make up` | Pełny deployment (VM + K3s + Apps) |
| `make down` | Usuń całą infrastrukturę |
| `make status` | Status klastra |
| `make dashboard` | Token do Kubernetes Dashboard |

## Dostęp do serwisów

| Serwis | Port | Opis |
|--------|------|------|
| Kubernetes Dashboard | 30090 | Dashboard klastra |
| Traefik Dashboard | 30880 | Dashboard Traefik |
| Prometheus | 30090 | Metrics database |
| Grafana | 30300 | Visualization (admin/admin) |
| AlertManager | 30093 | Alert management |
| Whoami | 30081 | Test application |

## Troubleshooting

Zobacz [docs/troubleshooting.md](docs/troubleshooting.md) dla rozwiązań częstych problemów.

## Rozwój projektu

Zaimplementowane:
- [x] **Monitoring Stack** (Prometheus + Grafana + AlertManager)
- [x] Node Exporter (automatic per-node metrics)
- [x] kube-state-metrics (K8s object metrics)
- [x] Pre-configured alerts (CPU, Memory, Disk, Pod health)

Pomysły na dalszą rozbudowę:
- [ ] HA Control Plane (3 mastery)
- [ ] GitOps z ArgoCD
- [ ] Cert-manager + Let's Encrypt
- [ ] Longhorn distributed storage
- [ ] Loki dla log aggregation

## Licencja

MIT License

---

⭐ Projekt stworzony jako portfolio DevOps Engineer
