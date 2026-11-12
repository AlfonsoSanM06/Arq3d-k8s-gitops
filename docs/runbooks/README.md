# Runbooks

Procedimientos operativos reproducibles para el proyecto ARQ3D.

| Runbook | Descripción |
|---|---|
| [`bootstrap.md`](bootstrap.md) | Despliegue completo desde cero. |
| [`rotate-secrets.md`](rotate-secrets.md) | Rotación de credenciales y secretos. |
| [`restore-mysql.md`](restore-mysql.md) | Restauración de la base de datos de WordPress. |

## Convenciones

- Cada runbook incluye objetivo, prerrequisitos, pasos, validación, riesgos y
  rollback.
- Los comandos usan placeholders seguros.
- Si un paso requiere un secreto, se indica cómo obtenerlo, nunca su valor.
