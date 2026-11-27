# Runbooks

Procedimientos operativos reproducibles para el proyecto ARQ3D.

| Runbook | Descripción |
|---|---|
| [`bootstrap.md`](bootstrap.md) | Despliegue completo desde cero (genérico). |
| [`local-deployment.md`](local-deployment.md) | Despliegue local con Proxmox en QEMU y sin NAS. |
| [`migrate-to-nas.md`](migrate-to-nas.md) | Migrar almacenamiento de `local-path` a NFS en Raspberry Pi NAS. |
| [`rotate-secrets.md`](rotate-secrets.md) | Rotación de credenciales y secretos. |
| [`restore-mysql.md`](restore-mysql.md) | Restauración de la base de datos de WordPress. |

## Convenciones

- Cada runbook incluye objetivo, prerrequisitos, pasos, validación, riesgos y
  rollback.
- Los comandos usan placeholders seguros.
- Si un paso requiere un secreto, se indica cómo obtenerlo, nunca su valor.
