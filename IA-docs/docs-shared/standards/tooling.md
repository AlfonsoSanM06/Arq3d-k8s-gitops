# Estándar Compartido De Herramientas

## Jerarquía

1. Usar una API o herramienta estructurada específica si existe.
2. Para buscar texto y archivos, preferir `rg` y `rg --files`.
3. Para JSON, preferir un parser estructurado o `jq`.
4. Usar herramientas del sistema como fallback.
5. No instalar herramientas ni modificar el equipo sin autorización.

Comprobar solo las herramientas que la tarea vaya a utilizar y reutilizar el
resultado durante la sesión.

## Edición

- Usar edición estructurada o parches revisables.
- No editar mediante redirecciones, sustituciones masivas o comandos
  destructivos si existe una alternativa controlada.
- Revisar el diff después de cada modificación relevante.
- No releer archivos que no hayan cambiado durante la misma sesión.

## Validación

- Validar sintaxis antes de ejecutar cambios.
- Preferir pruebas aisladas y datos ficticios.
- Capturar resultados sin incluir secretos.
- Distinguir una validación local de una comprobación real en producción.
