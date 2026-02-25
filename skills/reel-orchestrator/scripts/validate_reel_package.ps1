param(
  [Parameter(Mandatory = $true)]
  [string]$IdeaFolder
)

$requiredFiles = @(
  "00-manifest.yaml",
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

$errors = New-Object System.Collections.Generic.List[string]

if (-not (Test-Path -LiteralPath $IdeaFolder)) {
  throw "Idea folder not found: $IdeaFolder"
}

foreach ($f in $requiredFiles) {
  $full = Join-Path $IdeaFolder $f
  if (-not (Test-Path -LiteralPath $full)) {
    $errors.Add("Missing required file: $f")
  }
}

$scriptPath = Join-Path $IdeaFolder "03-script-master.md"
if (Test-Path -LiteralPath $scriptPath) {
  $scriptText = Get-Content -LiteralPath $scriptPath -Raw -Encoding UTF8
  foreach ($required in @("Hook", "Problema", "Comparacion", "Propuesta", "CTA")) {
    if ($scriptText -notmatch [regex]::Escape($required)) {
      $errors.Add("Script is missing required section marker: $required")
    }
  }
}

$directionPath = Join-Path $IdeaFolder "06-direccion-talento.md"
if (Test-Path -LiteralPath $directionPath) {
  $directionText = Get-Content -LiteralPath $directionPath -Raw -Encoding UTF8
  if ($directionText -cmatch "\b[A-Z][a-z]+ [A-Z][a-z]+\b") {
    $errors.Add("Detected probable proper name for spokesperson role; use talento/voceria/responsable.")
  }
}

if ($errors.Count -gt 0) {
  Write-Output "VALIDATION_FAILED"
  $errors | ForEach-Object { Write-Output $_ }
  exit 1
}

Write-Output "VALIDATION_OK"
