# scripts/ — Helpers para despliegue local

Scripts de utilidad para levantar un entorno Proxmox completo en una máquina local usando QEMU/KVM. Útil para hacer pruebas sin disponer de un hipervisor físico.

## Ficheros

| Script | Propósito |
|---|---|
| [`proxmox-vm.sh`](proxmox-vm.sh) | Crea red, disco, descarga/usa ISO y arranca Proxmox en QEMU. |
| [`proxmox-post-install.sh`](proxmox-post-install.sh) | Configura red estática, crea usuario API y plantilla cloud-init de Ubuntu 22.04. |

## Uso con Make

El [`Makefile`](../Makefile) expone los comandos más comunes:

```bash
make proxmox-check       # Verifica ISO, dependencias y disco sin arrancar QEMU
make proxmox-network     # Crea bridge + TAP + NAT (una sola vez)
make proxmox-install     # Instala Proxmox desde ISO (crea disco QCOW2)
make proxmox-run         # Arranca Proxmox ya instalado
make proxmox-post-install # Configura Proxmox y crea plantilla cloud-init
make proxmox-status      # Muestra estado de red, disco y proceso
make proxmox-destroy     # Elimina todo (¡cuidado!)
make validate            # Valida Terraform, Ansible y Helm del proyecto
```

## Flujo típico local

```bash
# Primera vez
make proxmox-network
make proxmox-install     # Instalas Proxmox manualmente desde la ISO en QEMU
make proxmox-post-install

# Siguientes arranques
make proxmox-run
```

El disco QCOW2 conserva la instalación, así que tras el primer despliegue basta con `make proxmox-run`.

## Requisitos del host

- `qemu-system-x86_64` y `qemu-img`
- `bridge-utils` o `iproute2`
- Virtualización habilitada (VT-x/AMD-V)
- ~16 GiB de RAM y ~60 GiB de disco libres
- La ISO de Proxmox descargada en `~/proxmox-tfg/` (nunca dentro del repo)

## Variables de entorno

Puedes personalizar el despliegue sin editar el script:

```bash
sudo PROXMOX_IP=10.10.10.2 \
     BRIDGE_NAME=br-arq3d \
     TAP_NAME=tap0 \
     RAM_MB=4096 \
     DISK_SIZE=80G \
     ./scripts/proxmox-vm.sh install
```

## Enlaces

- [README principal](../README.md)
- [Runbook de despliegue local](../docs/runbooks/local-deployment.md)
- [Makefile](../Makefile)
