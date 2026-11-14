# Evolución del Proyecto ARQ3D

Este documento describe la hoja de ruta y las fases previstas. Cada fase
añade valor observable y documentado.

## Fase 1: Base reproducible (completada)

- Terraform con provider `bpg/proxmox` y API token.
- Ansible con roles estructurados y variables coherentes.
- Red unificada en `10.10.10.0/24`.
- CI con GitHub Actions validando Terraform, Ansible, Helm y YAML.
- K3s con ArgoCD, NGINX Ingress y Sealed Secrets.

## Fase 2: Seguridad y persistencia (en progreso)

- [x] WordPress con PVC `ReadWriteMany` sobre `nfs-client`.
- [x] MySQL como StatefulSet single-instance.
- [x] NetworkPolicies para WordPress y MySQL.
- [x] ServiceAccount sin automount de token.
- [x] AppProject con whitelist explícita.
- [x] ArgoCD sin `--insecure` y con Ingress HTTPS.
- [ ] Provisionar backend de PVCs real (NFS/SMB).
- [ ] Generar SealedSecret real de MySQL.
- [ ] Crear secretos TLS `wordpress-tls` y `argocd-server-tls`.
- [ ] Instalar cert-manager para certificados gestionados.

## Fase 3: Observabilidad

- Instalar `kube-prometheus-stack` mediante ArgoCD.
- Configurar Grafana con dashboards de infraestructura y aplicaciones.
- Configurar Alertmanager con rutas de notificación.
- Activar ServiceMonitor de MySQL cuando Prometheus esté disponible.
- Añadir PVCs para Prometheus y Grafana.
- Configurar `remote_write` o backup de métricas a S3/MinIO.

## Fase 4: Backup y recuperación

- Backups automáticos de MySQL.
- Backups de contenido de WordPress.
- Backups del estado de ArgoCD.
- Export periódico de LDAP.
- Pruebas de restauración documentadas.

## Fase 5: Alta disponibilidad y producción

- Evaluar múltiples masters de K3s.
- Evaluar MySQL Operator o Percona para HA.
- Separar entornos (lab/staging/prod).
- Políticas de red más restrictivas.
- Autenticación centralizada con LDAP para ArgoCD/Grafana.

## Fase 6: Optimización y portfolio

- Refinar recursos y límites de cada workload.
- Añadir tests de humo al pipeline.
- Crear diagramas actualizados en `docs/diagrams/`.
- Documentar casos de uso para entrevistas.
- Publicar blog o README orientado a portfolio.

## Criterios para pasar de una fase a otra

1. Los checks de CI son verdes.
2. Se ha validado manualmente en el laboratorio.
3. La documentación afectada está actualizada.
4. Existe un plan de rollback.
5. No se introducen secretos ni estados en el repositorio.

## Notas

- Las fases 1 y 2 son necesarias para tener un proyecto desplegable.
- Las fases 3 y 4 son necesarias para considerarlo operable.
- Las fases 5 y 6 lo convierten en evidencia profesional sólida.
