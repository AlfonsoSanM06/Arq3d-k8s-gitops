# Estándar Compartido De Infraestructura

## Diseño

- Mantener una fuente de verdad versionada para infraestructura y configuración.
- Separar configuración, datos persistentes y secretos.
- Definir límites de confianza, exposición de red y dependencias externas.
- Evitar exponer directamente bases de datos o servicios internos.
- Diseñar los cambios para ser reversibles y seguros ante reejecución.

## Seguridad

- Usar mínimo privilegio para usuarios, servicios, runners y automatizaciones.
- Fijar versiones de imágenes y dependencias; preferir referencias inmutables.
- Aplicar hardening solo después de verificar compatibilidad y recuperación.
- Limitar logs y monitorizar espacio en disco.
- No almacenar secretos en repositorios, imágenes, configuraciones públicas ni
  artefactos de CI.
- Proteger también las claves utilizadas para descifrar datos operativos.

## Red Y TLS

- Documentar puertos internos y externos, DNS, firewall y consumidores.
- Mantener un único punto de entrada cuando exista un proxy inverso.
- Validar identidad y confianza TLS; no usar desactivación de verificación como
  solución permanente.
- Documentar emisión, distribución, renovación y revocación de certificados.

## Persistencia Y Recuperación

Antes de cambios con riesgo:

1. crear un backup consistente;
2. almacenar el backup fuera del sistema protegido;
3. conservar la versión actual de configuración e imágenes;
4. verificar periódicamente la restauración;
5. registrar RPO, RTO, retención y responsable.

Una copia de configuración no es un backup de una base de datos ni sustituye
una prueba de restauración.

## Producción

Antes de desplegar, comprobar capacidad, espacio, permisos, puertos, estado de
dependencias y mecanismo de rollback. Después, verificar healthchecks, una
prueba funcional representativa, logs y métricas.

No eliminar volúmenes, datos o recursos persistentes sin backup y autorización
expresa.
