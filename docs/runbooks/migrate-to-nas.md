# Migrar de `local-path` a NFS en Raspberry Pi NAS

Este runbook describe cómo migrar el despliegue local de ARQ3D desde
`local-path` (almacenamiento en disco del nodo worker) a un servidor **NFS
montado en una Raspberry Pi NAS**.

Se asume que ya tienes el despliegue local funcionando con `local-path` y que
la Raspberry Pi está en la misma red que el clúster K3s
(por defecto `10.10.10.0/24`).

## ¿Por qué migrar?

| Característica | `local-path` | NFS en Raspberry Pi |
|---|---|---|
| Requiere NAS | No | Sí |
| Modo de acceso | RWO | RWX |
| Réplicas de WordPress | 1 | 2-3 |
| Alta disponibilidad | Limitada | Sí |
| Backups centralizados | No | Sí |

## Paso 0: Preparar la Raspberry Pi como servidor NFS

### En la Raspberry Pi

```bash
# Instalar servidor NFS
sudo apt update
sudo apt install -y nfs-kernel-server

# Crear carpetas para WordPress y MySQL
sudo mkdir -p /srv/nfs/wordpress
sudo mkdir -p /srv/nfs/mysql

# Ajustar propietario al UID que usa WordPress en el contenedor
sudo chown -R 1000:1000 /srv/nfs/wordpress
sudo chmod 755 /srv/nfs/wordpress

# MySQL suele usar UID 1001 en el chart de Bitnami
sudo chown -R 1001:1001 /srv/nfs/mysql
sudo chmod 755 /srv/nfs/mysql
```

Editar `/etc/exports`:

```text
/srv/nfs/wordpress 10.10.10.0/24(rw,sync,no_subtree_check,no_root_squash)
/srv/nfs/mysql     10.10.10.0/24(rw,sync,no_subtree_check,no_root_squash)
```

Aplicar cambios:

```bash
sudo exportfs -rav
sudo systemctl restart nfs-kernel-server
sudo systemctl enable nfs-kernel-server
```

### Verificar desde un nodo del clúster

```bash
ssh arq3d@10.10.10.11
showmount -e IP_DE_TU_RASPBERRY
# Debe mostrar:
# /srv/nfs/wordpress 10.10.10.0/24
# /srv/nfs/mysql     10.10.10.0/24
```

## Paso 1: Instalar el provisionador nfs-client en K3s

Si aún no existe la StorageClass `nfs-client`:

```bash
helm repo add nfs-subdir-external-provisioner \
  https://kubernetes-sigs.github.io/nfs-subdir-external-provisioner/
helm repo update

helm install nfs-client nfs-subdir-external-provisioner/nfs-subdir-external-provisioner \
  --namespace kube-system \
  --set nfs.server=IP_DE_TU_RASPBERRY \
  --set nfs.path=/srv/nfs \
  --set storageClass.name=nfs-client \
  --set storageClass.defaultClass=false
```

Verificar:

```bash
kubectl get storageclass
# nfs-client (default) ...
```

## Paso 2: Habilitar el rol NFS en Ansible

Editar `ansible/group_vars/all.yml`:

```yaml
nfs_enabled: true
nfs_server_ip: "IP_DE_TU_RASPBERRY"
nfs_export_path: "/srv/nfs"
nfs_mount_point: "/mnt/nfs"
nfs_mount_options: "rw,hard,intr,nfsvers=4.1"
```

Editar `ansible/playbooks/02-nfs.yml` para reflejar que ahora es NFS genérico:

```yaml
---
- name: "FASE 2 | Montaje persistente NFS (NAS → K8s nodes)"
  hosts: k8s_cluster
  gather_facts: true
  become: true

  roles:
    - role: nfs
      tags: [nfs, storage]
```

Aplicar a los nodos:

```bash
cd ansible/
ansible-playbook playbooks/02-nfs.yml --vault-password-file ~/.vault_pass
```

Verificar montaje:

```bash
ssh arq3d@10.10.10.11 "mount | grep nfs"
```

## Paso 3: Cambiar el backend de WordPress a NFS

Editar `k8s-cluster/wordpress/wordpress-mysql/values.yaml`:

```yaml
global:
  storageClass: "nfs-client"

# ...

replicaCount: 3   # Ahora sí podemos escalar

# ...

persistence:
  accessMode: ReadWriteMany
```

Editar `k8s-cluster/argocd-apps/02-wordpress-app.yaml`:

```yaml
        - name: "global.storageClass"
          value: "nfs-client"
```

Hacer commit y push:

```bash
git add ansible/group_vars/all.yml

git add ansible/playbooks/02-nfs.yml
git add k8s-cluster/wordpress/wordpress-mysql/values.yaml
git add k8s-cluster/argocd-apps/02-wordpress-app.yaml

git commit -m "feat: migra almacenamiento a NFS en Raspberry Pi NAS"
git push
```

## Paso 4: Migrar datos existentes (opcional pero recomendado)

Si ya tienes contenido en `local-path` y no quieres perderlo:

### 4.1 Escalar WordPress a 0 réplicas

```bash
kubectl scale deployment wordpress-arq3d --replicas=0 -n wp
kubectl scale statefulset wordpress-mysql-subchart --replicas=0 -n wp
```

### 4.2 Localizar los PVs actuales

```bash
kubectl get pvc -n wp
# Anota los nombres de los PVs asociados
kubectl get pv
```

### 4.3 Copiar datos al NAS

En el nodo worker donde residen los PVs:

```bash
# WordPress
sudo rsync -avP /var/lib/rancher/k3s/storage/pvc-<wordpress-pv>/ \
  /mnt/nfs/wordpress/

# MySQL
sudo rsync -avP /var/lib/rancher/k3s/storage/pvc-<mysql-pv>/ \
  /mnt/nfs/mysql/
```

Ajustar permisos finales:

```bash
sudo chown -R 1000:1000 /srv/nfs/wordpress
sudo chown -R 1001:1001 /srv/nfs/mysql
```

### 4.4 Borrar PVCs antiguos para que se recreen en NFS

```bash
kubectl delete pvc -n wp --all
kubectl delete pv <nombre-del-pv-antiguo>
```

> Asegúrate de haber copiado los datos antes de borrar los PVCs.

## Paso 5: Sincronizar con ArgoCD

```bash
kubectl get applications -n argocd
kubectl argocd app sync wordpress-arq3d -n argocd
```

O desde la UI de ArgoCD:

1. Abrir `https://argo.alfonso.local`.
2. Seleccionar la aplicación `wordpress-arq3d`.
3. Pulsar **Sync** y luego **Synchronize**.

## Paso 6: Verificar la migración

```bash
# StorageClass activa
kubectl get storageclass

# PVCs en Bound con nfs-client
kubectl get pvc -n wp

# WordPress escalado
kubectl get deployment wordpress-arq3d -n wp

# Pods repartidos
kubectl get pods -n wp -o wide

# Comprobar contenido web
open https://alfonso.local
```

## Paso 7: Escalar WordPress a 2-3 réplicas

```bash
kubectl scale deployment wordpress-arq3d --replicas=3 -n wp
```

Verificar que los pods se reparten entre workers:

```bash
kubectl get pods -n wp -o wide
```

## Troubleshooting

### Los pods quedan en `Pending`

```bash
kubectl describe pvc -n wp
kubectl describe pod -n wp <nombre-del-pod>
```

Causa habitual: el provisionador NFS no puede escribir en `/srv/nfs`. Revisa
permisos y `no_root_squash` en `/etc/exports`.

### WordPress muestra 500 o contenido vacío

- Revisa permisos: `chown -R 1000:1000 /srv/nfs/wordpress`.
- Verifica que `wp-config.php` existe en `/srv/nfs/wordpress`.
- Revisa logs: `kubectl logs -n wp deployment/wordpress-arq3d`.

### MySQL no arranca

- Asegúrate de que `/srv/nfs/mysql` tiene UID 1001.
- Si migraste datos, verifica que no haya archivos de lock de InnoDB
  (`ib_logfile*`, `#innodb_temp`).

## Rollback a local-path

Si algo falla, vuelve a `local-path` rápidamente:

```bash
# Desde Git, revertir el commit de migración
git revert <hash-del-commit-de-migracion>
git push

# Sincronizar ArgoCD
kubectl argocd app sync wordpress-arq3d -n argocd
```

También desactiva el rol NFS:

```yaml
nfs_enabled: false
```

Y reaplica Ansible:

```bash
ansible-playbook site.yml --skip-tags nfs --vault-password-file ~/.vault_pass
```

## Referencias

- [`local-deployment.md`](local-deployment.md): despliegue inicial sin NAS.
- [`docs/decisions/storage-backend.md`](../decisions/storage-backend.md):
  análisis de backends de almacenamiento.
- [`ansible/roles/nfs/main.yml`](../../ansible/roles/nfs/main.yml): rol NFS.
