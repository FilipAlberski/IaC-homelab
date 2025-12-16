# Getting Started - Szybki Start

Ten przewodnik pomoże Ci uruchomić klaster K3s w 30 minut.

## Co jest potrzebne?

### 1. Proxmox z Template Cloud-init

Potrzebujesz template VM z cloud-init. Najprostszy sposób:

**Rocky Linux 9:**
```bash
# Na Proxmoxie
wget https://download.rockylinux.org/pub/rocky/9/images/x86_64/Rocky-9-GenericCloud.latest.x86_64.qcow2

# Stwórz VM
qm create 9000 --name rocky9-cloud-template --memory 2048 --cores 2 --net0 virtio,bridge=vmbr0

# Dodaj disk
qm importdisk 9000 Rocky-9-GenericCloud.latest.x86_64.qcow2 local-lvm
qm set 9000 --scsihw virtio-scsi-pci --scsi0 local-lvm:vm-9000-disk-0
qm set 9000 --boot c --bootdisk scsi0

# Cloud-init
qm set 9000 --ide2 local-lvm:cloudinit
qm set 9000 --serial0 socket --vga serial0
qm set 9000 --agent enabled=1

# Konwertuj na template
qm template 9000
```

### 2. API Token Proxmoxa

```bash
# W Proxmox Web UI:
# Datacenter → Permissions → API Tokens → Add
# User: terraform@pam
# Token ID: terraform
# Privilege Separation: NIE zaznaczaj (full permissions)

# Zapisz Secret - nie będzie ponownie pokazany!
```

### 3. Klucz SSH

```bash
# Jeśli nie masz, wygeneruj
ssh-keygen -t rsa -b 4096 -C "your_email@example.com"

# Wyświetl klucz publiczny (będzie w terraform.tfvars)
cat ~/.ssh/id_rsa.pub
```

## Instalacja Narzędzi

### Linux (Ubuntu/Debian)
```bash
# Terraform
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install terraform

# Ansible
sudo apt install ansible

# kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# jq
sudo apt install jq
```

### macOS
```bash
# Homebrew
brew install terraform ansible kubectl jq
```

### Windows (WSL2)
```bash
# Użyj instrukcji dla Linux w WSL2
```

## Konfiguracja Projektu

### 1. Sklonuj/Pobierz projekt
```bash
cd ~/projects
# Jeśli masz w git
git clone https://github.com/YOUR_USERNAME/homelab-k8s.git
cd homelab-k8s
```

### 2. Skonfiguruj Terraform

```bash
# Skopiuj przykładowy plik
cp terraform/terraform.tfvars.example terraform/terraform.tfvars

# Edytuj (użyj vim, nano, lub vscode)
vim terraform/terraform.tfvars
```

**Minimalna konfiguracja do uzupełnienia:**

```hcl
# Proxmox API
proxmox_api_url          = "https://192.168.40.40:8006/api2/json"  # ZMIEŃ!
proxmox_api_token_id     = "terraform@pam!terraform"                # ZMIEŃ!
proxmox_api_token_secret = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"  # ZMIEŃ!
proxmox_node             = "pve"                                    # ZMIEŃ jeśli inny

# Template
vm_template = "rocky9-cloud-template"  # Nazwa twojego template

# Network
master_ip        = "192.168.40.100"  # Wolny IP w twojej sieci
worker_ip_start  = "192.168.40.101"  # Workery dostaną .101, .102
network_gateway  = "192.168.40.1"    # Twój gateway

# SSH
ssh_public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAA... user@host"  # Twój klucz
```

### 3. Test konfiguracji

```bash
# Test połączenia z Proxmoxem
cd terraform
terraform init
terraform plan
```

Jeśli widzisz plan (bez błędów) - konfiguracja jest OK!

## Deployment

### Opcja 1: Pełny Automatyczny Deployment

```bash
# Inicjalizacja (tylko raz)
make init

# Pełny deployment (5-10 min)
make up
```

To polecenie:
1. Tworzy 3 VM na Proxmoxie
2. Czeka na boot
3. Instaluje K3s
4. Wdraża aplikacje

### Opcja 2: Krok po Kroku (dla nauki)

```bash
# 1. Inicjalizacja Terraform
make init

# 2. Stwórz VM-ki
make apply

# 3. Poczekaj 60 sekund na boot
sleep 60

# 4. Test connectivity
cd ansible && ansible all -m ping

# 5. Instaluj K3s
make provision

# 6. Poczekaj na klaster
./scripts/wait-for-k3s.sh

# 7. Wdróż aplikacje
make apps-deploy
```

## Weryfikacja

### Sprawdź czy działa

```bash
# 1. Eksportuj kubeconfig
export KUBECONFIG=$(pwd)/kubeconfig

# 2. Sprawdź node'y
kubectl get nodes
# Powinny być 3 node'y w stanie Ready

# 3. Sprawdź pody
kubectl get pods -A
# Wszystkie powinny być Running

# 4. Sprawdź web UI
# Zastąp MASTER_IP swoim IP
# Dashboard:  http://MASTER_IP:30090
# Traefik:    http://MASTER_IP:30880
# Whoami:     http://MASTER_IP:30081
```

### Pobierz token do Dashboard

```bash
make dashboard
# Skopiuj token i użyj w Dashboard (wybierz "Token" auth)
```

## Pierwsze Kroki w Kubernetes

### Podstawowe komendy

```bash
# Sprawdź status klastra
kubectl cluster-info
kubectl get nodes -o wide

# Zobacz wszystkie pody
kubectl get pods -A

# Zobacz serwisy
kubectl get svc -A

# Deploy test poda
kubectl run nginx --image=nginx --port=80

# Sprawdź
kubectl get pods

# Usuń
kubectl delete pod nginx
```

### Deploy własnej aplikacji

Przykład: prosty nginx

```bash
# Stwórz plik nginx-deployment.yaml
cat > nginx-deployment.yaml << EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-nginx
  namespace: apps
spec:
  replicas: 2
  selector:
    matchLabels:
      app: my-nginx
  template:
    metadata:
      labels:
        app: my-nginx
    spec:
      containers:
      - name: nginx
        image: nginx:latest
        ports:
        - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: my-nginx
  namespace: apps
spec:
  type: NodePort
  selector:
    app: my-nginx
  ports:
  - port: 80
    targetPort: 80
    nodePort: 30083
EOF

# Apply
kubectl apply -f nginx-deployment.yaml

# Sprawdź
kubectl get pods -n apps
kubectl get svc -n apps

# Otwórz w przeglądarce
# http://MASTER_IP:30083
```

## Częste Problemy

### Problem: `terraform apply` mówi "template not found"

```bash
# Sprawdź nazwę template na Proxmoxie
ssh root@PROXMOX_IP "qm list | grep template"

# Użyj dokładnej nazwy w terraform.tfvars
```

### Problem: VM nie dostają IP

```bash
# Poczekaj 2-3 minuty na cloud-init
# Sprawdź w Proxmox console czy VM bootują

# Sprawdź w Terraform outputs
cd terraform
terraform output
```

### Problem: `ansible all -m ping` nie działa

```bash
# Sprawdź inventory
cat ansible/inventory/hosts.ini

# Test SSH ręcznie
ssh k8s@MASTER_IP

# Jeśli "permission denied" - problem z kluczem SSH
# Sprawdź czy klucz w terraform.tfvars jest poprawny
```

### Problem: K3s nie instaluje się

```bash
# SSH do VM
make ssh-master

# Sprawdź logi
sudo journalctl -u k3s -f

# Sprawdź internet
curl https://get.k3s.io

# Ręczna instalacja (debug)
curl -sfL https://get.k3s.io | sh -
```

## Co Dalej?

### Naucz się Kubernetes

```bash
# Oficjalna dokumentacja
https://kubernetes.io/docs/tutorials/

# Interactive tutorial
https://www.katacoda.com/courses/kubernetes

# K3s docs
https://docs.k3s.io/
```

### Rozwijaj Projekt

1. **Monitoring**
   - Zainstaluj Prometheus + Grafana
   - Dodaj alerty

2. **GitOps**
   - Zainstaluj ArgoCD
   - Sync z Git repository

3. **Cert Manager**
   - Automatyczne TLS certyfikaty
   - Let's Encrypt integration

4. **CI/CD**
   - GitHub Actions pipeline
   - Automatic deployment

5. **Backup**
   - Velero dla backup klastra
   - Scheduled snapshots

### Pokaż na Rozmowie

Ten projekt pokazuje że znasz:
- ✅ Infrastructure as Code (Terraform)
- ✅ Configuration Management (Ansible)
- ✅ Container Orchestration (Kubernetes/K3s)
- ✅ Networking (Traefik, Services, Ingress)
- ✅ Automation (Makefile, scripts)
- ✅ Documentation (dobra praktyka!)
- ✅ Git workflow
- ✅ Problem solving

## Przydatne Linki

- [Terraform Proxmox Provider](https://registry.terraform.io/providers/Telmate/proxmox/latest/docs)
- [Ansible Docs](https://docs.ansible.com/)
- [K3s Docs](https://docs.k3s.io/)
- [Kubernetes Docs](https://kubernetes.io/docs/)
- [Traefik Docs](https://doc.traefik.io/traefik/)

## Potrzebujesz Pomocy?

- Przeczytaj [docs/troubleshooting.md](docs/troubleshooting.md)
- Sprawdź logi: `make status`, `kubectl logs`, `journalctl`
- Stwórz issue na GitHubie z opisem problemu

---

**Gratulacje!** Jeśli dotarłeś tutaj, masz działający klaster Kubernetes! 🎉
