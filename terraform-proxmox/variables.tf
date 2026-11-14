
# VARIABLES — arq3d-infrastructure

# Conexión a Proxmox

variable "proxmox_api_url" {
  description = "URL base HTTPS de Proxmox. Ej: https://192.168.1.10:8006/"
  type        = string
}

variable "proxmox_api_token_id" {
  description = "Identificador del API token de Proxmox. Formato: usuario@realm!token"
  type        = string
}

variable "proxmox_api_token_secret" {
  description = "Secreto del API token de Proxmox."
  type        = string
  sensitive   = true
}

variable "proxmox_node" {
  description = "Nombre del nodo Proxmox donde se crearán las VMs."
  type        = string
  default     = "pve"
}

variable "proxmox_tls_insecure" {
  description = "Deshabilitar verificación TLS (solo en desarrollo con cert self-signed)."
  type        = bool
  default     = false
}

# Plantilla Cloud-Init base

variable "vm_template_id" {
  description = "VMID numérico de la plantilla Cloud-Init"
  type        = number
  default     = 9000
}

variable "vm_storage_pool" {
  description = "Pool de almacenamiento de Proxmox donde se crean los discos de las VMs."
  type        = string
  default     = "local-lvm"
}


# Red — VLAN 10

variable "network_bridge" {
  description = "Bridge de red de Proxmox que mapea a la VLAN 10."
  type        = string
  default     = "vmbr0"
}

variable "network_vlan_tag" {
  description = "VLAN tag para la red de los nodos (VLAN 10 = clúster)."
  type        = number
  default     = 10
}

variable "network_gateway" {
  description = "Puerta de enlace de la VLAN 10."
  type        = string
  default     = "10.10.10.1"
}

variable "network_dns_servers" {
  description = "Servidores DNS para las VMs (separados por espacio en Cloud-Init)."
  type        = string
  default     = "8.8.8.8 8.8.4.4"
}

variable "network_cidr_prefix" {
  description = "Prefijo CIDR de la VLAN 10. Ej: 24 para /24."
  type        = number
  default     = 24
}

# Cloud-Init — Credenciales base

variable "ci_ssh_public_key" {
  description = "Clave pública SSH que se inyectará en todas las VMs."
  type        = string
  sensitive   = true
}

variable "ci_default_user" {
  description = "Usuario no-root creado por Cloud-Init en las VMs."
  type        = string
  default     = "arq3d"
}


# VM — Nodo Master K8s

variable "master_vm_id" {
  description = "VMID único en Proxmox para el nodo master."
  type        = number
  default     = 110
}

variable "master_ip" {
  description = "IP estática del nodo master (VLAN 10)."
  type        = string
  default     = "10.10.10.11"
}

variable "master_cpu" {
  type    = number
  default = 2
}

variable "master_ram_mb" {
  type    = number
  default = 4096
}

variable "master_disk_gb" {
  type    = number
  default = 40
}


# VM — Worker 01

variable "worker01_vm_id" {
  type    = number
  default = 111
}

variable "worker01_ip" {
  type    = string
  default = "10.10.10.12"
}

variable "worker01_cpu" {
  type    = number
  default = 4
}

variable "worker01_ram_mb" {
  type    = number
  default = 8192
}

variable "worker01_disk_gb" {
  type    = number
  default = 40
}


# VM — Worker 02

variable "worker02_vm_id" {
  type    = number
  default = 112
}

variable "worker02_ip" {
  type    = string
  default = "10.10.10.13"
}

variable "worker02_cpu" {
  type    = number
  default = 4
}

variable "worker02_ram_mb" {
  type    = number
  default = 8192
}

variable "worker02_disk_gb" {
  type    = number
  default = 40
}

# VM — LDAP Server

variable "ldap_vm_id" {
  type    = number
  default = 120
}

variable "ldap_ip" {
  type    = string
  default = "10.10.10.20"
}

variable "ldap_cpu" {
  type    = number
  default = 2
}

variable "ldap_ram_mb" {
  type    = number
  default = 4096
}

variable "ldap_disk_gb" {
  type    = number
  default = 30
}
