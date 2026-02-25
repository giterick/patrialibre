param(
  [Parameter(Mandatory = $true)]
  [string]$IdeaTextPath,

  [Parameter(Mandatory = $true)]
  [string]$OutputYamlPath,

  [string]$FechaObjetivo = "",
  [string]$SegmentoPreferido = "auto",
  [int]$DuracionSegundos = 75
)

function Get-SectionValue {
  param(
    [string]$Text,
    [string]$Label
  )

  $pattern = "(?im)^\s*$([regex]::Escape($Label))\s*:\s*(.+)$"
  $m = [regex]::Match($Text, $pattern)
  if ($m.Success) {
    return $m.Groups[1].Value.Trim()
  }
  return ""
}

function Get-LineaTematica {
  param([string]$Text)
  $t = $Text.ToLowerInvariant()

  $economicHits = @("impuesto","empleo","emprend","burocr","inversion","mercado","negocio") | Where-Object { $t.Contains($_) }
  $socialHits = @("asistencia","oportunidad","pobreza","trabajo","comunidad","dependencia") | Where-Object { $t.Contains($_) }
  $institutionalHits = @("corrup","seguridad","estado","institucion","ley","justicia","orden") | Where-Object { $t.Contains($_) }

  if ($economicHits.Count -ge $socialHits.Count -and $economicHits.Count -ge $institutionalHits.Count -and $economicHits.Count -gt 0) {
    return "economica"
  }
  if ($socialHits.Count -ge $economicHits.Count -and $socialHits.Count -ge $institutionalHits.Count -and $socialHits.Count -gt 0) {
    return "social"
  }
  if ($institutionalHits.Count -gt 0) {
    return "institucional"
  }
  return ""
}

function To-Slug {
  param([string]$Value)
  $slug = $Value.ToLowerInvariant()
  $slug = [regex]::Replace($slug, "[^a-z0-9\s-]", "")
  $slug = [regex]::Replace($slug, "\s+", "-")
  $slug = [regex]::Replace($slug, "-+", "-")
  $slug = $slug.Trim("-")
  if ([string]::IsNullOrWhiteSpace($slug)) {
    return "idea"
  }
  if ($slug.Length -gt 40) {
    return $slug.Substring(0, 40).Trim("-")
  }
  return $slug
}

function Yaml-Escape {
  param([string]$Value)
  if ([string]::IsNullOrEmpty($Value)) {
    return ""
  }
  $normalized = $Value -replace "`r`n", " " -replace "`n", " " -replace "\s+", " "
  return $normalized.Trim().Replace('"', '\"')
}

if (-not (Test-Path -LiteralPath $IdeaTextPath)) {
  throw "Idea text file not found: $IdeaTextPath"
}

$text = Get-Content -LiteralPath $IdeaTextPath -Raw -Encoding UTF8

$tema = Get-SectionValue -Text $text -Label "Tema principal"
$problema = Get-SectionValue -Text $text -Label "Problema que quiero explicar"
$resultado = Get-SectionValue -Text $text -Label "Resultado o propuesta"
$publico = Get-SectionValue -Text $text -Label "Publico"
$cta = Get-SectionValue -Text $text -Label "Llamado a la accion"
$fuentes = Get-SectionValue -Text $text -Label "Datos o fuentes que ya tengo"
$contexto = Get-SectionValue -Text $text -Label "Restricciones o contexto local"

$mensajeCentral = ""
if ([string]::IsNullOrWhiteSpace($tema)) {
  $mensajeCentral = (($problema + " " + $resultado).Trim())
} else {
  $mensajeCentral = $tema
}
if ([string]::IsNullOrWhiteSpace($mensajeCentral)) {
  $mensajeCentral = $text.Trim()
}

$lineaTematica = Get-LineaTematica -Text $text
$fecha = if ([string]::IsNullOrWhiteSpace($FechaObjetivo)) { (Get-Date).ToString("yyyy-MM-dd") } else { $FechaObjetivo }
$audiencia = if ([string]::IsNullOrWhiteSpace($publico)) { "jovenes y clase media pensante en Republica Dominicana" } else { $publico }
$objetivoVideo = if ([string]::IsNullOrWhiteSpace($resultado)) { "educar, generar recordacion y aumentar compartidos" } else { $resultado }
$ctaObjetivo = if ([string]::IsNullOrWhiteSpace($cta)) { "Comparte este video si quieres un pais de oportunidades." } else { $cta }
$ideaId = "{0}-{1}" -f $fecha, (To-Slug -Value $mensajeCentral)

$fuentesList = @()
if (-not [string]::IsNullOrWhiteSpace($fuentes)) {
  $fuentesList = $fuentes.Split(";") | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne "" }
}

$restricciones = @()
if (-not [string]::IsNullOrWhiteSpace($contexto)) {
  $restricciones = @($contexto)
}

$yaml = @()
$yaml += "idea_id: ""$(Yaml-Escape $ideaId)"""
$yaml += "fecha_objetivo: ""$(Yaml-Escape $fecha)"""
$yaml += "mensaje_central: ""$(Yaml-Escape $mensajeCentral)"""
$yaml += "linea_tematica: ""$(Yaml-Escape $lineaTematica)"""
$yaml += "audiencia_objetivo: ""$(Yaml-Escape $audiencia)"""
$yaml += "objetivo_video: ""$(Yaml-Escape $objetivoVideo)"""
$yaml += "segmento_preferido: ""$(Yaml-Escape $SegmentoPreferido)"""
$yaml += "duracion_segundos: $DuracionSegundos"
$yaml += "cta_objetivo: ""$(Yaml-Escape $ctaObjetivo)"""
$yaml += "plataformas:"
$yaml += "  - ""instagram"""
$yaml += "tono: ""racional_firme"""
$yaml += "contexto_local_rd: " + ($(if ([string]::IsNullOrWhiteSpace($contexto)) { "null" } else { """$(Yaml-Escape $contexto)""" }))
if ($fuentesList.Count -eq 0) {
  $yaml += "fuentes_iniciales: []"
} else {
  $yaml += "fuentes_iniciales:"
  foreach ($src in $fuentesList) {
    $yaml += "  - ""$(Yaml-Escape $src)"""
  }
}
if ($restricciones.Count -eq 0) {
  $yaml += "restricciones_legales: []"
} else {
  $yaml += "restricciones_legales:"
  foreach ($r in $restricciones) {
    $yaml += "  - ""$(Yaml-Escape $r)"""
  }
}
$yaml += "locacion: null"
$yaml += "recursos_disponibles: []"

$outDir = Split-Path -Path $OutputYamlPath -Parent
if (-not (Test-Path -LiteralPath $outDir)) {
  New-Item -ItemType Directory -Path $outDir -Force | Out-Null
}

$yaml -join "`n" | Set-Content -LiteralPath $OutputYamlPath -Encoding UTF8

Write-Output "Generated: $OutputYamlPath"
