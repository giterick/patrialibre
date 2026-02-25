param(
  [string]$IdeasRoot = "docs/reels/ideas",
  [string]$PublicRoot = "docs/reels/publicados"
)

$standardDocs = @(
  "01-creative-brief.md",
  "02-factcheck-matrix.md",
  "03-script-master.md",
  "04-shotlist-storyboard.md",
  "05-call-sheet-lite.md",
  "06-direccion-talento.md",
  "07-plan-arte-y-recursos.md",
  "08-edicion-post.md",
  "09-publicacion-multired.md",
  "10-checklist-pregrabacion.md"
)

function Get-ManifestStatus {
  param([string]$ManifestPath)

  if (-not (Test-Path -LiteralPath $ManifestPath)) {
    return $null
  }

  $raw = Get-Content -LiteralPath $ManifestPath -Raw -Encoding UTF8
  $match = [regex]::Match($raw, '(?im)^\s*status\s*:\s*"?([a-zA-Z_]+)"?\s*$')
  if (-not $match.Success) {
    return $null
  }
  return $match.Groups[1].Value.Trim().ToLowerInvariant()
}

if (-not (Test-Path -LiteralPath $IdeasRoot)) {
  throw "Ideas root not found: $IdeasRoot"
}

if (-not (Test-Path -LiteralPath $PublicRoot)) {
  New-Item -ItemType Directory -Path $PublicRoot -Force | Out-Null
}

$ideaDirs = Get-ChildItem -LiteralPath $IdeasRoot -Directory | Sort-Object Name
$approvedIdeaDirs = New-Object System.Collections.Generic.List[object]
$skippedNoManifest = New-Object System.Collections.Generic.List[string]
$skippedNonApproved = New-Object System.Collections.Generic.List[object]

foreach ($dir in $ideaDirs) {
  $manifestPath = Join-Path $dir.FullName "00-manifest.yaml"
  $status = Get-ManifestStatus -ManifestPath $manifestPath

  if ($null -eq $status) {
    $skippedNoManifest.Add($dir.Name)
    continue
  }

  if ($status -ne "approved") {
    $skippedNonApproved.Add([PSCustomObject]@{
      idea = $dir.Name
      status = $status
    })
    continue
  }

  $approvedIdeaDirs.Add($dir)
}

foreach ($approvedDir in $approvedIdeaDirs) {
  $publicIdeaDir = Join-Path $PublicRoot $approvedDir.Name
  if (-not (Test-Path -LiteralPath $publicIdeaDir)) {
    New-Item -ItemType Directory -Path $publicIdeaDir -Force | Out-Null
  }

  $existingDocs = New-Object System.Collections.Generic.List[string]
  $missingDocs = New-Object System.Collections.Generic.List[string]
  foreach ($doc in $standardDocs) {
    $sourceDocPath = Join-Path $approvedDir.FullName $doc
    if (Test-Path -LiteralPath $sourceDocPath) {
      $existingDocs.Add($doc)
    } else {
      $missingDocs.Add($doc)
    }
  }

  $ideaReadmePath = Join-Path $publicIdeaDir "README.md"
  $ideaLines = @()
  $ideaLines += "# Idea Publicada: $($approvedDir.Name)"
  $ideaLines += ""
  $ideaLines += "Este indice lista los documentos del paquete estandar disponibles para esta idea."
  $ideaLines += ""
  $ideaLines += "## Documentos"
  if ($existingDocs.Count -eq 0) {
    $ideaLines += "- No hay documentos markdown publicables en esta idea."
  } else {
    foreach ($doc in $existingDocs) {
      $ideaLines += "- [$doc](../../ideas/$($approvedDir.Name)/$doc)"
    }
  }

  if ($missingDocs.Count -gt 0) {
    $ideaLines += ""
    $ideaLines += "## Advertencia"
    $ideaLines += "Faltan documentos del paquete estandar:"
    foreach ($doc in $missingDocs) {
      $ideaLines += "- $doc"
    }
  }

  $ideaLines -join "`n" | Set-Content -LiteralPath $ideaReadmePath -Encoding UTF8
}

$publicReadmePath = Join-Path $PublicRoot "README.md"
$globalLines = @()
$globalLines += "# Ideas de Reels Publicadas"
$globalLines += ""
$globalLines += "Esta pagina lista solo ideas con status: approved en 00-manifest.yaml."
$globalLines += ""
$globalLines += "## Ideas disponibles"

if ($approvedIdeaDirs.Count -eq 0) {
  $globalLines += "- No hay ideas aprobadas para publicar."
} else {
  foreach ($approvedDir in $approvedIdeaDirs) {
    $globalLines += "- [$($approvedDir.Name)](./$($approvedDir.Name)/README.md)"
  }
}

$globalLines += ""
$globalLines += "## Resumen de omisiones"

if ($skippedNoManifest.Count -eq 0) {
  $globalLines += "- Sin carpetas omitidas por falta de 00-manifest.yaml."
} else {
  $globalLines += "- Carpetas omitidas por falta de 00-manifest.yaml:"
  foreach ($name in $skippedNoManifest) {
    $globalLines += "  - $name"
  }
}

if ($skippedNonApproved.Count -eq 0) {
  $globalLines += "- Sin carpetas omitidas por estado distinto de approved."
} else {
  $globalLines += "- Carpetas omitidas por estado no publicable:"
  foreach ($entry in $skippedNonApproved) {
    $globalLines += "  - $($entry.idea) (status: $($entry.status))"
  }
}

$globalLines += ""
$globalLines += "_Generado automaticamente por build_pages_publicados.ps1._"

$globalLines -join "`n" | Set-Content -LiteralPath $publicReadmePath -Encoding UTF8

Write-Output "PUBLIC_PAGES_BUILD_OK"
Write-Output ("Approved ideas: " + $approvedIdeaDirs.Count)
Write-Output ("Skipped (no manifest): " + $skippedNoManifest.Count)
Write-Output ("Skipped (non-approved): " + $skippedNonApproved.Count)
