# Documentación de ARQ3D

Este directorio contiene el conocimiento técnico del proyecto: contexto,
arquitectura, decisiones, procedimientos operativos, aprendizaje y evolución.
La documentación está escrita tanto para humanos como para agentes
automáticos: usa rutas relativas al repositorio, código ejecutable y
placeholders seguros.

## Índice

> Para agentes automáticos: consultar primero [`Agent.md`](../Agent.md) y luego este índice.

| Documento | Propósito |
|---|---|
| [`context.md`](context.md) | Qué es el proyecto, objetivos, entornos, red, dependencias y supuestos. |
| [`architecture.md`](architecture.md) | Componentes, flujos de datos, diagramas y límites de confianza. |
| [`project_structure.md`](project_structure.md) | Árbol de directorios y responsabilidad de cada capa. |
| [`methodology.md`](methodology.md) | Flujo de trabajo, CI/CD, criterios de merge y seguridad. |
| [`evolution.md`](evolution.md) | Hoja de ruta y próximas fases del proyecto. |
| [`decisions/`](decisions/) | Decisiones técnicas relevantes con contexto y consecuencias. |
| [`runbooks/`](runbooks/) | Procedimientos operativos reproducibles. |
| [`learning/`](learning/) | Materiales de aprendizaje por tema. |
| [`errors/error_log.md`](errors/error_log.md) | Registro de incidencias y post-mortems. |

## Cómo usar esta documentación

1. Si llegas al proyecto por primera vez, lee [`context.md`](context.md) y
   [`architecture.md`](architecture.md).
2. Si vas a realizar un cambio, consulta el runbook correspondiente en
   [`runbooks/`](runbooks/) y actualiza la documentación afectada.
3. Si tomas una decisión técnica nueva, añade un archivo en
   [`decisions/`](decisions/).
4. Si detectas un error confirmado, regístralo en
   [`errors/error_log.md`](errors/error_log.md).

## Convenciones

- Las rutas son relativas a la raíz del repositorio.
- Los comandos usan placeholders seguros como `REEMPLAZAR_*`.
- Los secretos nunca se incluyen en la documentación.
- Los diagramas preferentemente usan Mermaid.
- Un dato no verificado se marca como `Pendiente de verificar`.
