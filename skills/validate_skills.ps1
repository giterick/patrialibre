param(
  [string]$SkillsRoot = "skills"
)

if (-not (Test-Path -LiteralPath $SkillsRoot)) {
  throw "Skills root not found: $SkillsRoot"
}

$errors = New-Object System.Collections.Generic.List[string]
$skillDirs = Get-ChildItem -LiteralPath $SkillsRoot -Directory | Where-Object { $_.Name -like "reel-*" }

if ($skillDirs.Count -eq 0) {
  $errors.Add("No reel-* skill directories found.")
}

foreach ($dir in $skillDirs) {
  $skillName = $dir.Name
  $skillMd = Join-Path $dir.FullName "SKILL.md"
  $openaiYaml = Join-Path $dir.FullName "agents/openai.yaml"

  if (-not (Test-Path -LiteralPath $skillMd)) {
    $errors.Add("[$skillName] Missing SKILL.md")
    continue
  }

  if (-not (Test-Path -LiteralPath $openaiYaml)) {
    $errors.Add("[$skillName] Missing agents/openai.yaml")
  }

  $content = Get-Content -LiteralPath $skillMd -Raw -Encoding UTF8
  if ($content -notmatch "(?s)^---\s*\r?\n") {
    $errors.Add("[$skillName] SKILL.md missing YAML frontmatter opening.")
    continue
  }
  if ($content -notmatch "(?im)^name:\s*(.+)$") {
    $errors.Add("[$skillName] Frontmatter missing name.")
  } else {
    $frontmatterName = ([regex]::Match($content, "(?im)^name:\s*(.+)$")).Groups[1].Value.Trim()
    if ($frontmatterName -ne $skillName) {
      $errors.Add("[$skillName] Frontmatter name '$frontmatterName' does not match folder name.")
    }
  }
  if ($content -notmatch "(?im)^description:\s*(.+)$") {
    $errors.Add("[$skillName] Frontmatter missing description.")
  }
}

if ($errors.Count -gt 0) {
  Write-Output "SKILL_VALIDATION_FAILED"
  $errors | ForEach-Object { Write-Output $_ }
  exit 1
}

Write-Output "SKILL_VALIDATION_OK"
$skillDirs | ForEach-Object { Write-Output ("- " + $_.Name) }
