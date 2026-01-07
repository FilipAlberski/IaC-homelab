# Setup - jak to ogarnąć

No to tak, jak chcesz to u siebie postawić:

## Co potrzebujesz

- Proxmox (u mnie stoi na 192.168.40.10)
- Terraform zainstalowany
- Template VM w Proxmoxie (u mnie Rocky Linux jako VM 9000)
- API token w Proxmoxie

## Krok 1: API Token w Proxmox

Wbij w Proxmox UI:
1. Datacenter → Permissions → API Tokens
2. Add - nazwij sobie jak chcesz (ja dałem `terraform-prov@pve!terraform`)
3. Skopiuj UUID które Ci da - będzie Ci potrzebne

## Krok 2: Template VM

Musisz mieć jakiś template (u mnie Rocky Linux):
```bash
# SSH do VM
sudo dnf install -y qemu-guest-agent cloud-init
sudo systemctl enable qemu-guest-agent
sudo systemctl start qemu-guest-agent

# W Proxmox zamień VM na template
# I usuń serial port z Hardware jeśli jest
```

## Krok 3: Terraform config

W każdym folderze terraform (learning/production):
```bash
cp terraform.tfvars.example terraform.tfvars
```

Edytuj `terraform.tfvars` i wpisz swoje dane:
```hcl
proxmox_endpoint  = "https://TWOJ_IP:8006/"
proxmox_api_token = "user@pam!tokenid=twoj-uuid-tutaj"
proxmox_insecure  = true
```

## Krok 4: Odpal to

```bash
cd terraform/environments/learning
terraform init
terraform plan
terraform apply
```

I powinno śmigać. Jak coś nie działa to najpewniej:
- Nie ma template VM 9000
- API token źle skopiowany
- Guest agent nie działa w template

## Moja struktura IP

Tak to u siebie porozdzielałem:
- `192.168.40.1` - Gateway
- `192.168.40.10` - Proxmox
- `192.168.40.11-49` - Infrastruktura (zapas)
- `192.168.40.50-99` - Production VMs
- `192.168.40.100-149` - Lab/Testing VMs
- `192.168.40.150-255` - DHCP pool

## VM ID

- `1000-1999` - Production
- `7000-7999` - Learning/Lab
- `9000` - Template

Jak chcesz dodać nową maszynę to po prostu skopiuj któryś .tf file i zmień nazwę + IP + VM ID.

Tyle w temacie, jakby coś nie działało to sprawdź czy template ma guest agenta i czy API token ma odpowiednie uprawnienia.
