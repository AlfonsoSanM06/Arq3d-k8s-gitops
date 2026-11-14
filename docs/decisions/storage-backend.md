# Decisión: Backend de almacenamiento para PVCs

## Contexto

Kubernetes necesita un backend de almacenamiento para los PVCs de WordPress,
MySQL, Grafana y Prometheus. El repositorio original asumía un TrueNAS con NFS
en `192.168.20.100`, pero no se había tomado una decisión explícita ni se
había configurado el provisionador dinámico.

El usuario dispone de una Raspberry Pi con Samba compartido, lo que abre la
posibilidad de usar SMB en lugar de NFS.

## Opciones evaluadas

### 1. NFS externo (TrueNAS o similar)

- **Ventajas:** ampliamente usado en entornos Linux/Kubernetes; compatible con
  `ReadWriteMany` para múltiples réplicas de WordPress; existen provisionadores
  maduros como `nfs-subdir-external-provisioner` o el CSI de NFS.
- **Inconvenientes:** requiere un servidor NFS separado; NFS no es
  cifrado por defecto; puede generar problemas de bloqueos de archivo.

### 2. SMB/CIFS externo (Raspberry Pi con Samba)

- **Ventajas:** el usuario ya dispone del recurso; SMB es familiar y soportado
  en redes heterogéneas.
- **Inconvenientes:** Kubernetes requiere el
  [CSI driver para SMB](https://github.com/kubernetes-csi/csi-driver-smb);
  el rendimiento de una Raspberry Pi puede ser insuficiente para bases de
  datos; WordPress puede funcionar, pero MySQL sobre SMB no es recomendable por
  latencia y consistencia.

### 3. Almacenamiento local (`local-path` de K3s)

- **Ventajas:** sin dependencias externas; muy sencillo para laboratorio.
- **Inconvenientes:** los datos quedan atados al nodo; no permite HA real ni
  múltiples réplicas con volumen compartido.

### 4. S3 como almacenamiento principal

- **Ventajas:** ideal para backups y objetos.
- **Inconvenientes:** S3 no es un filesystem POSIX; no es adecuado para
  `/var/lib/mysql` ni `/var/www/html` sin herramientas intermedias. No se
  considera para datos en vivo.

## Decisión

Para un proyecto sólido orientado a producción se recomienda **NFS externo
compartido** como backend principal de PVCs, y **SMB de la Raspberry Pi como
laboratorio o destino secundario de backups/archivos de WordPress**.

Si el objetivo inmediato es aprender el flujo completo sin depender de un NAS
potente, se puede usar **`local-path` de K3s** reduciendo WordPress a una
réplica.

### Escenario recomendado para este proyecto

```text
Datos en vivo (PVCs):
  WordPress /var/www/html  -> NFS/SMB compartido (RWX)
  MySQL /var/lib/mysql     -> NFS preferiblemente, o local-path SSD

Backups:
  MySQL dumps              -> SMB de la Raspberry Pi o S3/MinIO
  WordPress files          -> SMB de la Raspberry Pi o S3/MinIO
  Estado ArgoCD            -> S3/MinIO
```

## Consecuencias

- WordPress puede mantener 3 réplicas si el backend soporta RWX.
- MySQL permanece single-instance; para HA habría que evaluar MySQL Operator,
  Percona XtraDB Cluster o similar.
- Es necesario instalar y configurar el provisionador correspondiente:
  `nfs-subdir-external-provisioner` o `csi-driver-smb`.
- El rendimiento y disponibilidad del almacenamiento determinarán la
  disponibilidad real de las aplicaciones.

## Condiciones para revisar esta decisión

- Se disponga de un NAS NFS dedicado y estable.
- Se decida añadir HA a MySQL.
- Se migre el clúster a cloud y se usen volúmenes gestionados.
- El rendimiento de la Raspberry Pi con SMB sea demasiado limitado.

## Notas de implementación

Para usar Samba en Kubernetes con el CSI driver:

```bash
helm repo add csi-driver-smb https://raw.githubusercontent.com/kubernetes-csi/csi-driver-smb/master/charts
helm install csi-driver-smb csi-driver-smb/csi-driver-smb --namespace kube-system
```

Y crear una StorageClass similar a:

```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: smb-client
provisioner: smb.csi.k8s.io
parameters:
  source: //192.168.20.100/arq3d-data
  csi.storage.k8s.io/provisioner-secret-name: smb-secret
  csi.storage.k8s.io/provisioner-secret-namespace: kube-system
reclaimPolicy: Delete
volumeBindingMode: Immediate
mountOptions:
  - dir_mode=0777
  - file_mode=0777
```

Para NFS con `nfs-subdir-external-provisioner`:

```bash
helm repo add nfs-subdir-external-provisioner https://kubernetes-sigs.github.io/nfs-subdir-external-provisioner
helm install nfs-subdir-external-provisioner nfs-subdir-external-provisioner/nfs-subdir-external-provisioner \
  --set nfs.server=192.168.20.100 \
  --set nfs.path=/mnt/pool/arq3d-data
```

Esto creará la StorageClass `nfs-client` que ya referencian los valores del
chart.
