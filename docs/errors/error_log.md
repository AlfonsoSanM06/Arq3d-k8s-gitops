# Registro de Incidencias y Troubleshooting

Este documento registra incidentes relevantes, decisiones de recuperación y acciones preventivas. No debe incluir secretos, datos personales ni kubeconfigs.

## Clasificación de severidad

| Severidad | Criterio | Objetivo inicial |
|---|---|---|
| SEV-1 Crítica | Servicio principal caído, pérdida de datos o impacto amplio | Mitigar inmediatamente |
| SEV-2 Alta | Degradación relevante o función importante no disponible | Mitigar durante la jornada |
| SEV-3 Media | Impacto limitado con alternativa operativa | Corregir en el sprint |
| SEV-4 Baja | Sin impacto productivo; defecto o mejora | Planificar |

## Plantilla de nuevo incidente

```markdown
## INC-YYYY-NNN: <título breve>

- **ID del incidente:** INC-YYYY-NNN
- **Fecha y hora (UTC):** YYYY-MM-DD HH:MM
- **Fecha de resolución (UTC):** YYYY-MM-DD HH:MM
- **Severidad:** SEV-1 | SEV-2 | SEV-3 | SEV-4
- **Estado:** Abierto | Mitigado | Resuelto | Cerrado
- **Responsable:** <persona o equipo>
- **Servicios afectados:** <servicio, namespace, VM o pipeline>
- **Enlaces:** <issue, dashboard, logs, PR o alerta>

### Impacto
<Usuarios, duración, alcance y datos afectados.>

### Síntomas y detección
<Qué se observó, cómo se detectó y comandos o métricas relevantes.>

### Línea temporal
| Hora UTC | Evento | Responsable |
|---|---|---|
| HH:MM | <evento> | <equipo> |

### Causa raíz
<Causa técnica y factores contribuyentes, sin culpar a personas.>

### Solución aplicada
<Mitigación, cambio realizado y validación del servicio.>

### Prevención futura
- [ ] <Acción, responsable, fecha objetivo>
- [ ] <Acción, responsable, fecha objetivo>

### Lecciones aprendidas
<Qué funcionó, qué falló y qué debe cambiar en el proceso.>
```

## Ejemplo: crash crítico de MySQL en producción

## INC-2026-001: MySQL no arranca por volumen NFS no disponible

- **ID del incidente:** INC-2026-001
- **Fecha y hora (UTC):** 2026-02-14 09:10
- **Fecha de resolución (UTC):** 2026-02-14 10:02
- **Severidad:** SEV-1 Crítica
- **Estado:** Cerrado
- **Responsable:** Equipo de plataforma
- **Servicios afectados:** WordPress, MySQL, namespace `wp`
- **Enlaces:** Alerta de ArgoCD, issue `#184`, dashboard de Kubernetes

### Impacto

WordPress devolvió errores HTTP 503 durante 52 minutos. No se confirmó pérdida de datos: el PVC conservaba el contenido y el backup de la noche anterior estaba disponible.

### Síntomas y detección

La alerta de disponibilidad detectó fallos. El pod `mysql-0` estaba en `CrashLoopBackOff` y sus eventos mostraban que el volumen no podía montarse. Los logs indicaban errores de acceso al directorio de datos, no credenciales inválidas.

```bash
kubectl get pods -n wp
kubectl describe pod mysql-0 -n wp
kubectl get pvc -n wp
kubectl get events -n wp --sort-by=.lastTimestamp
```

### Línea temporal

| Hora UTC | Evento | Responsable |
|---|---|---|
| 09:10 | Alerta de WordPress no disponible | Monitorización |
| 09:14 | Se confirma `CrashLoopBackOff` y PVC pendiente de montaje | Plataforma |
| 09:25 | TrueNAS informa de una exportación NFS caída tras mantenimiento de red | Sistemas |
| 09:38 | Se restaura la exportación y se valida conectividad desde el worker | Sistemas |
| 09:47 | MySQL arranca y pasa su readiness probe | Plataforma |
| 10:02 | WordPress responde y ArgoCD queda `Synced/Healthy` | Plataforma |

### Causa raíz

Una regla de red aplicada durante el mantenimiento bloqueó temporalmente el tráfico NFS desde los workers hacia TrueNAS. La aplicación no tenía una alerta específica para la capacidad de montar el volumen y el runbook no indicaba una prueba de conectividad NFS.

### Solución aplicada

Se revirtió la regla de red incorrecta, se verificó el acceso NFS desde cada worker y se reinició el pod mediante la reconciliación normal de Kubernetes. Se ejecutó una comprobación funcional de WordPress y se verificó la integridad del PVC. No se modificaron datos manualmente.

### Prevención futura

- [x] Añadir una prueba de conectividad NFS al runbook de recuperación. Responsable: Plataforma. Fecha: 2026-02-14.
- [x] Añadir alerta para PVC no montado y errores de I/O. Responsable: Observabilidad. Fecha: 2026-02-21.
- [ ] Automatizar una prueba de restauración del backup mensual. Responsable: Sistemas. Fecha objetivo: 2026-03-15.
- [ ] Revisar cambios de red con checklist y ventana de mantenimiento. Responsable: Infraestructura. Fecha objetivo: 2026-02-28.

### Lecciones aprendidas

La recuperación fue rápida porque el almacenamiento y la configuración estaban declarados y el backup estaba separado del volumen activo. Faltaba observar explícitamente la dependencia NFS y probarla como parte del procedimiento de mantenimiento.
