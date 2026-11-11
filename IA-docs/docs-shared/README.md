# Documentación Compartida

Esta carpeta contiene las políticas y prácticas comunes a los proyectos de la
organización. Está diseñada para copiarse o publicarse en un repositorio
independiente y reutilizarse junto a la documentación específica de cada
proyecto.

## Contenido

- [`agent-rules.md`](agent-rules.md): contrato de comportamiento del agente.
- [`standards/infrastructure.md`](standards/infrastructure.md): principios de
  infraestructura, seguridad y operación.
- [`standards/build-release.md`](standards/build-release.md): prácticas comunes
  de CI/CD, validación y releases.
- [`standards/tooling.md`](standards/tooling.md): selección y uso seguro de
  herramientas.
- [`errors/errors-common.md`](errors/errors-common.md): método general de
  diagnóstico y categorías de incidencias.
- [`templates/`](templates/): plantillas para documentar nuevos proyectos.
- [`../scripts/New-ProjectDocs.ps1`](../scripts/New-ProjectDocs.ps1): crea de
  forma segura la estructura documental completa de un proyecto nuevo.

La plantilla [`templates/project-readme.md`](templates/project-readme.md) crea
el punto de entrada de cada proyecto. Debe adaptarse y eliminar las secciones
que no apliquen, sin conservar marcadores pendientes.

## Uso En Un Proyecto

El proyecto debe mantener una carpeta `docs/` con su contexto, arquitectura,
estándares y runbooks concretos. La documentación específica puede ampliar las
reglas compartidas, pero no debe debilitarlas.

Estructura recomendada:

```text
.
|-- README.md
|-- AGENTS.md
|-- docs/
|   |-- README.md
|   |-- context.md
|   |-- architecture.md
|   |-- decisions/
|   |-- diagrams/
|   |-- incidents/
|   |-- learning/
|   |-- runbooks/
|   `-- deployment.md
`-- docs-shared/
    |-- agent-rules.md
    |-- errors/
    |-- standards/
    `-- templates/
```

Cuando una regla general no aplique, documentar explícitamente la excepción,
su motivo, el riesgo aceptado, el responsable y la fecha de revisión.

## Crear Un Proyecto Nuevo

Desde PowerShell, ejecutar el generador indicando una carpeta nueva o vacía:

```powershell
.\scripts\New-ProjectDocs.ps1 \
  -Destination 'C:\ruta\al\nuevo-proyecto' \
  -ProjectName 'nombre-del-proyecto'
```

El script copia `AGENTS.md`, `docs-shared/` y una estructura inicial de
documentación. No sobrescribe archivos existentes salvo que se use `-Force`
de forma deliberada. Tras crearlo, completar primero `README.md`,
`project.yaml`, `docs/context.md` y `docs/architecture.md` con hechos
verificados.

## Qué No Debe Contener

No incluir en esta carpeta:

- dominios, hosts, puertos o rutas de un proyecto concreto;
- nombres de servicios, imágenes o proveedores específicos;
- credenciales, tokens, certificados privados o valores de `.env`;
- afirmaciones sobre el estado real de un servidor.
