[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$Destination,

    [Parameter(Mandatory)]
    [ValidatePattern('^[a-z0-9][a-z0-9-]*$')]
    [string]$ProjectName,

    [switch]$Force
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$templateRoot = Split-Path -Parent $PSScriptRoot
$docsTemplateRoot = Join-Path $templateRoot 'docs-shared\templates'
$targetRoot = [System.IO.Path]::GetFullPath($Destination)

function Copy-TemplateFile {
    param(
        [Parameter(Mandatory)][string]$Source,
        [Parameter(Mandatory)][string]$Target
    )

    if ((Test-Path -LiteralPath $Target) -and -not $Force) {
        Write-Host "Omitido (ya existe): $Target"
        return
    }

    $targetDirectory = Split-Path -Parent $Target
    New-Item -ItemType Directory -Path $targetDirectory -Force | Out-Null
    $content = Get-Content -LiteralPath $Source -Raw
    $content = $content.Replace('<project-name>', $ProjectName)
    Set-Content -LiteralPath $Target -Value $content -Encoding utf8NoBOM
    Write-Host "Creado: $Target"
}

New-Item -ItemType Directory -Path $targetRoot -Force | Out-Null

$directories = @(
    'docs',
    'docs\decisions',
    'docs\diagrams',
    'docs\incidents',
    'docs\learning',
    'docs\runbooks'
)
foreach ($directory in $directories) {
    New-Item -ItemType Directory -Path (Join-Path $targetRoot $directory) -Force | Out-Null
}

$files = @(
    @{ Source = 'project-readme.md'; Target = 'README.md' },
    @{ Source = 'project.yaml'; Target = 'project.yaml' },
    @{ Source = 'docs-readme.md'; Target = 'docs\README.md' },
    @{ Source = 'context.md'; Target = 'docs\context.md' },
    @{ Source = 'architecture.md'; Target = 'docs\architecture.md' },
    @{ Source = 'deployment.md'; Target = 'docs\deployment.md' },
    @{ Source = 'rollback.md'; Target = 'docs\rollback.md' },
    @{ Source = 'decision.md'; Target = 'docs\decisions\ADR-0001-template.md' },
    @{ Source = 'incident.md'; Target = 'docs\incidents\INC-0001-template.md' },
    @{ Source = 'learning-readme.md'; Target = 'docs\learning\README.md' },
    @{ Source = 'runbooks-readme.md'; Target = 'docs\runbooks\README.md' },
    @{ Source = 'diagram.mmd'; Target = 'docs\diagrams\architecture.mmd' }
)

foreach ($file in $files) {
    Copy-TemplateFile `
        -Source (Join-Path $docsTemplateRoot $file.Source) `
        -Target (Join-Path $targetRoot $file.Target)
}

Copy-TemplateFile `
    -Source (Join-Path $templateRoot 'AGENTS.MD') `
    -Target (Join-Path $targetRoot 'AGENTS.MD')

$sharedTarget = Join-Path $targetRoot 'docs-shared'
if (Test-Path -LiteralPath $sharedTarget) {
    if (-not $Force) {
        Write-Host "Omitido (ya existe): $sharedTarget"
    }
    else {
        Get-ChildItem -LiteralPath (Join-Path $templateRoot 'docs-shared') -Force |
            Copy-Item -Destination $sharedTarget -Recurse -Force
        Write-Host "Actualizado: $sharedTarget"
    }
}
else {
    Copy-Item -LiteralPath (Join-Path $templateRoot 'docs-shared') `
        -Destination $sharedTarget -Recurse -Force
    Write-Host "Creado: $sharedTarget"
}

Write-Host "Estructura documental preparada para '$ProjectName' en $targetRoot"
