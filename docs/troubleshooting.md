# Troubleshooting Guide

Rozwiązania najczęstszych problemów z klastrem K3s.

## Terraform Issues

### Błąd: "Error creating VM"

**Przyczyny:**
- Template nie istnieje
- Brak zasobów na Proxmoxie
- Błędne dane uwierzytelniające API

**Rozwiązanie:**
```bash
# Sprawdź czy template istnieje
pvesh get /nodes/<node>/qemu --full

# Sprawdź dostępne zasoby
pvesh get /nodes/<node>/status

# Test połączenia API
curl -k https://PROXMOX_IP:8006/api2/json/version \
  -H "Authorization: PVEAPIToken=USER@REALM!TOKENID=SECRET"

# Zweryfikuj terraform.tfvars
cat terraform/terraform.tfvars
```

### Błąd: "Error cloning VM"

**Przyczyna:** Storage jest pełny lub niedostępny

**Rozwiązanie:**
```bash
# Sprawdź storage
pvesh get /storage

# Sprawdź użycie
df -h

# W terraform.tfvars użyj innego storage
vm_storage = "local-lvm"  # lub inny dostępny
```

### VM nie otrzymują IP

**Przyczyna:** Cloud-init nie działa lub błędny network config

**Rozwiązanie:**
```bash
# Poczekaj 2-3 minuty na cloud-init

# Sprawdź w Proxmox console
# Cloud-init status
cloud-init status

# Sprawdź logi
tail -f /var/log/cloud-init.log

# Sprawdź network
ip a

# Ręcznie ustaw IP (tymczasowo)
ip addr add 192.168.1.100/24 dev eth0
ip route add default via 192.168.1.1
```

## Ansible Issues

### Błąd: "Host unreachable"

**Przyczyny:**
- VM nie skończyły bootowania
- Błędny klucz SSH
- Firewall blokuje SSH

**Rozwiązanie:**
```bash
# Sprawdź ping
ping 192.168.1.100

# Test SSH ręcznie
ssh -v k8s@192.168.1.100

# Sprawdź czy klucz jest poprawny
cat ~/.ssh/id_rsa.pub

# Sprawdź inventory
cat ansible/inventory/hosts.ini

# Test Ansible
cd ansible && ansible all -m ping -vvv
```

### Błąd: "Permission denied (publickey)"

**Przyczyna:** Klucz SSH nie został poprawnie dodany do VM

**Rozwiązanie:**
```bash
# Sprawdź czy cloud-init dodał klucz
ssh k8s@MASTER_IP "cat ~/.ssh/authorized_keys"

# Jeśli nie ma klucza, dodaj ręcznie
ssh-copy-id -i ~/.ssh/id_rsa.pub k8s@MASTER_IP

# Lub przez Proxmox console
# Zaloguj się jako root (hasło z cloud-init)
cat >> /home/k8s/.ssh/authorized_keys << EOF
<wklej swój publiczny klucz>
EOF
```

### Role nie wykonują się

**Przyczyna:** Brak połączenia lub błędy w playbooku

**Rozwiązanie:**
```bash
# Verbose mode
cd ansible && ansible-playbook playbooks/site.yml -vv

# Check mode (dry-run)
cd ansible && ansible-playbook playbooks/site.yml --check

# Wykonaj tylko jeden host
cd ansible && ansible-playbook playbooks/site.yml --limit k3s-master-1

# Tylko jedna rola
cd ansible && ansible-playbook playbooks/site.yml --tags base
```

## K3s Issues

### Master nie instaluje się

**Przyczyny:**
- Brak internetu na VM
- Niewystarczające zasoby
- Porty już zajęte

**Rozwiązanie:**
```bash
# SSH do mastera
make ssh-master

# Sprawdź internet
curl -I https://get.k3s.io
ping 8.8.8.8

# Sprawdź zasoby
free -h
df -h

# Sprawdź porty
sudo ss -tulpn | grep -E '(6443|10250|8472)'

# Sprawdź logi instalacji
sudo journalctl -u k3s -f

# Ręczna instalacja (debug)
curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION=v1.29.0+k3s1 sh -s - server --disable=traefik --disable=servicelb --write-kubeconfig-mode=644
```

### Worker nie może dołączyć do klastra

**Przyczyny:**
- Błędny token
- Firewall blokuje port 6443
- Master nie jest gotowy

**Rozwiązanie:**
```bash
# SSH do mastera - pobierz token
make ssh-master
sudo cat /var/lib/rancher/k3s/server/node-token

# SSH do workera
make ssh-worker N=1

# Sprawdź connectivity do mastera
curl -k https://MASTER_IP:6443

# Sprawdź logi
sudo journalctl -u k3s-agent -f

# Ręczny join
curl -sfL https://get.k3s.io | \
  K3S_URL=https://MASTER_IP:6443 \
  K3S_TOKEN=<token> \
  sh -s - agent
```

### Node w stanie "NotReady"

**Przyczyny:**
- CNI (Flannel) nie działa
- Kubelet nie może komunikować się z API

**Rozwiązanie:**
```bash
# Sprawdź status
kubectl get nodes -o wide
kubectl describe node <node-name>

# Sprawdź pody systemowe
kubectl get pods -n kube-system

# Sprawdź Flannel
kubectl logs -n kube-system -l app=flannel

# SSH do node'a
sudo systemctl status k3s  # lub k3s-agent
sudo journalctl -u k3s -f

# Restart
sudo systemctl restart k3s  # lub k3s-agent
```

## Kubernetes Issues

### Pody w stanie "Pending"

**Przyczyny:**
- Niewystarczające zasoby
- Brak odpowiedniego node'a
- Problem z storage

**Rozwiązanie:**
```bash
# Sprawdź szczegóły
kubectl describe pod <pod-name> -n <namespace>

# Sprawdź eventy
kubectl get events -n <namespace> --sort-by='.lastTimestamp'

# Sprawdź zasoby node'ów
kubectl top nodes
kubectl describe nodes

# Sprawdź PVC
kubectl get pvc -A
kubectl describe pvc <pvc-name> -n <namespace>
```

### Pody w stanie "CrashLoopBackOff"

**Przyczyna:** Aplikacja crashuje przy starcie

**Rozwiązanie:**
```bash
# Sprawdź logi
kubectl logs <pod-name> -n <namespace>

# Logi poprzedniej instancji
kubectl logs <pod-name> -n <namespace> --previous

# Sprawdź eventy
kubectl get events -n <namespace>

# Debug interaktywnie
kubectl run debug --rm -it --image=busybox -- sh
```

### Service nie jest dostępny

**Przyczyny:**
- Błędny selector
- Pod nie nasłuchuje na porcie
- Network policy blokuje

**Rozwiązanie:**
```bash
# Sprawdź service
kubectl get svc -n <namespace>
kubectl describe svc <service-name> -n <namespace>

# Sprawdź endpoints
kubectl get endpoints <service-name> -n <namespace>

# Test z poda
kubectl run test --rm -it --image=nicolaka/netshoot -- bash
# W pod:
curl http://<service-name>.<namespace>.svc.cluster.local

# Sprawdź czy pod nasłuchuje
kubectl exec <pod-name> -n <namespace> -- netstat -tulpn
```

### Dashboard nie działa

**Rozwiązanie:**
```bash
# Sprawdź czy pod działa
kubectl get pods -n kubernetes-dashboard

# Sprawdź logi
kubectl logs -n kubernetes-dashboard -l app=kubernetes-dashboard

# Sprawdź service
kubectl get svc -n kubernetes-dashboard

# Test NodePort
curl http://MASTER_IP:30090

# Restart deployment
kubectl rollout restart deployment kubernetes-dashboard -n kubernetes-dashboard
```

### Brak tokena do Dashboard

**Rozwiązanie:**
```bash
# Sprawdź czy secret istnieje
kubectl get secret -n kubernetes-dashboard admin-user-token

# Jeśli nie istnieje, stwórz
kubectl apply -f kubernetes/dashboard/admin-user.yaml

# Pobierz token
./scripts/get-dashboard-token.sh

# Lub ręcznie
kubectl get secret admin-user-token -n kubernetes-dashboard \
  -o jsonpath='{.data.token}' | base64 -d
```

## Network Issues

### Brak connectivity między podami

**Przyczyny:**
- Flannel nie działa
- Firewall na node'ach
- MTU issues

**Rozwiązanie:**
```bash
# Sprawdź Flannel
kubectl get pods -n kube-system -l app=flannel
kubectl logs -n kube-system -l app=flannel

# Sprawdź routes na node
ip route
ip a

# Test connectivity
kubectl run test-1 --image=busybox -- sleep 3600
kubectl run test-2 --image=busybox -- sleep 3600

POD1_IP=$(kubectl get pod test-1 -o jsonpath='{.status.podIP}')
kubectl exec test-2 -- ping -c 3 $POD1_IP

# Sprawdź iptables
sudo iptables -L -n -v | grep -i kube

# Restart Flannel
kubectl delete pod -n kube-system -l app=flannel
```

### CoreDNS nie działa

**Rozwiązanie:**
```bash
# Sprawdź CoreDNS pody
kubectl get pods -n kube-system -l k8s-app=kube-dns

# Logi
kubectl logs -n kube-system -l k8s-app=kube-dns

# Test DNS
kubectl run test --rm -it --image=busybox -- nslookup kubernetes.default

# Restart CoreDNS
kubectl rollout restart deployment coredns -n kube-system
```

## Performance Issues

### Klaster działa wolno

**Rozwiązanie:**
```bash
# Sprawdź zasoby
kubectl top nodes
kubectl top pods -A

# Sprawdź eventy
kubectl get events -A --sort-by='.lastTimestamp' | head -20

# Sprawdź dysk I/O (na node)
iostat -x 1

# Sprawdź network
iftop

# Sprawdź czy wszystkie pody są ready
kubectl get pods -A | grep -v Running
```

## Disaster Recovery

### Klaster całkowicie padł

**Rozwiązanie:**
```bash
# Reset i reinstalacja
make k3s-reset
make provision

# Lub całkowity rebuild
make down
make up
```

### Utrata mastera

**Rozwiązanie:**
```bash
# Jeśli masz backup etcd (na masterze)
ls /var/lib/rancher/k3s/server/db/snapshots/

# Restore
sudo k3s server \
  --cluster-reset \
  --cluster-reset-restore-path=/path/to/snapshot

# Jeśli nie - rebuild
cd terraform
terraform taint proxmox_vm_qemu.k3s_master[0]
terraform apply

make provision
```

## Najczęstsze Błędy

### "Unable to connect to the server"

```bash
# Sprawdź kubeconfig
echo $KUBECONFIG
cat $KUBECONFIG

# Sprawdź czy master działa
ping MASTER_IP
curl -k https://MASTER_IP:6443

# Pobierz fresh kubeconfig
./scripts/get-kubeconfig.sh MASTER_IP
export KUBECONFIG=$(pwd)/kubeconfig
```

### "The connection to the server was refused"

```bash
# K3s nie działa na masterze
make ssh-master
sudo systemctl status k3s
sudo systemctl start k3s
```

### "Error from server (ServiceUnavailable)"

```bash
# API Server ma problemy
make ssh-master
sudo journalctl -u k3s -f

# Restart
sudo systemctl restart k3s
```

## Helpful Commands

```bash
# Pełny debug klastra
kubectl cluster-info dump > cluster-dump.txt

# Wszystkie zasoby w namespace
kubectl api-resources --verbs=list --namespaced -o name | \
  xargs -n 1 kubectl get --show-kind --ignore-not-found -n <namespace>

# Find problematic pods
kubectl get pods -A | grep -vE '(Running|Completed)'

# Resource usage
kubectl get pods -A -o custom-columns=NAME:.metadata.name,NAMESPACE:.metadata.namespace,CPU:.spec.containers[*].resources.requests.cpu,MEMORY:.spec.containers[*].resources.requests.memory

# Events summary
kubectl get events -A --sort-by='.lastTimestamp' | tail -20
```

## Preventive Maintenance

```bash
# Regular checks (cotygodniowo)
make status
kubectl get nodes
kubectl get pods -A
kubectl top nodes

# Update K3s (ostrożnie!)
# Na masterze:
curl -sfL https://get.k3s.io | sh -s - server

# Na workerach:
curl -sfL https://get.k3s.io | sh -s - agent

# Cleanup unused images
kubectl delete pod --field-selector=status.phase==Succeeded -A
kubectl delete pod --field-selector=status.phase==Failed -A
```

## Getting Help

Jeśli żadne z powyższych nie pomogło:

1. Sprawdź logi wszystkich komponentów
2. Zbierz informacje o środowisku
3. Stwórz issue na GitHub z:
   - Opisem problemu
   - Komendami które wykonałeś
   - Logami
   - Wersją K3s, Terraform, Ansible
