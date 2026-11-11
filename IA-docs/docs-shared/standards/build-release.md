# Estándar Compartido De Build Y Release

## Pipeline

Todo proyecto debe separar, como mínimo:

1. validación estática;
2. pruebas automatizadas;
3. generación o selección de artefactos;
4. despliegue controlado;
5. verificación posterior.

Un cambio no debe llegar a producción si falla una fase previa.

## Reproducibilidad

- Fijar acciones, imágenes y dependencias a versiones revisadas; preferir
  referencias inmutables.
- Registrar commit, versión de artefactos, configuración no sensible y
  resultado del despliegue.
- No usar `latest` ni artefactos construidos desde cambios no revisados.
- Separar los datos ficticios de los secretos de producción.

## CI/CD Y Runners

- Usar `permissions` mínimos.
- Proteger la rama de producción y utilizar entornos con aprobaciones cuando
  corresponda.
- Si se usa GitHub Actions, fijar las acciones externas a SHA revisados.
- Seleccionar runners self-hosted mediante etiquetas específicas y grupos
  controlados.
- No ejecutar código de pull requests no confiables con secretos o privilegios
  de producción.
- Añadir límites de tiempo y concurrencia para evitar despliegues solapados.

## Despliegue

Antes de activar una release:

- validar la configuración candidata;
- comprobar que el artefacto corresponde al commit esperado;
- conservar el estado anterior;
- confirmar backup cuando haya datos afectados;
- adquirir un bloqueo operativo en el destino si es necesario.

El rollback debe estar documentado y debe distinguir cambios de configuración,
versiones de aplicación y migraciones de base de datos.

## Secretos Y Logs

- Inyectar secretos solo en el paso que los necesita.
- No utilizar trazado de shell con secretos.
- No imprimir archivos de entorno ni configuraciones renderizadas con valores
  sensibles.
- Limpiar artefactos temporales incluso si el job falla.
