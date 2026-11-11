# Método Compartido De Incidencias

Consultar este documento antes de investigar un incidente. Registrar nuevos
errores solo cuando la causa y la solución estén confirmadas.

## Método

1. Conservar el primer error exacto, la hora y el componente afectado.
2. Identificar commit, versión, entorno, host y responsable del cambio.
3. Revisar el último paso correcto y los cambios recientes.
4. Ejecutar primero comprobaciones de solo lectura.
5. Formular hipótesis y comprobarlas con evidencia.
6. Aplicar la corrección de menor alcance.
7. Validar efectos secundarios y documentar el resultado.

## Categorías Que Deben Cubrirse

- configuración inválida o variable ausente;
- permisos y ownership;
- capacidad, disco y límites de recursos;
- red, DNS, firewall y certificados;
- dependencias no saludables;
- runner o automatización no disponible;
- pérdida o corrupción de datos;
- backup y restauración;
- despliegue parcial o rollback incompatible.

## Reglas De Seguridad

- No pedir ni copiar secretos para diagnosticar.
- Redactar tokens, contraseñas, claves privadas y datos personales.
- No borrar datos para intentar reparar un healthcheck.
- No convertir una mitigación temporal en solución permanente sin documentarlo.
