# Runbook De Rollback

## Alcance

Indicar qué versiones, configuración y datos puede restaurar este procedimiento.

## Precondiciones

- causa del fallo identificada o mitigación aprobada;
- estado actual conservado;
- backup disponible;
- compatibilidad de esquema comprobada.

## Procedimiento

1. Detener cambios concurrentes.
2. Conservar logs y estado del fallo.
3. Restaurar configuración o artefacto compatible.
4. Restaurar datos solo mediante el procedimiento aprobado.
5. Verificar salud y funcionalidad.
6. Registrar resultado y acciones posteriores.
