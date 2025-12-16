.PHONY: help init plan apply destroy provision up down k3s-reset apps-deploy lint clean status ssh dashboard

# Kolory dla lepszej czytelności
GREEN := \033[0;32m
YELLOW := \033[0;33m
BLUE := \033[0;34m
RED := \033[0;31m
NC := \033[0m

# Zmienne
KUBECONFIG := $(shell pwd)/kubeconfig

help:
	@echo "$(GREEN)╔════════════════════════════════════════════════════════╗$(NC)"
	@echo "$(GREEN)║   HomeLab K3s - Infrastructure as Code               ║$(NC)"
	@echo "$(GREEN)╚════════════════════════════════════════════════════════╝$(NC)"
	@echo ""
	@echo "$(BLUE)Infrastruktura (Terraform):$(NC)"
	@echo "  $(YELLOW)make init$(NC)         - Inicjalizuj Terraform"
	@echo "  $(YELLOW)make plan$(NC)         - Pokaż plan zmian"
	@echo "  $(YELLOW)make apply$(NC)        - Stwórz VM-ki na Proxmoxie"
	@echo "  $(YELLOW)make destroy$(NC)      - Usuń wszystkie VM-ki"
	@echo ""
	@echo "$(BLUE)Kubernetes (Ansible):$(NC)"
	@echo "  $(YELLOW)make provision$(NC)    - Zainstaluj K3s na VM-kach"
	@echo "  $(YELLOW)make k3s-reset$(NC)    - Zresetuj klaster (zachowaj VM)"
	@echo "  $(YELLOW)make apps-deploy$(NC)  - Wdróż aplikacje na klaster"
	@echo ""
	@echo "$(BLUE)Kompletny workflow:$(NC)"
	@echo "  $(YELLOW)make up$(NC)           - Pełny deploy (VM + K3s + Apps)"
	@echo "  $(YELLOW)make down$(NC)         - Usuń wszystko"
	@echo ""
	@echo "$(BLUE)Utility:$(NC)"
	@echo "  $(YELLOW)make status$(NC)       - Status klastra"
	@echo "  $(YELLOW)make dashboard$(NC)    - Pokaż token do dashboard"
	@echo "  $(YELLOW)make grafana$(NC)      - Info o Grafana (dashboards)"
	@echo "  $(YELLOW)make ssh-master$(NC)   - SSH do mastera"
	@echo "  $(YELLOW)make ssh-worker N=1$(NC) - SSH do workera N (N=1,2,...)"
	@echo "  $(YELLOW)make lint$(NC)         - Sprawdź składnię kodu"
	@echo "  $(YELLOW)make clean$(NC)        - Wyczyść pliki tymczasowe"
	@echo ""
	@echo "$(BLUE)Przykład użycia:$(NC)"
	@echo "  1. Skopiuj terraform/terraform.tfvars.example -> terraform.tfvars"
	@echo "  2. Uzupełnij wartości w terraform.tfvars"
	@echo "  3. make init"
	@echo "  4. make up"

# ===== TERRAFORM =====

init:
	@echo "$(GREEN)→ Inicjalizuję Terraform...$(NC)"
	cd terraform && terraform init
	@echo "$(GREEN)✓ Terraform zainicjalizowany$(NC)"

plan:
	@echo "$(GREEN)→ Planuję zmiany infrastruktury...$(NC)"
	cd terraform && terraform plan

apply:
	@echo "$(GREEN)→ Tworzę VM-ki na Proxmoxie...$(NC)"
	cd terraform && terraform apply -auto-approve
	@echo "$(GREEN)✓ VM-ki utworzone$(NC)"

destroy:
	@echo "$(RED)→ Usuwam wszystkie VM-ki...$(NC)"
	cd terraform && terraform destroy -auto-approve
	@echo "$(YELLOW)✓ VM-ki usunięte$(NC)"

# ===== ANSIBLE / K3S =====

provision:
	@echo "$(GREEN)→ Instaluję K3s na VM-kach...$(NC)"
	cd ansible && ansible-playbook playbooks/site.yml
	@echo ""
	@echo "$(GREEN)✓ K3s zainstalowany!$(NC)"
	@echo "$(BLUE)Kubeconfig zapisany do: $(KUBECONFIG)$(NC)"
	@echo "$(BLUE)Uruchom: export KUBECONFIG=$(KUBECONFIG)$(NC)"

k3s-reset:
	@echo "$(YELLOW)→ Resetuję klaster K3s...$(NC)"
	cd ansible && ansible-playbook playbooks/k3s-reset.yml
	@rm -f kubeconfig
	@echo "$(YELLOW)✓ Klaster zresetowany (VM pozostały)$(NC)"

apps-deploy:
	@echo "$(GREEN)→ Wdrażam aplikacje na klaster...$(NC)"
	cd ansible && ansible-playbook playbooks/apps-deploy.yml
	@echo "$(GREEN)✓ Aplikacje wdrożone!$(NC)"

# ===== COMBINED WORKFLOWS =====

up: apply
	@echo ""
	@echo "$(GREEN)→ Czekam 60s na uruchomienie VM-ek...$(NC)"
	@sleep 60
	@echo "$(GREEN)→ Sprawdzam połączenie SSH...$(NC)"
	@cd ansible && ansible all -m ping || (echo "$(RED)✗ Brak połączenia SSH. Sprawdź VM i spróbuj ponownie.$(NC)" && exit 1)
	@echo "$(GREEN)✓ Połączenie SSH OK$(NC)"
	@echo ""
	$(MAKE) provision
	@echo ""
	@echo "$(GREEN)→ Czekam na gotowość klastra...$(NC)"
	@sleep 30
	@KUBECONFIG=$(KUBECONFIG) ./scripts/wait-for-k3s.sh || echo "$(YELLOW)! Ostrzeżenie: Klaster może nie być w pełni gotowy$(NC)"
	@echo ""
	@echo "$(GREEN)→ Wdrażam aplikacje...$(NC)"
	$(MAKE) apps-deploy
	@echo ""
	@echo "$(GREEN)╔════════════════════════════════════════════════════════╗$(NC)"
	@echo "$(GREEN)║           Deployment zakończony sukcesem!             ║$(NC)"
	@echo "$(GREEN)╚════════════════════════════════════════════════════════╝$(NC)"
	@echo ""
	@echo "$(BLUE)Dostęp do serwisów:$(NC)"
	@MASTER_IP=$$(cd terraform && terraform output -raw master_ip 2>/dev/null); \
	echo "  • Kubernetes Dashboard: http://$$MASTER_IP:30090"; \
	echo "  • Traefik Dashboard:    http://$$MASTER_IP:30880"; \
	echo "  • Prometheus:           http://$$MASTER_IP:30090"; \
	echo "  • Grafana:              http://$$MASTER_IP:30300 (admin/admin)"; \
	echo "  • AlertManager:         http://$$MASTER_IP:30093"; \
	echo "  • Whoami App:           http://$$MASTER_IP:30081"
	@echo ""
	@echo "$(BLUE)Następne kroki:$(NC)"
	@echo "  export KUBECONFIG=$(KUBECONFIG)"
	@echo "  kubectl get nodes"
	@echo "  kubectl get pods -A"
	@echo "  make dashboard    # token do dashboardu"

down:
	@echo "$(RED)→ Usuwam całą infrastrukturę...$(NC)"
	$(MAKE) destroy
	@rm -f kubeconfig
	@rm -f ansible/inventory/hosts.ini
	@echo "$(YELLOW)✓ Infrastruktura całkowicie usunięta$(NC)"

# ===== UTILITY =====

status:
	@echo "$(BLUE)Nodes:$(NC)"
	@KUBECONFIG=$(KUBECONFIG) kubectl get nodes -o wide 2>/dev/null || echo "$(RED)✗ Klaster niedostępny$(NC)"
	@echo ""
	@echo "$(BLUE)Pods (wszystkie namespace):$(NC)"
	@KUBECONFIG=$(KUBECONFIG) kubectl get pods -A 2>/dev/null || echo "$(RED)✗ Klaster niedostępny$(NC)"

dashboard:
	@echo "$(GREEN)→ Pobieram token do Dashboard...$(NC)"
	@KUBECONFIG=$(KUBECONFIG) ./scripts/get-dashboard-token.sh

grafana:
	@echo "$(GREEN)╔════════════════════════════════════════════════════════╗$(NC)"
	@echo "$(GREEN)║              Grafana Dashboard Info                   ║$(NC)"
	@echo "$(GREEN)╚════════════════════════════════════════════════════════╝$(NC)"
	@echo ""
	@MASTER_IP=$$(cd terraform && terraform output -raw master_ip 2>/dev/null); \
	echo "$(BLUE)Grafana URL:$(NC) http://$$MASTER_IP:30300"; \
	echo "$(BLUE)Username:$(NC)    admin"; \
	echo "$(BLUE)Password:$(NC)    admin (zmień po zalogowaniu!)"; \
	echo ""; \
	echo "$(BLUE)Prometheus:$(NC)  http://$$MASTER_IP:30090"; \
	echo "$(BLUE)AlertManager:$(NC) http://$$MASTER_IP:30093"; \
	echo ""; \
	echo "$(YELLOW)Polecane Dashboardy do zaimportowania:$(NC)"; \
	echo "  1. ID: 1860  - Node Exporter Full"; \
	echo "  2. ID: 7249  - Kubernetes Cluster Monitoring"; \
	echo "  3. ID: 315   - Kubernetes Cluster (Prometheus)"; \
	echo "  4. ID: 12114 - Kubernetes Pods"; \
	echo ""; \
	echo "$(YELLOW)Jak zaimportować:$(NC)"; \
	echo "  1. Otwórz Grafana w przeglądarce"; \
	echo "  2. Zaloguj się (admin/admin)"; \
	echo "  3. Idź do Dashboards → Import"; \
	echo "  4. Wpisz ID dashboardu i kliknij Load"; \
	echo "  5. Wybierz datasource: Prometheus"; \
	echo "  6. Kliknij Import"

ssh-master:
	@echo "$(GREEN)→ Łączę z masterem...$(NC)"
	@MASTER_IP=$$(cd terraform && terraform output -raw master_ip 2>/dev/null); \
	ssh -o StrictHostKeyChecking=no k8s@$$MASTER_IP

ssh-worker:
	@if [ -z "$(N)" ]; then \
		echo "$(RED)✗ Podaj numer workera: make ssh-worker N=1$(NC)"; \
		exit 1; \
	fi
	@echo "$(GREEN)→ Łączę z workerem $(N)...$(NC)"
	@WORKER_IP=$$(cd terraform && terraform output -json worker_ips 2>/dev/null | jq -r '.[$(N)-1]'); \
	if [ "$$WORKER_IP" = "null" ] || [ -z "$$WORKER_IP" ]; then \
		echo "$(RED)✗ Worker $(N) nie istnieje$(NC)"; \
		exit 1; \
	fi; \
	ssh -o StrictHostKeyChecking=no k8s@$$WORKER_IP

lint:
	@echo "$(GREEN)→ Sprawdzam składnię Terraform...$(NC)"
	@cd terraform && terraform fmt -check || (echo "$(YELLOW)! Uruchom: terraform fmt -recursive$(NC)")
	@cd terraform && terraform validate || echo "$(RED)✗ Błędy walidacji Terraform$(NC)"
	@echo "$(GREEN)✓ Terraform OK$(NC)"
	@echo ""
	@echo "$(GREEN)→ Sprawdzam składnię Ansible...$(NC)"
	@cd ansible && ansible-playbook playbooks/site.yml --syntax-check || echo "$(RED)✗ Błędy składni Ansible$(NC)"
	@echo "$(GREEN)✓ Ansible OK$(NC)"
	@echo ""
	@echo "$(GREEN)→ Sprawdzam manifesty Kubernetes...$(NC)"
	@for file in $$(find kubernetes -name "*.yaml" -o -name "*.yml"); do \
		kubectl --dry-run=client apply -f $$file 2>/dev/null || echo "$(YELLOW)  Pominięto: $$file (wymaga klastra)$(NC)"; \
	done
	@echo "$(GREEN)✓ Manifesty Kubernetes OK$(NC)"

clean:
	@echo "$(GREEN)→ Czyszczę pliki tymczasowe...$(NC)"
	@rm -f kubeconfig
	@rm -f ansible/inventory/hosts.ini
	@rm -f terraform/*.tfstate.backup
	@find . -name "*.retry" -delete 2>/dev/null || true
	@echo "$(GREEN)✓ Wyczyszczono$(NC)"

# ===== INFORMACJE =====

info:
	@echo "$(BLUE)Informacje o środowisku:$(NC)"
	@echo "  Terraform: $$(terraform version -json 2>/dev/null | jq -r '.terraform_version' || echo 'nie zainstalowany')"
	@echo "  Ansible:   $$(ansible --version 2>/dev/null | head -n1 || echo 'nie zainstalowany')"
	@echo "  kubectl:   $$(kubectl version --client -o json 2>/dev/null | jq -r '.clientVersion.gitVersion' || echo 'nie zainstalowany')"
	@echo "  jq:        $$(jq --version 2>/dev/null || echo 'nie zainstalowany')"
	@echo ""
	@if [ -f "kubeconfig" ]; then \
		echo "  Kubeconfig: $(GREEN)✓ istnieje$(NC)"; \
	else \
		echo "  Kubeconfig: $(RED)✗ brak$(NC)"; \
	fi
	@if [ -f "terraform/terraform.tfvars" ]; then \
		echo "  tfvars:     $(GREEN)✓ skonfigurowane$(NC)"; \
	else \
		echo "  tfvars:     $(RED)✗ brak (skopiuj terraform.tfvars.example)$(NC)"; \
	fi
