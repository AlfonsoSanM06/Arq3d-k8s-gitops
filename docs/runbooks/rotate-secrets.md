# Runbook: Rotación de secretos

## Objetivo

Cambiar de forma segura credenciales sensibles sin dejar rastros en Git ni
perder el control de la infraestructura.

## Secretos gestionados

| Secreto | Ubicación | Herramienta |
|---|---|---|
| API token de Proxmox | Local | `terraform.tfvars` |
| Contraseñas Ansible | Repositorio cifrado | `group_vars/vault.yml` |
| Contraseñas MySQL | Repositorio cifrado | `03-sealed-secret.yaml` |
| kubeconfig | Local | `~/.kube/config-arq3d` |
| Clave de recuperación Sealed Secrets | Backup seguro | `sealed-secrets-key*.yaml` |

## Rotar API token de Proxmox

1. Crear nuevo token en Proxmox.
2. Actualizar `terraform.tfvars`.
3. Ejecutar `terraform plan`; no debería haber cambios de infraestructura.
4. Revocar token antiguo.

## Rotar contraseñas de MySQL

1. Generar nuevas contraseñas seguras.
2. Crear un nuevo Secret temporal en Kubernetes:

```bash
kubectl create secret generic wordpress-mysql-secrets-new \
  --from-literal=password='NUEVA_PASSWORD' \
  --from-literal=root-password='NUEVA_ROOT_PASSWORD' \
  --namespace wp --dry-run=client -o yaml |
kubeseal --format yaml > k8s-cluster/argocd-apps/03-sealed-secret.yaml
```

3. Commitear y push. ArgoCD sincronizará el nuevo SealedSecret.
4. Los pods de MySQL y WordPress se reiniciarán.
5. Verificar conectividad.

## Rotar clave de Sealed Secrets

⚠️ Operación destructiva si no se respalda.

1. Exportar clave actual:

```bash
kubectl get secret -n kube-system sealed-secrets-key -o yaml > sealed-secrets-key-backup.yaml
```

2. Guardar en almacén seguro fuera del repositorio.
3. Eliminar y regenerar la clave del controlador.
4. Volver a sellar todos los SealedSecrets.

## Rotar contraseñas de Ansible Vault

```bash
ansible-vault rekey group_vars/vault.yml
```

## Validación

- `terraform validate`
- `ansible-playbook --syntax-check site.yml`
- `helm template` del chart WordPress
- `kubectl get sealedsecret -n wp`
- `kubectl get secret wordpress-mysql-secrets -n wp`

## Prevención

- No versionar `terraform.tfvars`, `.vault_pass`, kubeconfigs ni claves.
- Usar un gestor de contraseñas para los secretos locales.
- Programar rotación periódica anual como mínimo.
