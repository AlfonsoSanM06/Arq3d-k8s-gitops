# Reglas Comunes Del Agente

## Principios

- Priorizar soluciones simples, mantenibles, observables, seguras y
  reversibles.
- Distinguir hechos confirmados, supuestos, riesgos e inferencias.
- No inventar resultados de comandos, métricas, versiones ni estado de
  sistemas.
- Revisar primero el estado del repositorio y conservar cambios ajenos.
- Aplicar el cambio mínimo que resuelva la petición.

## Clasificación De Tareas

Clasificar la tarea antes de actuar:

- **Solo lectura:** inspección, diagnóstico o recomendación; no modifica
  sistemas externos.
- **Cambio versionado:** edición de código, configuración o documentación.
- **Cambio operativo:** modifica un equipo, servicio, cuenta, red o datos.
- **Producción:** cualquier cambio sobre un entorno que atiende usuarios.

No ejecutar cambios operativos ni despliegues cuando el usuario solo haya
pedido diagnóstico, revisión o recomendaciones.

## Puerta De Producción

Antes de modificar producción se debe confirmar:

1. alcance exacto, host y entorno;
2. autorización explícita;
3. backup reciente y restaurable, cuando haya datos afectados;
4. prueba previa y validación de configuración;
5. procedimiento de rollback proporcional;
6. verificación posterior y forma de observar el servicio.

Si falta una condición crítica, detener el cambio y explicar el bloqueo.

## Seguridad

- No leer, mostrar, confirmar ni versionar secretos reales.
- No imprimir `.env`, claves privadas, tokens ni variables sensibles.
- No pasar secretos innecesariamente en argumentos de comandos.
- No usar datos de producción en pruebas.
- Aplicar mínimo privilegio a usuarios, runners, tokens y servicios.
- Tratar el acceso a un socket de container runtime como acceso administrativo
  al host.

## Cambios Y Comandos

- Identificar los comandos de solo lectura y los que modifican estado.
- Evitar comandos destructivos por defecto.
- Validar entradas y hacer las automatizaciones idempotentes.
- No sobrescribir una configuración activa sin conservar el estado anterior.
- No hacer rollback de una aplicación con migraciones de datos sin comprobar
  compatibilidad del esquema.

## Evidencia Y Entrega

La respuesta final debe indicar:

- diagnóstico y conclusión;
- archivos o recursos afectados;
- validaciones ejecutadas y su resultado;
- riesgos pendientes y supuestos;
- rollback disponible;
- estado que no pudo verificarse.
