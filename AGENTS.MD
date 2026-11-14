# Guía Base Del Agente Para Proyectos Técnicos

Este archivo es una plantilla común para proyectos de infraestructura,
automatización, aplicaciones, datos y documentación. El proyecto puede añadir
reglas específicas, pero no puede relajar estas reglas de seguridad,
trazabilidad, validación ni documentación.

## Objetivo

Entregar cambios simples, seguros, reproducibles y comprensibles. Un cambio no
está completo solo porque funcione: debe quedar documentado de forma que una
persona pueda entender qué hace, repetirlo, validarlo y revertirlo.

## Orden De Lectura

Antes de modificar archivos:

1. Leer este `AGENTS.md`.
2. Si existe, leer `docs-shared/README.md` y después
   `docs-shared/agent-rules.md`.
3. Leer `docs/README.md`, `docs/context.md` y `docs/architecture.md` cuando
   existan.
4. Leer el runbook, decisión, incidencia o estándar de `docs/` relacionado con
   la tarea.
5. Ejecutar `git status --short` y conservar cambios ajenos.

No inventar documentación que no pueda verificarse. Si faltan documentos
necesarios para un cambio, crearlos a partir de las plantillas de
`docs-shared/templates/` y señalar qué datos continúan pendientes de validar.

## Clasificar La Tarea

Clasificar la tarea antes de actuar:

- **Solo lectura:** revisión, diagnóstico, explicación o recomendación.
- **Cambio versionado:** código, configuración, infraestructura como código o
  documentación dentro del repositorio.
- **Cambio operativo:** altera un servidor, servicio, cuenta, red, datos o
  recurso externo.
- **Producción:** afecta a usuarios, datos reales o servicios en uso.

Una petición de revisión, diagnóstico o recomendación no autoriza cambios
operativos, despliegues ni escrituras en sistemas externos.

## Documentación Como Parte Del Cambio

Actualizar `docs/` dentro del mismo cambio cuando se modifique cualquiera de
estos aspectos:

- propósito, componentes, dependencias o límites de confianza;
- infraestructura, red, DNS, permisos, identidades, secretos o backups;
- despliegue, configuración, CI/CD, observabilidad o recuperación;
- interfaz, operación o forma de reproducir un componente;
- decisión técnica, riesgo aceptado o procedimiento de rollback;
- error confirmado, causa raíz, corrección o medida preventiva.

Usar esta guía para decidir qué documento actualizar:

| Si cambia… | Actualizar… |
| --- | --- |
| estado conocido, componentes, dependencias o entornos | `docs/context.md` |
| componentes, flujos, límites de confianza o recuperación | `docs/architecture.md` y su diagrama |
| una elección relevante y sus alternativas | `docs/decisions/` |
| un procedimiento repetible de operación, despliegue o recuperación | `docs/runbooks/` |
| una incidencia con causa y solución confirmadas | `docs/incidents/` o `docs/errors/` |
| conceptos, comandos o razonamiento que el responsable debe aprender | `docs/learning/` y, si procede, un runbook |

Si el cambio no altera documentación, indicarlo expresamente en la entrega con
el motivo. No duplicar bloques de configuración o código que ya están en el
repositorio: enlazar el archivo fuente y explicar su intención.

## Documentar Para Aprender

Cuando el usuario pida documentar, explicar una implementación o dejar un
proceso preparado para reutilizarlo, crear o actualizar un documento de
aprendizaje y un runbook cuando exista una secuencia operativa reproducible.

Un runbook debe incluir, en proporción al riesgo:

1. objetivo y cuándo usarlo;
2. prerrequisitos, permisos y datos que no se deben exponer;
3. modelo mental: qué componente hace qué y por qué;
4. pasos ordenados, separando comandos de lectura de comandos que modifican
   estado;
5. resultado esperado y validación;
6. riesgos, puntos para detenerse y rollback;
7. enlaces al código, configuración y documentos relacionados.

La documentación de aprendizaje debe explicar decisiones y efectos, no solo
enumerar comandos para copiar y pegar. Mantener un archivo por tema o
procedimiento; no crear un único documento acumulativo e inmanejable.

## Incidencias Y Errores

Registrar un error como conocimiento reutilizable solo cuando la causa y la
solución estén confirmadas. Cada incidencia debe conservar:

- síntoma y alcance, sin secretos ni datos personales;
- entorno, versión o commit y fecha de verificación;
- evidencia relevante y causa raíz confirmada;
- corrección aplicada, validación y prevención;
- enlace al cambio o runbook relacionado.

No convertir hipótesis, logs completos o mitigaciones temporales en hechos.
La guía general de investigación permanece en
`docs-shared/errors/errors-common.md`; las incidencias específicas pertenecen
al proyecto.

## Seguridad Y Cambios Operativos

- No leer, mostrar ni versionar claves privadas, tokens, contraseñas, `.env`,
  states sensibles, certificados privados ni datos de producción.
- Aplicar mínimo privilegio y no incluir secretos en comandos, ejemplos o
  documentación.
- Preferir automatizaciones idempotentes, parametrizadas y trazables.
- Identificar los comandos de solo lectura y los que modifican estado.
- Evitar acciones destructivas por defecto y conservar el estado anterior.

Antes de modificar producción, confirmar alcance, autorización explícita,
backup recuperable cuando aplique, prueba previa, rollback, validación y forma
de observar el resultado. Aplicar la skill `devops-senior` para decisiones de
infraestructura, operaciones, seguridad, CI/CD y producción.

## Diagramas Y Trazabilidad

Cuando haya tres o más componentes, dependencias no evidentes o un flujo
operativo relevante, actualizar un diagrama en `docs/diagrams/`. Preferir
Mermaid como fuente versionable y añadir una versión Excalidraw solo cuando
aporta claridad visual. El diagrama debe reflejar únicamente relaciones
verificadas y enlaces a la documentación detallada.

## Entrega Y Validación

Al finalizar, informar de:

- cambio realizado y archivos afectados;
- documentación creada o actualizada;
- validaciones ejecutadas y resultado;
- supuestos, riesgos o estado no verificable;
- rollback disponible o motivo por el que no aplica.

Nunca declarar un despliegue, una corrección o el estado de infraestructura
como correcto sin evidencia verificable.
