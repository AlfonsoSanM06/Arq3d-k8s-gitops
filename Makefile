.PHONY: help proxmox-network proxmox-install proxmox-run proxmox-check proxmox-post-install proxmox-status proxmox-destroy validate

help: ## Muestra esta ayuda
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

proxmox-network: ## Crear bridge/TAP y NAT para Proxmox en QEMU
	sudo ./scripts/proxmox-vm.sh network

proxmox-install: ## Arrancar Proxmox desde ISO para instalarlo
	sudo ./scripts/proxmox-vm.sh install

proxmox-run: ## Arrancar Proxmox ya instalado
	sudo ./scripts/proxmox-vm.sh run

proxmox-check: ## Verificar dependencias, ISO y disco sin arrancar QEMU
	sudo ./scripts/proxmox-vm.sh check

proxmox-post-install: ## Configurar Proxmox tras la instalación (red, token, plantilla)
	./scripts/proxmox-post-install.sh

proxmox-status: ## Mostrar estado de red, disco y proceso QEMU
	./scripts/proxmox-vm.sh status

proxmox-destroy: ## Eliminar bridge, TAP, disco y proceso QEMU
	sudo ./scripts/proxmox-vm.sh destroy

validate: ## Validar Terraform, Ansible y Helm del proyecto
	cd terraform-proxmox && terraform init -backend=false && terraform validate
	cd k8s-cluster/k8s_argocd/argocd_terraform && terraform validate
	cd ansible && ansible-playbook --syntax-check site.yml
	cd /home/alfonso/Documentos/1-Informatica/proyectos/TFG-asir && helm dependency build k8s-cluster/wordpress/wordpress-mysql
	helm lint k8s-cluster/wordpress/wordpress-mysql
