#!/usr/bin/env bash
# =============================================================================
# scripts/proxmox-vm.sh
# Levanta Proxmox VE virtualizado con QEMU/KVM para el entorno local de ARQ3D.
# =============================================================================
set -euo pipefail

# ---------------------------------------------------------------------------
# Valores por defecto
# ---------------------------------------------------------------------------
: "${PROXMOX_IP:=10.10.10.2}"
: "${PROXMOX_HOST_IP:=10.10.10.1}"
: "${PROXMOX_NET_CIDR:=24}"
: "${BRIDGE_NAME:=br-arq3d}"
: "${TAP_NAME:=tap0}"
: "${OUTBOUND_IFACE:=$(ip route | awk '/default/ {print $5}' | head -1)}"
: "${VM_NAME:=Proxmox-TFG}"
: "${RAM_MB:=4096}"
: "${CPU_CORES:=4}"
: "${DISK_SIZE:=80G}"

# Detectar home del usuario real cuando se ejecuta con sudo.
# De lo contrario, sudo cambia $HOME a /root y no encuentra la ISO/disco.
if [[ -n "${SUDO_USER:-}" ]]; then
  REAL_HOME=$(getent passwd "${SUDO_USER}" | cut -d: -f6)
else
  REAL_HOME="${HOME}"
fi
: "${PROXMOX_BASE_DIR:=${REAL_HOME}/proxmox-tfg}"
: "${DISK_FILE:=${PROXMOX_BASE_DIR}/hdd_produccion.qcow2}"
: "${ISO_DIR:=${PROXMOX_BASE_DIR}}"
: "${ISO_URL:=https://www.proxmox.com/en/downloads/item/proxmox-virtual-environment-8-3-iso-installer}"
: "${ISO_FILE:=}"
: "${QEMU_BINARY:=qemu-system-x86_64}"

# ---------------------------------------------------------------------------
# Funciones auxiliares
# ---------------------------------------------------------------------------
log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"; }

err() { log "ERROR: $*" >&2; exit 1; }

usage() {
  cat <<EOF
Uso: $0 {network|install|run|destroy|status} [opciones]

Subcomandos:
  network   Crear bridge y TAP en el host.
  install   Crear disco, descargar ISO si es necesario y arrancar Proxmox
            desde la ISO para instalarlo.
  run       Arrancar Proxmox ya instalado desde el disco QCOW2.
  check     Verificar dependencias, ISO y disco sin arrancar QEMU.
  destroy   Eliminar el disco, TAP y bridge (pide confirmación).
  status    Mostrar estado de red, disco y proceso QEMU.

Variables de entorno (con valores por defecto):
  PROXMOX_IP=${PROXMOX_IP}
  PROXMOX_HOST_IP=${PROXMOX_HOST_IP}
  BRIDGE_NAME=${BRIDGE_NAME}
  TAP_NAME=${TAP_NAME}
  OUTBOUND_IFACE=${OUTBOUND_IFACE}
  RAM_MB=${RAM_MB}
  CPU_CORES=${CPU_CORES}
  DISK_SIZE=${DISK_SIZE}
  PROXMOX_BASE_DIR=${PROXMOX_BASE_DIR}
  DISK_FILE=${DISK_FILE}
  ISO_DIR=${ISO_DIR}
  ISO_FILE=${ISO_FILE:-<auto-detect>}

Ejemplos:
  $0 network
  $0 install
  $0 run
  $0 status
  $0 destroy
EOF
}

check_root_or_sudo() {
  if [[ "${EUID}" -ne 0 ]]; then
    err "Este subcomando requiere ejecutarse como root o con sudo."
  fi
}

check_deps() {
  local missing=()
  for cmd in "${QEMU_BINARY}" qemu-img ip iptables; do
    if ! command -v "${cmd}" &>/dev/null; then
      missing+=("${cmd}")
    fi
  done
  if [[ ${#missing[@]} -gt 0 ]]; then
    err "Faltan dependencias: ${missing[*]}. Instala qemu-utils, qemu-system-x86, iproute2 e iptables."
  fi
}

find_iso() {
  if [[ -n "${ISO_FILE}" && -f "${ISO_FILE}" ]]; then
    echo "${ISO_FILE}"
    return
  fi
  local iso
  iso=$(find "${ISO_DIR}" -maxdepth 1 -name 'proxmox-ve_*.iso' -print -quit 2>/dev/null || true)
  if [[ -n "${iso}" ]]; then
    echo "${iso}"
    return
  fi
  echo ""
}

# ---------------------------------------------------------------------------
# Subcomandos
# ---------------------------------------------------------------------------

cmd_network() {
  check_root_or_sudo
  check_deps

  log "Creando red local para Proxmox..."

  if ! ip link show "${BRIDGE_NAME}" &>/dev/null; then
    ip link add name "${BRIDGE_NAME}" type bridge
    ip addr add "${PROXMOX_HOST_IP}/${PROXMOX_NET_CIDR}" dev "${BRIDGE_NAME}"
    ip link set dev "${BRIDGE_NAME}" up
    log "Bridge ${BRIDGE_NAME} creado con IP ${PROXMOX_HOST_IP}/${PROXMOX_NET_CIDR}."
  else
    log "Bridge ${BRIDGE_NAME} ya existe."
  fi

  if ! ip link show "${TAP_NAME}" &>/dev/null; then
    ip tuntap add dev "${TAP_NAME}" mode tap user "${SUDO_USER:-${USER}}"
    ip link set "${TAP_NAME}" master "${BRIDGE_NAME}"
    ip link set dev "${TAP_NAME}" up
    log "Interfaz TAP ${TAP_NAME} creada y unida a ${BRIDGE_NAME}."
  else
    log "Interfaz TAP ${TAP_NAME} ya existe."
  fi

  if [[ -n "${OUTBOUND_IFACE}" ]]; then
    sysctl -w net.ipv4.ip_forward=1 >/dev/null
    if ! iptables -t nat -C POSTROUTING -o "${OUTBOUND_IFACE}" -j MASQUERADE &>/dev/null; then
      iptables -t nat -A POSTROUTING -o "${OUTBOUND_IFACE}" -j MASQUERADE
      log "NAT habilitado hacia ${OUTBOUND_IFACE}."
    else
      log "NAT ya estaba habilitado."
    fi
  else
    log "AVISO: no se detectó interfaz de salida; NAT no configurado."
  fi

  log "Red lista. Puedes continuar con: $0 install"
}

cmd_install() {
  check_root_or_sudo
  check_deps

  mkdir -p "$(dirname "${DISK_FILE}")" "${ISO_DIR}"

  if [[ ! -f "${DISK_FILE}" ]]; then
    log "Creando disco ${DISK_FILE} de ${DISK_SIZE}..."
    qemu-img create -f qcow2 "${DISK_FILE}" "${DISK_SIZE}"
  else
    log "Disco ${DISK_FILE} ya existe."
  fi

  local iso
  iso=$(find_iso)
  if [[ -z "${iso}" ]]; then
    log "No se encontró ISO de Proxmox en ${ISO_DIR}."
    log "Descarga la ISO manualmente desde:"
    log "  ${ISO_URL}"
    err "Colócala en ${ISO_DIR} y vuelve a ejecutar: $0 install"
  fi

  log "Arrancando instalación de Proxmox desde ${iso}..."
  log "Completa la instalación gráfica. La contraseña de root la eliges tú."

  exec "${QEMU_BINARY}" \
    -m "${RAM_MB}" \
    -smp "${CPU_CORES}" \
    -enable-kvm \
    -cpu host \
    -name "${VM_NAME}" \
    -hda "${DISK_FILE}" \
    -cdrom "${iso}" \
    -netdev tap,id=net0,ifname="${TAP_NAME}",script=no,downscript=no \
    -device virtio-net-pci,netdev=net0 \
    -display gtk
}

cmd_run() {
  check_root_or_sudo
  check_deps

  if [[ ! -f "${DISK_FILE}" ]]; then
    err "No existe ${DISK_FILE}. Ejecuta primero: $0 install"
  fi

  log "Arrancando Proxmox desde ${DISK_FILE}..."

  exec "${QEMU_BINARY}" \
    -m "${RAM_MB}" \
    -smp "${CPU_CORES}" \
    -enable-kvm \
    -cpu host \
    -name "${VM_NAME}" \
    -hda "${DISK_FILE}" \
    -netdev tap,id=net0,ifname="${TAP_NAME}",script=no,downscript=no \
    -device virtio-net-pci,netdev=net0 \
    -display gtk
}

cmd_status() {
  log "Estado de red:"
  ip -brief addr show "${BRIDGE_NAME}" 2>/dev/null || log "  ${BRIDGE_NAME}: no existe"
  ip -brief link show "${TAP_NAME}" 2>/dev/null || log "  ${TAP_NAME}: no existe"

  log "Estado del disco:"
  if [[ -f "${DISK_FILE}" ]]; then
    ls -lh "${DISK_FILE}"
    qemu-img info "${DISK_FILE}" | head -5
  else
    log "  ${DISK_FILE}: no existe"
  fi

  log "Procesos QEMU:"
  pgrep -a "${QEMU_BINARY}" || log "  No hay procesos ${QEMU_BINARY} en ejecución."

  log "ISO disponible:"
  find_iso || log "  Ninguna"
}

cmd_check() {
  log "Comprobando entorno para Proxmox en QEMU..."
  check_deps

  log "Directorio base: ${PROXMOX_BASE_DIR}"
  log "Disco:           ${DISK_FILE}"
  log "ISO dir:         ${ISO_DIR}"

  local iso
  iso=$(find_iso)
  if [[ -n "${iso}" ]]; then
    log "ISO encontrada:  ${iso}"
  else
    err "No se encontró ISO de Proxmox en ${ISO_DIR}. Descárgala desde ${ISO_URL}"
  fi

  if [[ -f "${DISK_FILE}" ]]; then
    log "Disco encontrado: ${DISK_FILE}"
  else
    log "Disco no existe; se creará en la instalación."
  fi

  log "Todo listo para 'install' o 'run'."
}

cmd_destroy() {
  check_root_or_sudo

  read -rp "¿Eliminar disco, red y proceso QEMU? Esto borra datos. Escribe 'si': " confirm
  if [[ "${confirm}" != "si" ]]; then
    log "Cancelado."
    exit 0
  fi

  pkill -f "${VM_NAME}" || true
  sleep 1

  if ip link show "${TAP_NAME}" &>/dev/null; then
    ip link del "${TAP_NAME}"
    log "TAP ${TAP_NAME} eliminado."
  fi

  if ip link show "${BRIDGE_NAME}" &>/dev/null; then
    ip link del "${BRIDGE_NAME}"
    log "Bridge ${BRIDGE_NAME} eliminado."
  fi

  if [[ -f "${DISK_FILE}" ]]; then
    rm -f "${DISK_FILE}"
    log "Disco ${DISK_FILE} eliminado."
  fi

  log "Destrucción completa."
}

# ---------------------------------------------------------------------------
# Punto de entrada
# ---------------------------------------------------------------------------
main() {
  if [[ $# -lt 1 ]]; then
    usage
    exit 1
  fi

  local subcommand="$1"
  shift

  case "${subcommand}" in
    network) cmd_network "$@" ;;
    install) cmd_install "$@" ;;
    run) cmd_run "$@" ;;
    check) cmd_check "$@" ;;
    status) cmd_status "$@" ;;
    destroy) cmd_destroy "$@" ;;
    -h|--help|help) usage; exit 0 ;;
    *) usage; err "Subcomando desconocido: ${subcommand}" ;;
  esac
}

main "$@"
