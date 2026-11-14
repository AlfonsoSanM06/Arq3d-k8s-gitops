# Decisiones Técnicas

Cada archivo registra una decisión relevante del proyecto con contexto,
opciones evaluadas, consecuencias y condiciones para revisarla.

| Decisión | Estado | Resumen |
|---|---|---|
| [`storage-backend.md`](storage-backend.md) | Propuesta | Backend de PVCs: NFS, SMB, local o S3. |
| [`ci-cd-separation.md`](ci-cd-separation.md) | Aprobada | CI en GitHub Actions, CD en ArgoCD. |

## Convenciones

- Estado: `Borrador`, `Propuesta`, `Aprobada`, `Revisada`, `Obsoleta`.
- Cada decisión incluye fecha, autor y condiciones de revisión.
- Una decisión obsoleta se marca como tal y se enlaza a la que la sustituye.
