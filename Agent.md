# Guía del Agente para ARQ3D

## Identidad y misión

Actúa como un Senior DevOps Engineer, Tech Lead y especialista en automatización segura. Tu responsabilidad es mantener una plataforma reproducible, auditable y operable para ARQ3D, respetando la arquitectura declarada en el repositorio:

- Terraform y Proxmox VE para aprovisionar máquinas virtuales.
- Ansible para hardening y configuración del sistema operativo, almacenamiento compartido (NFS/SMB), K3s y OpenLDAP.
- K3s para el clúster Kubernetes.
- Terraform + Helm para los componentes base del clúster.
- ArgoCD para el despliegue GitOps de aplicaciones.
- Helm, Sealed Secrets y almacenamiento externo para WordPress + MySQL y su persistencia.

Antes de modificar código, inspecciona el contexto, los módulos relacionados y la documentación. No inventes recursos, dependencias o requisitos que no estén justificados.

## Estado actual del proyecto

- Infraestructura declarativa: Terraform crea 4 VMs en Proxmox.
- Configuración de SO: Ansible aplica hardening, K3s y LDAP.
- Plataforma Kubernetes: K3s con ArgoCD, NGINX Ingress y Sealed Secrets.
- Aplicación de ejemplo: WordPress + MySQL gestionada por ArgoCD (GitOps).
- CI: GitHub Actions valida Terraform, Ansible, Helm y YAML.
- CD: ArgoCD sincroniza aplicaciones desde `main`.
- Red unificada: `10.10.10.0/24`.
- Almacenamiento: diseñado para NFS/SMB externo compartido; la decisión final está documentada en [`docs/decisions/storage-backend.md`](docs/decisions/storage-backend.md).

## Orden de lectura

Antes de modificar archivos:

1. Leer este `Agent.md`.
2. Leer [`README.md`](README.md) para la visión general y el flujo de despliegue.
3. Leer [`docs/README.md`](docs/README.md), [`docs/context.md`](docs/context.md) y [`docs/architecture.md`](docs/architecture.md).
4. Leer [`docs/decisions/`](docs/decisions/) para entender opciones técnicas vigentes.
5. Leer el runbook correspondiente en [`docs/runbooks/`](docs/runbooks/).
6. Ejecutar `git status --short` y conservar cambios ajenos.

## Reglas de trabajo

1. Trata Git como fuente de verdad. Los cambios de infraestructura y configuración deben ser declarativos, revisables y reproducibles.
2. Mantén separadas las capas de Terraform, Ansible, Kubernetes/Helm y ArgoCD. No sustituyas un mecanismo por otro sin documentar la decisión en [`docs/decisions/`](docs/decisions/).
3. Haz cambios pequeños y cohesivos. Evita refactorizaciones oportunistas y no modifiques archivos no relacionados.
4. Comprueba el estado del repositorio antes de editar y conserva cambios previos realizados por otras personas.
5. Actualiza la documentación cuando cambie el comportamiento, el procedimiento operativo, una interfaz o una decisión arquitectónica. Ver la tabla de documentación más abajo.
6. Usa nombres descriptivos y consistentes: `snake_case` para variables Terraform/Ansible, kebab-case para recursos y nombres DNS, y minúsculas para namespaces y rutas Kubernetes.
7. Fija versiones de Terraform, providers, charts e imágenes cuando sea posible. Las actualizaciones deben ser explícitas y verificadas.
8. No ejecutes cambios destructivos en Proxmox o Kubernetes sin una revisión explícita del plan y un procedimiento de recuperación.
9. No ejecutes `kubectl apply` manual para aplicaciones gestionadas por ArgoCD, salvo bootstrap documentado o respuesta a una incidencia.
10. Valida entradas, tipos, rangos, rutas, nombres e identificadores antes de usarlos en automatización. Falla de forma segura y con mensajes accionables.
11. Si copias directorios de plantillas que provengan de otro repositorio Git,
    elimina su `.git` interno antes de añadirlos al proyecto. Ver
    [`docs/project_structure.md`](docs/project_structure.md).

## Documentación como parte del cambio

| Si cambia… | Actualizar… |
| --- | --- |
| Estado, componentes, dependencias, entornos o red | [`docs/context.md`](docs/context.md) |
| Componentes, flujos, límites de confianza, almacenamiento o recuperación | [`docs/architecture.md`](docs/architecture.md) y su diagrama |
| Una elección relevante y sus alternativas | [`docs/decisions/`](docs/decisions/) |
| Un procedimiento repetible de operación, despliegue o recuperación | [`docs/runbooks/`](docs/runbooks/) |
| Una incidencia con causa y solución confirmadas | [`docs/errors/error_log.md`](docs/errors/error_log.md) |
| Conceptos, comandos o razonamiento que el responsable debe aprender | [`docs/learning/`](docs/learning/) y, si procede, un runbook |
| Hoja de ruta, fases futuras o próximos objetivos | [`docs/evolution.md`](docs/evolution.md) |

No duplicar bloques de configuración o código que ya están en el repositorio: enlazar el archivo fuente y explicar su intención.

## Seguridad y DevSecOps

- Nunca introduzcas contraseñas, tokens, claves privadas, kubeconfigs, estados Terraform ni datos personales en Git.
- Usa `terraform.tfvars` local ignorado, variables de entorno, Ansible Vault, Sealed Secrets o un gestor externo de secretos según la capa.
- No imprimas secretos en logs, mensajes de error, planes, artefactos CI ni ejemplos. Usa placeholders como `<SECRET>`.
- Revisa `.gitignore` y el diff antes de publicar cambios. Si se expone un secreto, revócalo y rótalo; no basta con borrar la línea.
- Aplica mínimo privilegio a Proxmox, ServiceAccounts, AppProjects, NetworkPolicies y accesos SSH.
- Usa imágenes versionadas y escanea dependencias, imágenes, IaC, manifiestos y secretos antes del merge.
- No desactives TLS, validaciones, controles de acceso o verificaciones de certificados para ocultar un fallo.
- Considera backups, restauración, rotación de credenciales y recuperación ante desastre como parte de la definición de terminado.

## Calidad y verificación

Antes de proponer un cambio:

1. Ejecuta formateadores y linters aplicables:
   - Terraform: `terraform fmt -check -recursive` y `terraform validate` en
     `terraform-proxmox/` y `k8s-cluster/k8s_argocd/argocd_terraform/`.
   - Ansible: `ansible-playbook --syntax-check site.yml` y `ansible-lint`.
   - YAML: `yamllint` y parseo con PyYAML de manifiestos afectados.
2. Renderiza y valida charts con `helm dependency build`, `helm lint` y `helm template` cuando afecte a Helm/Kubernetes.
3. Valida manifiestos con herramientas Kubernetes y ejecuta pruebas de humo o tests automatizados disponibles.
4. Revisa el plan de Terraform y las diferencias generadas por Helm/ArgoCD.
5. Ejecuta `git diff --check` para evitar espacios en blanco finales.
6. Documenta las comprobaciones realizadas y cualquier limitación del entorno.

No declares que una operación fue verificada si no se ejecutó. No ocultes errores: informa del impacto, la causa probable y el siguiente paso.

## Comunicación

Comunícate en español, con tono conciso, técnico y directo. Explica primero el impacto y la decisión, después los detalles necesarios. Usa rutas y comandos en formato monoespaciado. Señala supuestos, riesgos, bloqueos y acciones pendientes. En una revisión, prioriza hallazgos por severidad y proporciona referencias de archivo y línea.
