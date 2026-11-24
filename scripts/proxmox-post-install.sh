#!/usr/bin/env bash
# =============================================================================
# scripts/proxmox-post-install.sh
# Configura Proxmox tras la instalación desde ISO y crea la plantilla
# cloud-init para el despliegue de ARQ3D.
# =============================================================================
set -euo pipefail

# ---------------------------------------------------------------------------
# Valores por defecto
# ---------------------------------------------------------------------------
: "${PROXMOX_IP:=10.10.10.2}"
: "${PROXMOX_HOSTNAME:=pve-arq3d}"
: "${PROXMOX_DOMAIN:=proxmox.com}"
: "${PROXMOX_FQDN:=${PROXMOX_HOSTNAME}.${PROXMOX_DOMAIN}}"
: "${PROXMOX_GW:=10.10.10.1}"
: "${PROXMOX_DNS:=8.8.8.8}"
: "${PROXMOX_BRIDGE:=vmbr0}"
: "${PROXMOX_NET_CIDR:=24}"
: "${PROXMOX_USER:=root}"
: "${TERRAFORM_USER:=terraform@pam}"
: "${TERRAFORM_TOKEN_NAME:=tfg-token}"
: "${VM_TEMPLATE_ID:=9000}"
: "${VM_TEMPLATE_NAME:=ubuntu-2204-cloud-init}"
: "${UBUNTU_IMAGE_URL:=https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img}"
: "${UBUNTU_IMAGE_NAME:=jammy-server-cloudimg-amd64.img}"

# ---------------------------------------------------------------------------
# Funciones auxiliares
# ---------------------------------------------------------------------------
log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"; }

err() { log "ERROR: $*" >&2; exit 1; }

usage() {
  cat <<EOF
Uso: $0 [opciones]

Configura Proxmox tras la instalación desde ISO:
  - Fija red estática, hostname y /etc/hosts.
  - Crea usuario/terraform API token.
  - Descarga imagen cloud-init de Ubuntu 22.04.
  - Crea plantilla VMID ${VM_TEMPLATE_ID}.

Variables de entorno:
  PROXMOX_IP=${PROXMOX_IP}
  PROXMOX_FQDN=${PROXMOX_FQDN}
  PROXMOX_GW=${PROXMOX_GW}
  PROXMOX_DNS=${PROXMOX_DNS}
  PROXMOX_USER=${PROXMOX_USER}
  TERRAFORM_USER=${TERRAFORM_USER}
  TERRAFORM_TOKEN_NAME=${TERRAFORM_TOKEN_NAME}
  VM_TEMPLATE_ID=${VM_TEMPLATE_ID}

Ejemplo:
  $0
  PROXMOX_IP=10.10.10.2 $0
EOF
}

wait_for_proxmox() {
  log "Esperando a que Proxmox responda en ${PROXMOX_IP}:8006..."
  local attempts=0
  while ! curl -sk "https://${PROXMOX_IP}:8006/api2/json/version" &>/dev/null; do
    attempts=$((attempts + 1))
    if [[ ${attempts} -gt 60 ]]; then
      err "Proxmox no responde tras 60 intentos. Verifica red e IP."
    fi
    sleep 5
  done
  log "Proxmox responde."
}

# ---------------------------------------------------------------------------
# Punto de entrada
# ---------------------------------------------------------------------------
main() {
  if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
    usage
    exit 0
  fi

  if ! command -v sshpass &>/dev/null && ! ssh -o BatchMode=yes "${PROXMOX_USER}@${PROXMOX_IP}" true &>/dev/null; then
    log "AVISO: no se detecta acceso SSH sin contraseña ni sshpass instalado."
    log "El script te pedirá la contraseña de root de Proxmox en cada comando."
  fi

  SSH_OPTS="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"

  run_ssh() {
    ssh ${SSH_OPTS} "${PROXMOX_USER}@${PROXMOX_IP}" "$@"
  }

  wait_for_proxmox

  log "Configurando red estática en Proxmox..."
  run_ssh "cat > /etc/network/interfaces" <<EOF
auto lo
iface lo inet loopback

iface ${PROXMOX_BRIDGE} inet static
    address ${PROXMOX_IP}/${PROXMOX_NET_CIDR}
    gateway ${PROXMOX_GW}
    bridge-ports nic0
    bridge-stp off
    bridge-fd 0

iface nic0 inet manual
EOF

  log "Configurando /etc/hosts..."
  run_ssh "cat > /etc/hosts" <<EOF
127.0.0.1 localhost.localdomain localhost
${PROXMOX_IP} ${PROXMOX_FQDN} ${PROXMOX_HOSTNAME}

# The following lines are desirable for IPv6 capable hosts
::1     ip6-localhost ip6-loopback
fe00::0 ip6-localnet
ff00::0 ip6-mcastprefix
ff02::1 ip6-allnodes
ff02::2 ip6-allrouters
EOF

  log "Configurando hostname..."
  run_ssh "hostnamectl set-hostname ${PROXMOX_FQDN}"

  log "Reiniciando red y pveproxy..."
  run_ssh "systemctl restart networking && systemctl restart pveproxy"

  log "Creando usuario API ${TERRAFORM_USER}..."
  run_ssh "pveum user add ${TERRAFORM_USER} 2>/dev/null || true"
  run_ssh "pveum acl modify / -user ${TERRAFORM_USER} -role PVEVMAdmin"

  log "Creando token API ${TERRAFORM_TOKEN_NAME}..."
  log "============================================================================"
  log "GUARDA EL SECRETO QUE APARECE A CONTINUACIÓN. NO SE VOLVERÁ A MOSTRAR."
  log "============================================================================"
  run_ssh "pveum user token add ${TERRAFORM_USER} ${TERRAFORM_TOKEN_NAME} --privsep=1"

  log "Descargando imagen cloud-init de Ubuntu 22.04..."
  run_ssh "mkdir -p /root/cloud-images && cd /root/cloud-images && wget -q --show-progress -O ${UBUNTU_IMAGE_NAME} ${UBUNTU_IMAGE_URL}"

  log "Creando plantilla cloud-init VMID ${VM_TEMPLATE_ID}..."
  run_ssh "
set -e
qm destroy ${VM_TEMPLATE_ID} 2>/dev/null || true
qm create ${VM_TEMPLATE_ID} --name ${VM_TEMPLATE_NAME} --memory 2048 --net0 virtio,bridge=${PROXMOX_BRIDGE}
qm importdisk ${VM_TEMPLATE_ID} /root/cloud-images/${UBUNTU_IMAGE_NAME} local-lvm
qm set ${VM_TEMPLATE_ID} --scsihw virtio-scsi-pci --scsi0 local-lvm:vm-${VM_TEMPLATE_ID}-disk-0
qm set ${VM_TEMPLATE_ID} --ide2 local-lvm:cloudinit
qm set ${VM_TEMPLATE_ID} --boot c --bootdisk scsi0
qm set ${VM_TEMPLATE_ID} --serial0 socket --vga serial0
qm template ${VM_TEMPLATE_ID}
"

  log "============================================================================"
  log "Post-instalación completada."
  log "============================================================================"
  log "Resumen:"
  log "  - Proxmox: https://${PROXMOX_IP}:8006"
  log "  - Hostname: ${PROXMOX_FQDN}"
  log "  - Usuario API: ${TERRAFORM_USER}"
  log "  - Token: ${TERRAFORM_TOKEN_NAME}"
  log "  - Plantilla cloud-init: VMID ${VM_TEMPLATE_ID} (${VM_TEMPLATE_NAME})"
  log ""
  log "Pasos siguientes:"
  log "  1. Copia el token secreto en terraform-proxmox/terraform.tfvars"
  log "  2. Ejecuta: cd terraform-proxmox && terraform init && terraform apply"
  log "============================================================================"
}

main "$@"
