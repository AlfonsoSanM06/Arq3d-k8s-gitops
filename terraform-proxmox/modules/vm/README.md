# Module: vm

Crea una VM en **Proxmox VE** clonando una plantilla Cloud-Init.
Reutilizable para cualquier nodo del proyecto (K8s master, workers, LDAP…).

## Ficheros

| Fichero | Propósito |
|---|---|
| `main.tf` | Recurso `proxmox_vm_qemu` |
| `variables.tf` | Parámetros de entrada del módulo |
| `outputs.tf` | Valores exportados (`vm_id`, `vm_name`, `ip`) |

## Uso

```hcl
module "k8s_master_01" {
  source = "./modules/vm"

  vm_id          = 110
  vm_name        = "k8s-master-01"
  proxmox_node   = "pve"
  template_name  = "ubuntu-2204-cloud-init"
  storage_pool   = "local-lvm"

  cpu_cores    = 2
  ram_mb       = 4096
  disk_size_gb = 40

  network_bridge = "vmbr0"
  network_vlan   = 10
  ip_address     = "10.10.10.11"
  cidr_prefix    = 24
  gateway        = "10.10.10.1"
  dns_servers    = "8.8.8.8 1.1.1.1"

  ci_user    = "arq3d"
  ci_ssh_key = var.ci_ssh_public_key

  tags = ["k8s", "master"]
}
```

## Inputs

| Variable | Tipo | Default | Descripción |
|---|---|---|---|
| `vm_id` | `number` | — | VMID único en Proxmox |
| `vm_name` | `string` | — | Nombre de la VM |
| `vm_description` | `string` | `"Managed by Terraform — ARQ3D"` | Descripción |
| `proxmox_node` | `string` | — | Nodo Proxmox destino |
| `template_name` | `string` | — | Plantilla Cloud-Init |
| `storage_pool` | `string` | — | Pool de almacenamiento |
| `cpu_cores` | `number` | — | vCPUs |
| `cpu_sockets` | `number` | `1` | Sockets CPU |
| `cpu_type` | `string` | `"host"` | Tipo de CPU |
| `ram_mb` | `number` | — | Memoria en MiB |
| `balloon_mb` | `number` | `0` | Ballooning (0=off) |
| `disk_size_gb` | `number` | — | Disco OS en GiB |
| `network_bridge` | `string` | — | Bridge de red |
| `network_vlan` | `number` | — | VLAN tag |
| `ip_address` | `string` | — | IP estática |
| `cidr_prefix` | `number` | — | Longitud CIDR |
| `gateway` | `string` | — | Puerta de enlace |
| `dns_servers` | `string` | — | DNS (separados por espacio) |
| `ci_user` | `string` | — | Usuario Cloud-Init |
| `ci_ssh_key` | `string` | — | Clave pública SSH (sensitive) |
| `tags` | `list(string)` | `[]` | Etiquetas Proxmox |

## Outputs

| Output | Descripción |
|---|---|
| `vm_id` | VMID de la VM creada |
| `vm_name` | Nombre de la VM creada |
| `ip` | IP estática de la VM |
