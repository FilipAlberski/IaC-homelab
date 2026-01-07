# IaC Homelab

Mój homelab zarządzany przez Infrastructure as Code. Zamiast ręcznie klikać w Proxmoxie i logować się na każdą maszynę przez SSH, wszystko jest zautomatyzowane.

## Co tu jest

### Terraform
Automatyczne tworzenie VM w Proxmoxie. Jeden `terraform apply` i mam gotowe maszyny z odpowiednimi parametrami (CPU, RAM, dysk, IP). Używam providera BPG do Proxmoxa.

**Co zarządzam:**
- 2x Rocky Linux do nauki i testów (2 CPU, 2GB RAM, 25GB dysk)
- 1x Docker host produkcyjny (4 CPU, 8GB RAM, 100GB dysk)


Każda maszyna ma swoje stałe IP, startuje automatycznie i jest sklonowana z przygotowanego wcześniej template.

### Ansible
Automatyczne konfigurowanie maszyn. Update systemu, instalacja paczek, setup timezone, NTP - wszystko przez playbooki zamiast ręcznie.

**Co robi:**
- Update systemu
- Instalacja podstawowych narzędzi (vim, git, htop, tmux, etc.)
- Konfiguracja timezone i NTP
- Różne paczki dla maszyn learning vs production

## Struktura

```
├── terraform/           # Definicje infrastruktury
│   ├── environments/
│   │   ├── learning/   # Maszyny do nauki
│   │   └── production/ # Produkcyjny setup
│   └── SETUP.md
├── ansible/            # Automatyzacja konfiguracji
│   ├── inventory/      # Lista maszyn
│   ├── playbooks/      # Co mają robić
│   └── SETUP.md
└── scripts/            # Pomocnicze skrypty, na razie nic ciekawe ale ma byc jeden co zrobi terraform + ansible na raz 
```


## Stack

- **Proxmox VE** - hypervisor
- **Terraform** - tworzenie infrastruktury
- **Ansible** - konfiguracja maszyn
- **Rocky Linux** - stabilny, RHEL-based
- **Git** - wersjonowanie całego setupu

## Jak to działa

1. Terraform tworzy VM z template w Proxmoxie
2. VM startują z cloud-init (SSH keys, podstawowa config)
3. Ansible wchodzi i robi pełny setup
4. Mam gotowe maszyny do roboty

Całość zajmuje minuty, nie godziny ręcznego klikania.

## Sieć

Mam to sensownie podzielone:
- `192.168.40.10` - Proxmox
- `192.168.40.50-99` - Production
- `192.168.40.100-149` - Lab/Testing
- `192.168.40.150-255` - DHCP pool

VM ID też logiczne:
- `1000-1999` - Production
- `7000-7999` - Learning/Lab
- `9000` - Template

## Co dalej

Plan jest rozbudowywać to w miarę potrzeb:
- Docker na docker-01 (już prawie gotowe)
- Monitoring (Prometheus + Grafana)
- Security hardening (firewall, fail2ban)
- Może coś z Kubernetes do nauki

Ale na razie działa i automatyzuje podstawy, co już robi robotę.

## Dokumentacja

Detale w odpowiednich folderach:
- [Terraform Setup](terraform/SETUP.md) - jak postawić infrastrukturę
- [Ansible Setup](ansible/SETUP.md) - jak używać playbooks

---

**Uwaga:** To jest homelab, nie production. Są tu uproszczenia i rzeczy które w prawdziwym środowisku wyglądałyby inaczej. Ale to jest miejsce do nauki i eksperymentów, więc git + mam nadzieje ze zrobilem dobrze .gitignore
