# Plan de Despliegue Local de ARQ3D (sin NAS)

Este runbook describe cómo desplegar el proyecto ARQ3D en un entorno local
usando Proxmox virtualizado con QEMU/KVM, **sin necesidad de un NAS externo**.
En lugar de NFS/SMB se utiliza `local-path` de K3s para los volúmenes
persistentes.

> **Flujo resumido:**
> 1. `make proxmox-network` → crea la red (una sola vez).
> 2. `make proxmox-install` → instala Proxmox en el disco QCOW2 (una sola vez).
> 3. `make proxmox-post-install` → configura Proxmox y la plantilla cloud-init
>    (una sola vez).
> 4. `make proxmox-run` → arranca Proxmox las siguientes veces.
>
> El disco QCOW2 conserva la instalación, por lo que **no es necesario volver a
> instalar**; basta con `make proxmox-run` después del primer despliegue.

## Requisitos previos

### Hardware del host

| Recurso | Mínimo recomendado |
|---|---|
| CPU | 4 núcleos con virtualización (VT-x/AMD-V) |
| RAM | 16 GiB (Proxmox 2-4 GiB + 3 VMs × 2-4 GiB) |
| Disco | 60 GiB libres para el disco QCOW2 de Proxmox |
| Red | Conexión a Internet para descargar imágenes y paquetes |

### Software en el host

- `qemu-system-x86_64`
- `qemu-img`
- `bridge-utils` o `iproute2`
- `terraform` ≥ 1.11.0
- `ansible` ≥ 2.15
- `kubectl` ≥ 1.28
- `helm` ≥ 3.12
- `kubeseal` ≥ 0.24
- Par de claves SSH ED25519 (`~/.ssh/id_ed25519.pub`)

## Arquitectura del despliegue local

```text
Host Linux
├── Proxmox VE (VM QEMU)
│   ├── VM 9000: ubuntu-2204-cloud-init (plantilla)
│   ├── VM 110: k8s-master-01   (10.10.10.11)
│   ├── VM 111: k8s-worker-01   (10.10.10.12)
│   ├── VM 112: k8s-worker-02   (10.10.10.13)
│   └── VM 120: ldap-server     (10.10.10.20)
└── Red local 10.10.10.0/24 (bridge + TAP)
```

## Paso 0 y 1: Preparar red y levantar Proxmox VE en QEMU

El proyecto incluye un script automatizado en `scripts/proxmox-vm.sh` y un
`Makefile` para simplificar estas tareas.

### Opción A: usar el script directamente

```bash
# 1. Crear red (bridge + TAP + NAT)
sudo ./scripts/proxmox-vm.sh network

# 2. Instalar Proxmox desde ISO (crea disco y arranca QEMU)
#    La ISO debe estar en ~/proxmox-tfg/ (fuera del repositorio Git).
sudo ./scripts/proxmox-vm.sh install

# 3. Tras la instalación, arrancar Proxmox ya instalado
sudo ./scripts/proxmox-vm.sh run
```

> **Importante:** la ISO de Proxmox nunca debe guardarse dentro del
> repositorio. El script la busca en `~/proxmox-tfg/`. El `.gitignore` ya
> ignora cualquier fichero `.iso` y el directorio `proxmox-tfg/` por si
> acaso.

### Opción B: usar Make

```bash
make proxmox-check     # verifica ISO y entorno sin arrancar QEMU
make proxmox-network   # crea bridge/TAP y NAT
make proxmox-install   # instala Proxmox desde ISO
make proxmox-run       # arranca Proxmox instalado
make proxmox-status    # ver estado
make proxmox-destroy   # elimina todo (¡cuidado!)
```

### Variables configurables

Puedes sobreescribir variables mediante entorno:

```bash
sudo PROXMOX_IP=10.10.10.2 \
     BRIDGE_NAME=br-arq3d \
     TAP_NAME=tap0 \
     RAM_MB=4096 \
     DISK_SIZE=80G \
     ./scripts/proxmox-vm.sh install
```

### Opción manual (si prefieres no usar el script)

```bash
# Crear bridge
sudo ip link add name br-arq3d type bridge
sudo ip addr add 10.10.10.1/24 dev br-arq3d
sudo ip link set dev br-arq3d up

# Crear TAP
sudo ip tuntap add dev tap0 mode tap user "$USER"
sudo ip link set tap0 master br-arq3d
sudo ip link set dev tap0 up

# NAT
sudo sysctl -w net.ipv4.ip_forward=1
sudo iptables -t nat -A POSTROUTING -o "$(ip route | awk '/default/ {print $5}' | head -1)" -j MASQUERADE

# Disco
qemu-img create -f qcow2 ~/proxmox-tfg/hdd_produccion.qcow2 80G

# Instalar desde ISO
sudo qemu-system-x86_64 \
  -m 4G -smp 4 -enable-kvm -cpu host \
  -name 'Proxmox-TFG' \
  -hda ~/proxmox-tfg/hdd_produccion.qcow2 \
  -cdrom ~/proxmox-tfg/proxmox-ve_*.iso \
  -netdev tap,id=net0,ifname=tap0,script=no,downscript=no \
  -device virtio-net-pci,netdev=net0

# Arrancar instalado
sudo qemu-system-x86_64 \
  -m 4G -smp 4 -enable-kvm -cpu host \
  -name 'Proxmox-TFG' \
  -hda ~/proxmox-tfg/hdd_produccion.qcow2 \
  -netdev tap,id=net0,ifname=tap0,script=no,downscript=no \
  -device virtio-net-pci,netdev=net0
```

### Valores del instalador gráfico de Proxmox

Durante la instalación desde ISO introduce:

| Campo | Valor |
|---|---|
| Management interface | `nic0` |
| Hostname (FQDN) | `pve-arq3d.proxmox.com` |
| IP Address | `10.10.10.2` |
| Netmask | `255.255.255.0` |
| Gateway | `10.10.10.1` |
| DNS Server | `8.8.8.8` |
| Password | La que elijas |
| Email | `admin@alfonso.local` |

## Paso 2: Configurar Proxmox tras la instalación

Una vez Proxmox esté instalado y arrancado, ejecuta el script de
post-instalación. Este script configura la red estática, el hostname, crea el
usuario/token API para Terraform y genera la plantilla cloud-init
automáticamente.

```bash
make proxmox-post-install
```

O directamente:

```bash
./scripts/proxmox-post-install.sh
```

El script te pedirá la contraseña de root de Proxmox la primera vez que se
conecte por SSH. **Guarda el secreto del token API** que se muestra, porque no
se volverá a mostrar.

> Nota: si quieres cambiar IP u otros valores, puedes usar variables de entorno:
> ```bash
> PROXMOX_IP=10.10.10.2 PROXMOX_FQDN=pve-arq3d.proxmox.com \
>   ./scripts/proxmox-post-install.sh
> ```

## Paso 3: Verificar acceso a Proxmox y la plantilla

Desde el host Linux:

```bash
# Verificar conectividad
ping -c 3 10.10.10.2

# Acceder a la interfaz web
curl -sk https://10.10.10.2:8006/api2/json/version
```

Abrir en navegador: `https://10.10.10.2:8006`

Usuario: `root`  
Contraseña: la configurada durante la instalación.

Verificar que existe la plantilla `9000 (ubuntu-2204-cloud-init)` en el árbol
de Proxmox.

## Paso 4: Configurar variables locales de Terraform

```bash
cd terraform-proxmox/
cp terraform.tfvars.example terraform.tfvars
```

Editar `terraform.tfvars`:

```hcl
proxmox_api_url          = "https://10.10.10.2:8006/"
proxmox_api_token_id     = "terraform@pam!tfg-token"
proxmox_api_token_secret = "SECRET_MOSTRADO_POR_PROXMOX"
proxmox_node             = "pve-arq3d"
proxmox_tls_insecure     = true

vm_template_id  = 9000
vm_storage_pool = "local-lvm"

network_bridge      = "vmbr0"
network_vlan_tag    = 0
network_gateway     = "10.10.10.1"
network_dns_servers = "8.8.8.8"
network_cidr_prefix = 24

ci_default_user   = "arq3d"
ci_ssh_public_key = "ssh-ed25519 AAAA... tu-clave"

master_ram_mb  = 2048
worker01_ram_mb = 4096
worker02_ram_mb = 4096
ldap_ram_mb    = 2048
```

## Paso 5: Desplegar VMs con Terraform

```bash
terraform init
terraform plan
terraform apply
```

Verificar:

```bash
terraform output
```

## Paso 6: Preparar Ansible Vault

```bash
cd ../ansible/

# Crear vault.yml con placeholders reales
ansible-vault create group_vars/vault.yml
```

Contenido mínimo:

```yaml
---
vault_k3s_token: "token_aleatorio_de_50_caracteres"
vault_arq3d_password_hash: "HASH_SHA512_DEL_USUARIO_ARQ3D"
ldap_admin_password: "password_admin_ldap"
ldap_bind_password: "password_bind_ldap"
```

Crear fichero de contraseña del vault:

```bash
echo "tu-password-vault" > ~/.vault_pass
chmod 600 ~/.vault_pass
```

## Paso 7: Desplegar configuración con Ansible

> En despliegue local **sin NAS** se omite el rol NFS mediante `--skip-tags nfs`.

```bash
# Verificar conectividad
ansible all -m ping --vault-password-file ~/.vault_pass

# Ejecutar playbooks omitiendo NFS
ansible-playbook site.yml --skip-tags nfs --vault-password-file ~/.vault_pass
```

Verificar K3s:

```bash
ssh arq3d@10.10.10.11 "kubectl get nodes"
```

## Paso 8: Instalar controladores base en K3s

```bash
cd ../k8s-cluster/k8s_argocd/argocd_terraform/

scp arq3d@10.10.10.11:/etc/rancher/k3s/k3s.yaml ~/.kube/config-arq3d
export KUBECONFIG=~/.kube/config-arq3d

terraform init
terraform apply
```

Verificar:

```bash
kubectl get pods -n argocd
kubectl get pods -n ingress-nginx
kubectl get pods -n kube-system | grep sealed
```

## Paso 9: Generar SealedSecret de MySQL

```bash
cd ../../../

kubectl create secret generic wordpress-mysql-secrets \
  --from-literal=password='PASSWORD_MYSQL_REAL' \
  --from-literal=root-password='ROOT_PASSWORD_MYSQL_REAL' \
  --namespace wp --dry-run=client -o yaml |
kubeseal --format yaml > k8s-cluster/argocd-apps/03-sealed-secret.yaml
```

Verificar que el fichero contiene datos cifrados, no contraseñas en claro.

## Paso 10: Crear certificados TLS locales

Para laboratorio local, generar una CA propia:

```bash
mkdir -p /tmp/tls-arq3d && cd /tmp/tls-arq3d

# CA
openssl genrsa -out ca.key 2048
openssl req -x509 -new -nodes -key ca.key -sha256 -days 365 -out ca.crt \
  -subj "/CN=arq3d-ca"

# Certificado WordPress
openssl genrsa -out wordpress.key 2048
openssl req -new -key wordpress.key -out wordpress.csr \
  -subj "/CN=alfonso.local"
openssl x509 -req -in wordpress.csr -CA ca.crt -CAkey ca.key \
  -CAcreateserial -out wordpress.crt -days 365 -sha256

# Certificado ArgoCD
openssl genrsa -out argocd.key 2048
openssl req -new -key argocd.key -out argocd.csr \
  -subj "/CN=argo.alfonso.local"
openssl x509 -req -in argocd.csr -CA ca.crt -CAkey ca.key \
  -CAcreateserial -out argocd.crt -days 365 -sha256

# Crear secretos en Kubernetes
kubectl create secret tls wordpress-tls \
  --cert=wordpress.crt --key=wordpress.key -n wp

kubectl create secret tls argocd-server-tls \
  --cert=argocd.crt --key=argocd.key -n argocd
```

## Paso 11: Registrar root-app en ArgoCD

```bash
kubectl apply -f k8s-cluster/argocd-apps/01-root-app.yaml
```

Subir el SealedSecret a Git:

```bash
git add k8s-cluster/argocd-apps/03-sealed-secret.yaml
git commit -m "feat: bootstrap sealed mysql secret"
git push
```

## Paso 12: Verificar despliegue

```bash
# Aplicaciones en ArgoCD
kubectl get applications -n argocd

# Pods de WordPress
kubectl get pods -n wp

# Ingress
kubectl get ingress -n wp

# PVCs (deben estar Bound con local-path)
kubectl get pvc -n wp
```

Añadir DNS local:

```bash
echo "10.10.10.12 alfonso.local" | sudo tee -a /etc/hosts
echo "10.10.10.12 argo.alfonso.local" | sudo tee -a /etc/hosts
```

Acceder:

- WordPress: `https://alfonso.local`
- ArgoCD: `https://argo.alfonso.local`

## Consideraciones sin NAS

- K3s incluye `local-path` como StorageClass por defecto.
- WordPress se despliega con **1 réplica** porque `local-path` solo soporta
  `ReadWriteOnce`.
- Los datos se almacenan en el disco del nodo worker donde se programa el pod.
- Este modo es válido para laboratorio y demostración, pero no es alta
  disponibilidad real.
- Para producción o portfolio avanzado, migrar a NFS/SMB externo.

## Rollback rápido

```bash
# Destruir aplicaciones
kubectl delete -f k8s-cluster/argocd-apps/01-root-app.yaml

# Destruir controladores
cd k8s-cluster/k8s_argocd/argocd_terraform/
terraform destroy

# Destruir VMs
cd ../../../terraform-proxmox/
terraform destroy
```

## Troubleshooting común

### Las VMs no obtienen IP

- Verificar que `qm guest agent` está habilitado en la plantilla.
- Comprobar que el bridge `vmbr0` de Proxmox tiene acceso a la red.
- Revisar logs de Cloud-Init: `cat /var/log/cloud-init.log`.

### Ansible no conecta por SSH

```bash
ssh-keyscan 10.10.10.11 >> ~/.ssh/known_hosts
ssh-keyscan 10.10.10.12 >> ~/.ssh/known_hosts
ssh-keyscan 10.10.10.13 >> ~/.ssh/known_hosts
ssh-keyscan 10.10.10.20 >> ~/.ssh/known_hosts
```

### Los PVCs quedan Pending

```bash
kubectl get storageclass
kubectl describe pvc -n wp
```

Si no existe `local-path`, instalarlo manualmente:

```bash
kubectl apply -f https://raw.githubusercontent.com/rancher/local-path-provisioner/v0.0.26/deploy/local-path-storage.yaml
```

### ArgoCD no sincroniza

```bash
kubectl logs -n argocd deployment/argocd-server
kubectl describe application wordpress-arq3d -n argocd
```

## Enlaces

- [`README.md`](../../README.md)
- [`docs/runbooks/bootstrap.md`](bootstrap.md)
- [`docs/decisions/storage-backend.md`](../decisions/storage-backend.md)
- [`docs/runbooks/migrate-to-nas.md`](migrate-to-nas.md)
