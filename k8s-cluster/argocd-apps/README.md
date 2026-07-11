# argocd-apps — GitOps Applications (ARQ3D Systems)

Este directorio contiene los manifiestos de ArgoCD que implementan el **patrón App-of-Apps**.
ArgoCD monitoriza esta carpeta. Cualquier fichero `.yaml` añadido aquí se convierte
automáticamente en un recurso gestionado del clúster.

## Estructura

```
argocd-apps/
├── 00-appproject.yaml      # Permisos y límites del proyecto (mínimo privilegio)
├── 01-root-app.yaml        # App raíz: gestiona este propio directorio
├── 02-wordpress-app.yaml   # Application: WordPress + MySQL via Helm
└── 03-sealed-secret.yaml   # SealedSecret: credenciales MySQL (cifrado, seguro en Git)
```

## Flujo de despliegue

```
Developer (git push) → GitHub → ArgoCD Poll/Webhook
                                      │
                              root-app detecta cambios
                                      │
                    ┌─────────────────┴─────────────────┐
                    ▼                                   ▼
          wordpress-arq3d                      (futuro) nextcloud-arq3d
          Helm Chart → namespace wp            Helm Chart → namespace nextcloud
          WordPress + MySQL                    Nextcloud + PostgreSQL
          PVC → NFS TrueNAS                   PVC → NFS TrueNAS
```

## Cómo añadir una nueva aplicación

1. Crea un fichero `NN-nombre-app.yaml` con el CRD `Application` de ArgoCD.
2. Haz `git push` a la rama `main`.
3. ArgoCD detecta el cambio en ≤ 3 minutos y despliega la app automáticamente.
4. **No ejecutes `kubectl apply` manualmente** — ArgoCD es la única fuente de verdad.

## Prerequisitos de despliegue

Antes de aplicar estos manifiestos, el Terraform de `k8s_argocd/argocd_terraform/`
debe haber desplegado:

| Componente | Namespace | Función |
|---|---|---|
| ArgoCD `7.x` | `argocd` | Gestor GitOps |
| Ingress NGINX `4.10.x` | `ingress-nginx` | Terminador HTTP/Ingress |
| Sealed Secrets `2.16.x` | `kube-system` | Descifrado de SealedSecrets |

## Bootstrapping

```bash
# 1. Desplegar la infraestructura base (ArgoCD + NGINX + SealedSecrets)
cd k8s-cluster/k8s_argocd/argocd_terraform/
terraform init && terraform apply

# 2. Sellar el secret de MySQL con la clave del clúster
kubectl create secret generic wordpress-mysql-secrets \
  --from-literal=password='<PASSWORD>' \
  --from-literal=root-password='<ROOT_PASSWORD>' \
  --namespace wp --dry-run=client -o yaml | \
  kubeseal --format yaml > argocd-apps/03-sealed-secret.yaml

# 3. Registrar la root-app en ArgoCD (solo la primera vez)
kubectl apply -f argocd-apps/01-root-app.yaml
```

## Acceso a la UI de ArgoCD

```bash
# Añadir entrada DNS local
echo "$(minikube ip)  argo.local" | sudo tee -a /etc/hosts

# Obtener contraseña inicial del admin
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d; echo

# Navegar a http://argo.local
```
