# Contexto del Proyecto ARQ3D

## Propósito

ARQ3D es una infraestructura cloud-native completa diseñada para aprender y
demostrar prácticas DevOps sobre un entorno real de máquinas virtuales. El
objetivo es construir un pipeline reproducible que va desde el
aprovisionamiento bare-metal/hipervisor hasta el despliegue continuo de
aplicaciones mediante GitOps.

Este proyecto sirve como:

- Portfolio técnico para la transición de sysadmin a DevOps.
- Laboratorio reproducible de Terraform, Ansible, Kubernetes y ArgoCD.
- Base documentada para futuras mejoras de seguridad, observabilidad y alta
disponibilidad.

## Alcance actual

El repositorio gestiona:

1. **Capa 1 — VMs:** Terraform + provider `bpg/proxmox` crea 4 VMs en
   Proxmox VE.
2. **Capa 2 — Sistema operativo:** Ansible aplica hardening, monta
   almacenamiento, instala K3s y configura OpenLDAP.
3. **Capa 3 — Plataforma Kubernetes:** Terraform/Helm instala ArgoCD,
   NGINX Ingress Controller y Sealed Secrets.
4. **Capa 4 — Aplicaciones:** ArgoCD despliega WordPress + MySQL desde Git.

## Entornos

Actualmente existe un único entorno físico/lógico:

| Entorno | Red | Propósito |
|---|---|---|
| Lab/Producción inicial | `10.10.10.0/24` | Desarrollo, pruebas y demostración del stack completo. |

Pendiente de verificar: si en el futuro se añaden entornos `staging` o
`pre`, se separarán por namespaces, redes o clústeres y se documentarán aquí.

## Red

```text
VLAN 10 (clúster):  10.10.10.0/24
Gateway:            10.10.10.1
DNS:                8.8.8.8 (configurable)

Servicios:
  k8s-master-01:    10.10.10.11
  k8s-worker-01:    10.10.10.12
  k8s-worker-02:    10.10.10.13
  ldap-server:      10.10.10.20

VLAN 20 (almacenamiento): 192.168.20.0/24
  TrueNAS/SMB/NFS:  192.168.20.100
```

La red de almacenamiento puede cambiar según la decisión final sobre el
backend de PVCs. Ver [`decisions/storage-backend.md`](decisions/storage-backend.md).

## Dependencias externas

| Componente | Ubicación | Gestión | Notas |
|---|---|---|---|
| Proxmox VE | Bare-metal/hipervisor | Manual / externo | Debe tener un API token dedicado para Terraform. |
| NAS / TrueNAS / Samba | Red de almacenamiento | Manual / externo | El usuario dispone de una Raspberry Pi con Samba. Ver [`decisions/storage-backend.md`](decisions/storage-backend.md). |
| Router/firewall | VLAN 10 y 20 | Manual / externo | Debe permitir tráfico K3s y acceso al almacenamiento. |
| DNS local | Red interna | Manual / externo | `alfonso.local`, `argo.alfonso.local`. |

## Supuestos

- Se dispone de un hipervisor Proxmox VE con una plantilla Cloud-Init de
  Ubuntu 22.04.
- Las VMs tienen conectividad saliente para descargar paquetes e imágenes.
- Se dispone de un par de claves SSH ED25519 para administración.
- Se dispone de un backend S3 (AWS o MinIO) para el estado de Terraform.
- Se dispone de un almacén de secretos local seguro para `terraform.tfvars`,
  `.vault_pass` y kubeconfigs.

## Qué NO incluye todavía

- Provisionador dinámico de volúmenes (CSI/NFS/SMB) en Kubernetes.
- Cert-manager y certificados TLS gestionados automáticamente.
- Stack de monitorización Prometheus/Grafana/Alertmanager.
- Backups automáticos de MySQL, WordPress, LDAP y estado de ArgoCD.
- Alta disponibilidad real del plano de control de K3s.

Ver [`evolution.md`](evolution.md) para la hoja de ruta.

## Glosario rápido

| Término | Significado |
|---|---|
| IaC | Infrastructure as Code. |
| GitOps | El estado deseado del clúster vive en Git; ArgoCD lo reconcilia. |
| PVC | Persistent Volume Claim; volumen persistente solicitado por un pod. |
| Sealed Secret | Secret Kubernetes cifrado que solo el clúster puede descifrar. |
| CSI | Container Storage Interface; estándar para drivers de almacenamiento. |
