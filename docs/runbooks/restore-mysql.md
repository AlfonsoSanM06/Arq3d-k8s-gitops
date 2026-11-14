# Runbook: Restauración de MySQL

## Objetivo

Restaurar la base de datos de WordPress desde un backup ante pérdida,
corrupción o desastre.

## Prerrequisitos

- Backup disponible: SQL dump o snapshot del PVC.
- Acceso al clúster con `kubectl`.
- MySQL en ejecución o capacidad de recrear el StatefulSet.

## Backup periódico (preparación)

Crear un Job de Kubernetes o un script cron que ejecute:

```bash
kubectl exec -n wp statefulset/wordpress-mysql-subchart -- \
  mysqldump -u root -p"$MYSQL_ROOT_PASSWORD" wordpress > backup-wordpress-$(date +%Y%m%d-%H%M%S).sql
```

Almacenar el dump en S3/MinIO o en el SMB de la Raspberry Pi.

## Restauración desde dump SQL

### 1. Escalar WordPress a cero réplicas

```bash
kubectl scale deployment/wordpress-dev -n wp --replicas=0
```

### 2. Eliminar datos actuales de MySQL (opcional)

```bash
kubectl exec -n wp statefulset/wordpress-mysql-subchart -- \
  rm -rf /var/lib/mysql/wordpress
```

### 3. Restaurar el dump

```bash
kubectl cp backup-wordpress-YYYYMMDD-HHMMSS.sql \
  wp/wordpress-mysql-subchart-0:/tmp/backup.sql

kubectl exec -it -n wp statefulset/wordpress-mysql-subchart -- \
  bash -c 'mysql -u root -p"$MYSQL_ROOT_PASSWORD" wordpress < /tmp/backup.sql'
```

### 4. Escalar WordPress

```bash
kubectl scale deployment/wordpress-dev -n wp --replicas=3
```

### 5. Verificar

```bash
kubectl logs -n wp deployment/wordpress-dev
kubectl get pods -n wp
```

## Restauración desde snapshot de PVC

1. Detener el StatefulSet de MySQL.
2. Restaurar el snapshot en el backend de almacenamiento.
3. Volver a crear el PVC.
4. Iniciar el StatefulSet.

## Resultado esperado

WordPress vuelve a funcionar con los datos del momento del backup.

## Riesgos

- Pérdida de datos desde el último backup.
- Inconsistencias si se restaura un dump parcial.
- Necesidad de regenerar sesiones o cachés de WordPress.

## Enlaces

- [`docs/decisions/storage-backend.md`](../decisions/storage-backend.md)
- [`docs/runbooks/rotate-secrets.md`](rotate-secrets.md)
