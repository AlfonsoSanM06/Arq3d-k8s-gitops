# Estructura del Proyecto

## Contexto

ARQ3D es una infraestructura cloud-native sobre Proxmox VE. Terraform crea las VMs, Ansible configura el sistema operativo y K3s, Terraform/Helm instala los controladores del clúster y ArgoCD despliega las aplicaciones desde Git.

## Árbol de directorios

```text
TFG-asir/
├── Agent.md                          # Reglas específicas del proyecto para agentes
├── AGENTS.MD                         # Plantilla base de reglas para agentes
├── IA-docs/                          # Plantillas compartidas de documentación (sin .git interno)
│   ├── docs-shared/                  # Plantillas y estándares reutilizables
│   └── scripts/                      # Scripts para crear docs en nuevos proyectos
├── README.md                        # Visión general y guía de despliegue
├── .github/
│   └── workflows/
│       └── ci.yml                   # Validaciones automáticas de CI
├── assets/                          # Diagramas y material visual
├── terraform-proxmox/               # Capa 1: VMs declarativas en Proxmox
│   ├── backend.tf                    # Backend remoto y locking del estado
│   ├── main.tf                       # Recursos y composición de VMs
│   ├── variables.tf                  # Contrato de entrada
│   ├── outputs.tf                    # Datos exportados a otras capas
│   ├── versions.tf                   # Versiones de Terraform y providers
│   ├── terraform.tfvars.example      # Plantilla sin secretos
│   └── modules/
│       └── vm/                       # Módulo reutilizable de máquinas virtuales
├── ansible/                         # Capa 2: configuración y hardening del SO
│   ├── site.yml                      # Orquestador principal
│   ├── inventory.yml                 # Inventario de hosts
│   ├── ansible.cfg                   # Configuración de Ansible
│   ├── requirements.yml              # Dependencias de Ansible Galaxy
│   ├── group_vars/
│   │   ├── all.yml                   # Variables comunes no sensibles
│   │   └── vault.yml                 # Variables sensibles cifradas
│   ├── playbooks/                    # Ejecución ordenada por capacidad
│   └── roles/                        # hardening, k3s, ldap y nfs
├── k8s-cluster/                      # Capas 3 y 4: plataforma K3s y GitOps
│   ├── k8s_argocd/
│   │   └── argocd_terraform/         # ArgoCD, NGINX y Sealed Secrets vía Helm
│   ├── argocd-apps/                  # App-of-Apps y recursos GitOps
│   └── wordpress/
│       └── wordpress-mysql/          # Chart WordPress + MySQL
│           ├── templates/            # Manifiestos parametrizados
│           └── charts/                # Subcharts y dependencias fijadas
└── docs/
    ├── README.md                      # Índice de documentación
    ├── project_structure.md           # Este documento
    ├── methodology.md                 # Flujo de trabajo y CI/CD
    ├── context.md                     # Contexto, entornos y supuestos
    ├── architecture.md                # Arquitectura y diagramas
    ├── evolution.md                   # Hoja de ruta del proyecto
    ├── decisions/                     # Decisiones técnicas
    ├── runbooks/                      # Procedimientos operativos
    ├── learning/                      # Materiales de aprendizaje
    └── errors/
        └── error_log.md               # Incidencias y post-mortems
```

## Responsabilidad de los directorios principales

| Directorio | Responsabilidad | Fuente de verdad | Validación habitual |
|---|---|---|---|
| `.github/` | Automatización de CI y controles de calidad | Git | GitHub Actions |
| `terraform-proxmox/` | Ciclo de vida de las VMs | Terraform state + Git | `fmt`, `validate`, `plan` |
| `ansible/` | Estado deseado del SO y servicios base | Git + Vault | `ansible-lint`, check mode |
| `k8s-cluster/k8s_argocd/` | Controladores de plataforma del clúster | Terraform state + Git | Terraform + Helm |
| `k8s-cluster/argocd-apps/` | Aplicaciones y permisos GitOps | Git | YAML + ArgoCD |
| `k8s-cluster/wordpress/` | Empaquetado de WordPress y MySQL | Git | `helm lint`, renderizado |
| `docs/` | Diseño, operación y aprendizaje del sistema | Git | Revisión documental |
| `assets/` | Diagramas que explican la arquitectura | Git | Revisión visual |

Los directorios `src/` y `scripts/` no existen actualmente porque este repositorio gestiona infraestructura y configuración, no código de aplicación. Se añadirán solo cuando exista una necesidad real y con su responsabilidad documentada.

## Nota sobre `IA-docs/`

`IA-docs/` contiene plantillas compartidas de documentación. Si se copia desde
otro repositorio Git, hay que eliminar su directorio `.git` interno antes de
añadirlo al proyecto; de lo contrario Git lo tratará como submódulo y fallará
al hacer `git add .`.

```bash
# Ejemplo de copia segura a otro proyecto
rsync -av --exclude='.git' IA-docs/ /ruta/otro-proyecto/IA-docs/
```
