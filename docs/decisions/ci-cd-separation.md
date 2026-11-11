# Decisión: Separación de CI y CD

## Contexto

El proyecto despliega infraestructura y aplicaciones en un clúster Kubernetes
privado. No es viable ni seguro que GitHub Actions acceda directamente al
clúster desde Internet para ejecutar `kubectl apply` o `helm upgrade`.

## Opciones evaluadas

### 1. GitHub Actions como CI + runner auto-hospedado como CD

- Un runner interno ejecuta los despliegues.
- **Ventajas:** control total del pipeline.
- **Inconvenientes:** requiere mantener un runner seguro y conectado; aumenta
  la superficie de ataque; no es GitOps puro.

### 2. GitHub Actions solo CI + ArgoCD como CD (GitOps)

- GitHub Actions valida cambios; ArgoCD los aplica.
- **Ventajas:** el clúster tira del estado desde Git; no se expone la API de
  Kubernetes; trazabilidad completa; despliegues reversibles.
- **Inconvenientes:** requiere instalar y configurar ArgoCD; el bootstrap
  inicial es manual.

### 3. Terraform como CD de controladores, GitHub Actions como CD de apps

- Similar a la opción 1 pero con Terraform Cloud o runners auto-hospedados.

## Decisión

Se adopta la **opción 2**:

```text
Git push
  |
  v
GitHub Actions: CI (validación)
  |
  v
ArgoCD: CD (sincronización con Kubernetes)
```

Terraform se usa para el aprovisionamiento inicial de infraestructura y
controladores, con aprobación humana del `plan`. ArgoCD gestiona el ciclo de
vida de las aplicaciones.

## Consecuencias

- El workflow `.github/workflows/ci.yml` no contiene kubeconfig ni acceso al
  clúster.
- ArgoCD es el único componente autorizado a modificar recursos en
  namespaces gestionados.
- Los despliegues de aplicaciones no requieren ejecutar comandos manuales tras
  el bootstrap inicial.
- Los cambios en `terraform-proxmox/` y `k8s-cluster/k8s_argocd/` requieren
  `terraform plan` y aprobación explícita.

## Condiciones para revisar esta decisión

- Se disponga de runners auto-hospedados muy controlados.
- Se requiera desplegar recursos que ArgoCD no pueda gestionar.
- Se migre a una plataforma de GitOps diferente (Flux, Rancher Fleet, etc.).
