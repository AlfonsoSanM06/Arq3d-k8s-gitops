# Runbook De Despliegue

## Precondiciones

- autorización;
- backup;
- commit o release;
- validación de configuración;
- ventana de cambio;
- rollback disponible.

## Procedimiento

1. Registrar el estado actual.
2. Validar la candidata.
3. Conservar el estado anterior.
4. Activar el cambio.
5. Ejecutar healthchecks y prueba funcional.
6. Registrar resultado y artefactos no sensibles.

## Fallos

Indicar cuándo detenerse, qué logs conservar y cómo ejecutar el rollback.
