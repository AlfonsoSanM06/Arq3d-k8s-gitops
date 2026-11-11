# terraform/ — Infraestructura ARQ3D sobre Proxmox VE

Gestión declarativa de las VMs del proyecto mediante **Terraform + provider bpg/proxmox**.

## Estructura

```
tf/
├── backend.tf                  # Configuración del backend de estado
├── versions.tf                 # Pin de Terraform y providers
├── variables.tf                # Variables públicas del root module
├── main.tf                     # Orquestación de los módulos de VM
├── outputs.tf                  # Outputs tras el apply (IPs, VMIDs)
├── terraform.tfvars.example    # Plantilla de valores (copiar a terraform.tfvars)
├── .gitignore                  # Excluye state, credenciales y caché
└── modules/
    └── vm/                     # Módulo reutilizable de VM Proxmox
        ├── main.tf             # Recurso proxmox_vm_qemu
        ├── variables.tf        # Inputs del módulo
        ├── outputs.tf          # Outputs del módulo
        └── README.md           # Documentación del módulo
```

## Nodos aprovisionados

| VM | VMID | IP | Rol |
|---|---|---|---|
| `k8s-master-01` | 110 | 10.10.10.11 | K8s Control Plane |
| `k8s-worker-01` | 111 | 10.10.10.12 | K8s Worker (Web + ArgoCD) |
| `k8s-worker-02` | 112 | 10.10.10.13 | K8s Worker (Nextcloud HA) |
| `ldap-server`   | 120 | 10.10.10.20 | OpenLDAP Identity |

## Requisitos

- Terraform >= 1.7.0
- Provider `bpg/proxmox ~> 0.107`
- Token de API de Proxmox con permisos sobre el nodo y el storage

## Primeros pasos

```bash
# 1. Copiar plantilla de variables
cp terraform.tfvars.example terraform.tfvars
# 2. Editar con tus valores reales (API URL, token, IPs, SSH key…)
$EDITOR terraform.tfvars

# 3. Inicializar providers
terraform init

# 4. Verificar plan
terraform plan

# 5. Aplicar
terraform apply

# 6. Exportar IPs a Ansible
terraform output -json > ../ansible/inventory_vars.json
```

## Notas de seguridad

- `terraform.tfvars` está en `.gitignore` — **nunca lo commitees**.
- Usa `TF_VAR_proxmox_api_token_secret` en lugar de escribir el secreto en fichero.
- El state local contiene datos sensibles; considera el backend S3 (MinIO) documentado en `backend.tf`.
