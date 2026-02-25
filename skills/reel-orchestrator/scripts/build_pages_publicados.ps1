param(
  [string]$IdeasRoot = "docs/reels/ideas",
  [string]$PublicRoot = "docs/reels/publicados",
  [string]$IndexPath = "index.html",
  [string]$SiteBaseUrl = "https://giterick.github.io/patrialibre"
)

$ErrorActionPreference = "Stop"

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

function Update-DocsVersionInIndex {
  param(
    [string]$IndexFilePath,
    [string]$Version
  )

  if (-not (Test-Path -LiteralPath $IndexFilePath)) {
    throw "Index file not found: $IndexFilePath"
  }

  $indexRaw = Get-Content -LiteralPath $IndexFilePath -Raw -Encoding UTF8
  if ([string]::IsNullOrWhiteSpace($indexRaw)) {
    throw "index.html is empty or unreadable: $IndexFilePath"
  }

  $pattern = "(?m)^(\s*const\s+DOCS_VERSION\s*=\s*')[^']+(';\s*)$"
  if ([regex]::IsMatch($indexRaw, $pattern)) {
    $updated = [regex]::Replace(
      $indexRaw,
      $pattern,
      { param($m) $m.Groups[1].Value + $Version + $m.Groups[2].Value },
      1
    )
  } else {
    $injectPattern = "(?m)^(\s*<script>\s*)$"
    if (-not [regex]::IsMatch($indexRaw, $injectPattern)) {
      throw "Could not find <script> block in index.html to inject DOCS_VERSION."
    }
    $updated = [regex]::Replace(
      $indexRaw,
      $injectPattern,
      { param($m) $m.Groups[1].Value + "`r`n    const DOCS_VERSION = '$Version';" },
      1
    )
  }

  Set-Content -LiteralPath $IndexFilePath -Value $updated -Encoding UTF8
}

if (-not (Test-Path -LiteralPath $IdeasRoot)) {
  throw "Ideas root not found: $IdeasRoot"
}

if (-not (Test-Path -LiteralPath $PublicRoot)) {
  New-Item -ItemType Directory -Path $PublicRoot -Force | Out-Null
}

$docsVersion = (Get-Date).ToUniversalTime().ToString("yyyyMMddHHmmss")
Update-DocsVersionInIndex -IndexFilePath $IndexPath -Version $docsVersion

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

# Remove stale public idea directories that are no longer approved.
$currentApprovedNames = $approvedIdeaDirs | ForEach-Object { $_.Name }
$publicIdeaDirs = Get-ChildItem -LiteralPath $PublicRoot -Directory -ErrorAction SilentlyContinue
foreach ($publicIdeaDir in $publicIdeaDirs) {
  if ($currentApprovedNames -notcontains $publicIdeaDir.Name) {
    Remove-Item -LiteralPath $publicIdeaDir.FullName -Recurse -Force
  }
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
      $href = "$SiteBaseUrl/#/docs/reels/ideas/$($approvedDir.Name)/${doc}?v=${docsVersion}"
      $ideaLines += "- [$doc]($href)"
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

  $ideaLines += ""
  $ideaLines += "_Version de docs: ${docsVersion}_"
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
    $href = "$SiteBaseUrl/#/docs/reels/publicados/$($approvedDir.Name)/README.md?v=$docsVersion"
    $globalLines += "- [$($approvedDir.Name)]($href)"
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
$globalLines += "_Version de docs: ${docsVersion}_"
$globalLines += "_Generado automaticamente por build_pages_publicados.ps1._"

$globalLines -join "`n" | Set-Content -LiteralPath $publicReadmePath -Encoding UTF8

Write-Output "PUBLIC_PAGES_BUILD_OK"
Write-Output ("DOCS_VERSION: " + $docsVersion)
Write-Output ("Approved ideas: " + $approvedIdeaDirs.Count)
Write-Output ("Skipped (no manifest): " + $skippedNoManifest.Count)
Write-Output ("Skipped (non-approved): " + $skippedNonApproved.Count)
