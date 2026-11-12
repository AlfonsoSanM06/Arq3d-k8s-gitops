# Runbook: Bootstrap completo de ARQ3D

## Objetivo

Desplegar desde cero la infraestructura ARQ3D: VMs, configuración de SO,
plataforma Kubernetes y aplicación WordPress.

## Prerrequisitos

- Proxmox VE accesible con un API token dedicado.
- Plantilla Cloud-Init `ubuntu-2204-cloud-init` disponible.
- Par de claves SSH ED25519.
- Backend S3 para Terraform configurado y credenciales exportadas.
- Almacenamiento externo (NFS/SMB) accesible o decisión de usar `local-path`.
- `terraform`, `ansible`, `kubectl`, `helm` y `kubeseal` instalados.

## Modelo mental

```text
Terraform -> VMs -> Ansible -> K3s -> Terraform/Helm -> ArgoCD -> GitOps
```

Cada capa debe estar saludable antes de continuar con la siguiente.

## Pasos

### 1. Aprovisionar VMs con Terraform

```bash
cd terraform-proxmox/
cp terraform.tfvars.example terraform.tfvars
# Editar terraform.tfvars con URL, token, IPs, clave SSH y plantilla.
terraform init
terraform plan
terraform apply
```

Validación:

```bash
terraform output
```

### 2. Configurar el sistema operativo con Ansible

```bash
cd ../ansible/
# Opcional: verificar conectividad
ansible all -m ping

# Crear/cifrar vault.yml con las contraseñas reales
ansible-vault encrypt group_vars/vault.yml

# Ejecutar todos los playbooks
ansible-playbook site.yml --vault-password-file ~/.vault_pass
```

Validación:

```bash
ssh arq3d@10.10.10.11 "kubectl get nodes"
```

### 3. Copiar kubeconfig local

```bash
scp arq3d@10.10.10.11:/etc/rancher/k3s/k3s.yaml ~/.kube/config-arq3d
export KUBECONFIG=~/.kube/config-arq3d
```

### 4. Instalar controladores base con Terraform

```bash
cd ../k8s-cluster/k8s_argocd/argocd_terraform/
terraform init
terraform plan
terraform apply
```

Validación:

```bash
kubectl get pods -n argocd
kubectl get pods -n ingress-nginx
kubectl get pods -n kube-system | grep sealed
```

### 5. Configurar almacenamiento de PVCs

Según la decisión tomada:

- **NFS:** instalar `nfs-subdir-external-provisioner`.
- **SMB:** instalar `csi-driver-smb` y crear StorageClass.
- **Local:** usar `local-path` de K3s.

Ver [`docs/decisions/storage-backend.md`](../decisions/storage-backend.md).

### 6. Generar SealedSecret de MySQL

```bash
cd ../../../
kubectl create secret generic wordpress-mysql-secrets \
  --from-literal=password='REEMPLAZAR_PASSWORD' \
  --from-literal=root-password='REEMPLAZAR_ROOT_PASSWORD' \
  --namespace wp \
  --dry-run=client -o yaml |
kubeseal --format yaml \
  > k8s-cluster/argocd-apps/03-sealed-secret.yaml
```

Validación:

```bash
git diff k8s-cluster/argocd-apps/03-sealed-secret.yaml
# Debe contener campos cifrados, no passwords en claro.
```

### 7. Crear secretos TLS

Para laboratorio con certificados propios:

```bash
kubectl create secret tls wordpress-tls \
  --cert=wordpress.crt --key=wordpress.key -n wp

kubectl create secret tls argocd-server-tls \
  --cert=argocd.crt --key=argocd.key -n argocd
```

Para producción se recomienda cert-manager.

### 8. Registrar root-app en ArgoCD

```bash
kubectl apply -f k8s-cluster/argocd-apps/01-root-app.yaml
```

Validación:

```bash
kubectl get applications -n argocd
kubectl get pods -n wp
kubectl get ingress -n wp
```

### 9. Configurar DNS local

```bash
echo "10.10.10.12 alfonso.local" | sudo tee -a /etc/hosts
echo "10.10.10.12 argo.alfonso.local" | sudo tee -a /etc/hosts
```

## Resultado esperado

- 4 VMs saludables en Proxmox.
- Clúster K3s con 3 nodos Ready.
- ArgoCD, NGINX Ingress y Sealed Secrets funcionando.
- WordPress accesible en `https://alfonso.local`.
- ArgoCD accesible en `https://argo.alfonso.local`.

## Riesgos y puntos de parada

- Si Terraform falla, revisar conectividad y permisos del API token.
- Si Ansible falla, verificar inventario, grupo y variables.
- Si los PVCs quedan `Pending`, revisar el provisionador de almacenamiento.
- Si ArgoCD muestra `OutOfSync`, revisar logs y permisos del AppProject.

## Rollback

1. Destruir aplicaciones desde ArgoCD o eliminar `root-app`.
2. Destruir controladores con Terraform.
3. Destruir VMs con `terraform destroy`.
4. Los datos en PVCs y backups deben gestionarse por separado.

## Enlaces

- [`README.md`](../../README.md)
- [`docs/architecture.md`](../architecture.md)
- [`docs/decisions/storage-backend.md`](../decisions/storage-backend.md)
