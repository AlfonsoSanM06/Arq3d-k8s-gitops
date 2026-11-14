# Conceptos de almacenamiento en Kubernetes

## ¿Por qué necesitamos volúmenes?

Los contenedores son efímeros. Si un pod se elimina, su filesystem desaparece.
Para aplicaciones como WordPress o MySQL necesitamos almacenamiento que sobreviva
al ciclo de vida del pod.

## PersistentVolumeClaim (PVC)

Un PVC es una petición de almacenamiento que hace una aplicación:

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: wordpress-pvc
spec:
  accessModes:
    - ReadWriteMany
  resources:
    requests:
      storage: 1Gi
  storageClassName: nfs-client
```

Kubernetes busca una StorageClass que pueda satisfacerlo y crea el volumen.

## Access modes

| Modo | Significado | Uso típico |
|---|---|---|
| `ReadWriteOnce` (RWO) | Un solo nodo puede montarlo en lectura/escritura. | Bases de datos single-instance. |
| `ReadWriteMany` (RWX) | Varios nodos pueden montarlo en lectura/escritura. | WordPress con varias réplicas. |
| `ReadOnlyMany` (ROX) | Varios nodos en solo lectura. | Contenido estático compartido. |

## StorageClass

Define el tipo de almacenamiento disponible y el provisionador:

```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: nfs-client
provisioner: k8s-sigs.io/nfs-subdir-external-provisioner
```

## NFS vs SMB vs local vs S3

| Tecnología | Tipo | Ventaja | Desventaja |
|---|---|---|---|
| NFS | Filesystem compartido | Compatible RWX, maduro | Sin cifrado nativo |
| SMB/CIFS | Filesystem compartido | Soporte Windows/redes mixtas | Más complejo en Kubernetes |
| local-path | Disco local del nodo | Sencillo | Sin HA, sin RWX |
| S3 | Object storage | Escalable, ideal backups | No es filesystem POSIX |

## MySQL sobre red compartida

MySQL es exigente con la latencia y la consistencia del filesystem. NFS puede
funcionar para una sola instancia, pero SMB sobre Raspberry Pi no es
recomendable para cargas de base de datos de producción. Para HA de MySQL se
necesitan soluciones específicas como operadores.

## Práctica de comprobación

1. Listar StorageClasses del clúster:

```bash
kubectl get storageclass
```

2. Crear un PVC de prueba y verificar que pasa a `Bound`:

```bash
kubectl apply -f - <<EOF
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: test-pvc
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 100Mi
  storageClassName: nfs-client
EOF

kubectl get pvc test-pvc
```

3. Si queda `Pending`, el provisionador no está instalado o no puede acceder
   al servidor de almacenamiento.

## Errores frecuentes

- Montar manualmente NFS en los nodos no hace que Kubernetes use
  automáticamente ese volumen.
- Usar RWO con varias réplicas de WordPress impide que se programen en nodos
  distintos.
- Confundir S3 (object storage) con un filesystem POSIX para bases de datos.
- No respaldar la clave de Sealed Secrets junto con los backups.
