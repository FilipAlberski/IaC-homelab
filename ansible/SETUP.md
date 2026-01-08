# Ansible - jak używać

## Szybki start

Najpierw sprawdź czy maszyny odpowiadają:
```bash
cd ansible
ansible all -m ping
```

## Playbooki

### Common - podstawowy setup
Instaluje podstawowe paczki, ustawia timezone, update systemu:
```bash
ansible-playbook playbooks/common.yml
```

Dla konkretnej grupy:
```bash
ansible-playbook playbooks/common.yml --limit learning
ansible-playbook playbooks/common.yml --limit production
```

### Update - szybki update systemu
Jak chcesz tylko update'nąć paczki:
```bash
ansible-playbook playbooks/update.yml
```

Dry-run (sprawdzić co by się zmieniło):
```bash
ansible-playbook playbooks/update.yml --check
```

## Inventory

Hostsy są w `inventory/hosts.yml`:
- **production**: docker-01 (192.168.40.50)
- **learning**: rocky-lab-01 (192.168.40.100), rocky-lab-02 (192.168.40.101)

Jak dodajesz nową maszynę to wrzuć ją do odpowiedniej grupy.

## SSH

Ansible używa SSH, więc musisz mieć klucz dodany do maszyn (powinno być z cloud-init w template).

Jak nie działa to sprawdź:
```bash
ssh rocky@192.168.40.100
```

++

jak masz haslo na ssh to musisz ssh-add ~/.ssh/id_rsa (czy tam inna nazwe jaka masz swojego klucza)

## Użyteczne komendy

Sprawdź uptime wszystkich maszyn:
```bash
ansible all -a "uptime"
```

Restart konkretnej maszyny:
```bash
ansible docker-01 -a "reboot" -b
```

Info o systemie:
```bash
ansible all -m setup | less
```

## RHCSA Lab Setup

Jeśli przygotowujesz się do RHCSA i potrzebujesz środowiska do praktyki autofs/NFS:

### Quick start - kompletny setup
Jeden playbook który konfiguruje wszystko (NFS server + autofs client):
```bash
ansible-playbook playbooks/rhcsa-lab-setup.yml
```

To skonfiguruje:
- **rocky-lab-02**: NFS server z eksportami
- **rocky-lab-01**: autofs client z mappingami

### Osobne konfiguracje

#### NFS Server (rocky-lab-02)
```bash
ansible-playbook playbooks/nfs-server.yml
```

Tworzy exporty:
- `/nfs/shares/public` (rw)
- `/nfs/shares/data` (rw)
- `/nfs/home` (rw)
- `/nfs/shares/readonly` (ro)

#### autofs Client (rocky-lab-01)
```bash
ansible-playbook playbooks/autofs-client.yml
```

Konfiguruje:
- Direct mappings: `/mnt/public`, `/mnt/readonly`
- Indirect mappings: `/shares/data`, `/shares/home`

### Testowanie

Zaloguj się na rocky-lab-01:
```bash
ssh rocky@192.168.40.100

# Test direct mapping
ls -la /mnt/public
cat /mnt/public/test-file.txt

# Test indirect mapping
ls -la /shares/data
ls -la /shares/home

# Sprawdź montowania
df -h | grep nfs
mount | grep autofs

# Debug
journalctl -u autofs -f
```

Tyle w temacie, jak coś to dokumentacja Ansible jest spoko.
