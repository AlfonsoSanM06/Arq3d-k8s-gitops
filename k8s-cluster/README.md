# k8s-cluster/ — Plataforma Kubernetes y GitOps

Este directorio agrupa todo lo relacionado con el clúster K3s: controladores de plataforma, aplicaciones gestionadas por ArgoCD y el chart de WordPress.

## Estructura

```text
k8s-cluster/
├── k8s_argocd/
│   └── argocd_terraform/       # Controladores base vía Terraform + Helm
│       ├── main.tf             # ArgoCD, NGINX Ingress, Sealed Secrets
│       ├── providers.tf        # Providers Helm/Kubernetes
│       ├── backend.tf          # Backend de estado
│       ├── variables.tf
│       └── values/argocd.yaml  # Valores custom de ArgoCD
│
├── argocd-apps/                # App-of-Apps de ArgoCD
│   ├── 00-appproject.yaml      # Permisos y límites
│   ├── 01-root-app.yaml        # Root Application
│   ├── 02-wordpress-app.yaml   # Aplicación WordPress
│   ├── 03-sealed-secret.yaml   # Credenciales MySQL cifradas
│   └── README.md
│
└── wordpress/
    └── wordpress-mysql/        # Helm chart custom
        ├── Chart.yaml
        ├── values.yaml
        ├── values-secrets.yaml.example
        └── templates/
```

## Controladores base

El directorio [`k8s_argocd/argocd_terraform/`](k8s_argocd/argocd_terraform/) instala los controladores imprescindibles del clúster:

| Controlador | Namespace | Función |
|---|---|---|
| ArgoCD | `argocd` | GitOps y sincronización de aplicaciones. |
| NGINX Ingress | `ingress-nginx` | Terminación HTTP/HTTPS. |
| Sealed Secrets | `kube-system` | Descifra secretos versionados en Git. |

```bash
cd k8s-cluster/k8s_argocd/argocd_terraform/
export KUBECONFIG=~/.kube/config-arq3d
terraform init
terraform plan
terraform apply
```

## Aplicaciones GitOps

ArgoCD monitoriza [`argocd-apps/`](argocd-apps/). Cualquier manifiesto `.yaml` nuevo se convierte automáticamente en un recurso gestionado.

```text
Git push → GitHub Actions (CI, lint) → ArgoCD (CD) → Kubernetes
```

GitHub Actions **no toca el clúster**; solo valida. ArgoCD es el único componente que aplica cambios.

### Bootstrap inicial

```bash
# 1. Sellar el secret de MySQL con la clave pública del clúster
kubectl create secret generic wordpress-mysql-secrets \
  --from-literal=password='CAMBIA_ESTO' \
  --from-literal=root-password='CAMBIA_ESTO_TAMBIEN' \
  --namespace wp --dry-run=client -o yaml | \
  kubeseal --format yaml > k8s-cluster/argocd-apps/03-sealed-secret.yaml

# 2. Subir a Git
git add k8s-cluster/argocd-apps/03-sealed-secret.yaml
git commit -m "feat: bootstrap sealed mysql secret"
git push

# 3. Registrar la root-app (solo la primera vez)
kubectl apply -f k8s-cluster/argocd-apps/01-root-app.yaml
```

> El Secret original y la clave privada de Sealed Secrets **no se versionan**. El `SealedSecret` cifrado sí.

### Añadir una aplicación nueva

1. Crea `k8s-cluster/argocd-apps/NN-nombre-app.yaml` con un CRD `Application`.
2. Haz `git push` a `main`.
3. ArgoCD lo detecta y despliega automáticamente.
4. No uses `kubectl apply` manualmente para aplicaciones gestionadas.

## Chart de WordPress

[`wordpress/wordpress-mysql/`](wordpress/wordpress-mysql/) es un chart Helm custom que despliega:

- WordPress (Deployment + PVC + Ingress).
- MySQL (StatefulSet single-instance como subchart).
- NetworkPolicies y ServiceAccount restringido.
- ServiceMonitor opcional para Prometheus.

Las credenciales de MySQL se inyectan desde el SealedSecret, no desde `values.yaml`.

## Acceso a ArgoCD

```bash
# Obtener contraseña inicial del admin
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d; echo

# Añadir DNS local (usa la IP del worker que expone el Ingress)
echo "10.10.10.12 argo.alfonso.local" | sudo tee -a /etc/hosts
```

URL: `https://argo.alfonso.local`  
Usuario: `admin`

## Verificación rápida

```bash
kubectl get nodes
kubectl get pods -n argocd
kubectl get pods -n ingress-nginx
kubectl get applications -n argocd
kubectl get pods -n wp
```

## Enlaces

- [README principal](../README.md)
- [README de argocd-apps](argocd-apps/README.md)
- [Runbook de bootstrap](../docs/runbooks/bootstrap.md)
- [Runbook de despliegue local](../docs/runbooks/local-deployment.md)
- [Arquitectura del clúster](../docs/architecture.md)
