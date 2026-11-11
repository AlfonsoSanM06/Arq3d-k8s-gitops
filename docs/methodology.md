# Metodología de Trabajo y Flujo CI/CD

## Principios operativos

- **IaC**: toda infraestructura reproducible se define en Terraform o Ansible y se revisa mediante pull request.
- **GitOps**: Git define el estado deseado de las aplicaciones; ArgoCD lo reconcilia en Kubernetes.
- **DevSecOps**: seguridad, calidad y trazabilidad se comprueban durante todo el ciclo, no al final.
- **Entrega incremental**: cambios pequeños, reversibles y observables; cada tarea debe tener criterios de aceptación.
- **Inmutabilidad**: se prefieren cambios declarativos y nuevas versiones frente a modificaciones manuales persistentes.

## Estrategia de ramas

Se adopta **Trunk-Based Development** con `main` como rama protegida:

1. Crea una rama corta desde `main`: `feature/<descripcion>`, `fix/<descripcion>`, `docs/<descripcion>` o `chore/<descripcion>`.
2. Mantén el cambio enfocado y sincroniza la rama con `main` antes de solicitar revisión.
3. Abre un Pull Request con descripción del cambio, riesgo, plan de rollback y evidencias de validación.
4. Requiere al menos una revisión, todos los checks obligatorios en verde y resolución de comentarios.
5. Integra mediante squash merge. Elimina la rama después del merge.
6. Etiqueta versiones o releases de infraestructura cuando el cambio requiera trazabilidad operativa.

No se permiten pushes directos a `main` ni ramas de larga duración. Un hotfix sigue el mismo control, con revisión posterior de la causa raíz.

## Separación CI/CD

### CI: GitHub Actions

Cada Pull Request debe ejecutar, según los archivos afectados:

1. Comprobaciones de formato y sintaxis de Terraform, Ansible, YAML y Helm.
2. `terraform init -backend=false`, `terraform validate` y `terraform plan` sin aplicar cambios.
3. `ansible-lint` y, cuando sea viable, `ansible-playbook --syntax-check` y `--check`.
4. `helm dependency build`, `helm lint` y `helm template` para charts modificados.
5. Validación de manifiestos Kubernetes y políticas de seguridad.
6. Escaneo de secretos, dependencias, IaC e imágenes de contenedor con herramientas aprobadas.
7. Publicación de artefactos de diagnóstico sin credenciales ni datos sensibles.

Un check fallido bloquea el merge. Los jobs deben usar versiones fijadas, permisos mínimos y secretos de GitHub únicamente desde el almacén de secretos.

### CD: ArgoCD y cambios de infraestructura

- Las aplicaciones de `k8s-cluster/argocd-apps/` y los charts se despliegan mediante ArgoCD desde `main`.
- ArgoCD aplica sincronización automática solo a recursos autorizados por el `AppProject`.
- El bootstrap inicial y las acciones de recuperación excepcionales se documentan y se auditan.
- Terraform para Proxmox y los controladores base requiere aprobación humana del `plan` antes de `apply`.
- Ansible se ejecuta desde un entorno controlado, con inventario revisado y `--check` cuando sea posible.
- El estado Terraform usa backend remoto con locking y nunca se versiona en el repositorio.

Flujo resumido:

```text
Issue -> rama corta -> Pull Request -> CI + revisión -> main
                                             |
                         +-------------------+-------------------+
                         |                                       |
                 Terraform/Ansible                     ArgoCD GitOps
                 plan/aprobación                       sync desde Git
```

## Criterios antes de un merge

- El cambio tiene objetivo, alcance, impacto y rollback descritos.
- Los checks aplicables pasan y no hay secretos o estados generados en el diff.
- Terraform tiene un plan revisado; no hay cambios destructivos no explicados.
- Los manifests renderizados son válidos y respetan namespaces, límites, probes, RBAC y NetworkPolicies.
- Las imágenes están versionadas y las vulnerabilidades críticas/altas tienen resolución o excepción aprobada.
- La documentación y los registros de incidencia se actualizan si cambia la operación.
- El autor incluye evidencia de prueba y, si procede, una prueba de humo post-despliegue.

## Seguridad y secretos

- `terraform.tfvars`, estados, kubeconfigs, claves privadas, `.vault_pass` y secretos sin cifrar son siempre locales o gestionados por un almacén seguro.
- Ansible Vault protege variables sensibles de Ansible; Sealed Secrets permite versionar solo el manifiesto cifrado que el clúster puede descifrar.
- Las credenciales usan mínimo privilegio, rotación definida y nombres separados por entorno.
- Si un secreto se expone: revoca, rota, analiza el historial, corrige el origen y registra la incidencia. Borrarlo del último commit no es suficiente.
- Los accesos de CI usan OIDC o tokens de mínimo alcance cuando la plataforma lo soporte.
- No se deshabilitan controles para hacer pasar el pipeline; se corrige la causa o se registra una excepción con caducidad y responsable.

## Operación y cambios urgentes

Toda alerta debe tener responsable, severidad, hora de detección, impacto y canal de comunicación. Para un incidente crítico se prioriza restaurar el servicio con el cambio mínimo seguro, se conserva la evidencia y se crea un post-mortem en `docs/errors/error_log.md` dentro de los cinco días laborables siguientes.
