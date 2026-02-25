---
name: reel-research-factcheck
description: Create a fact-check matrix for reel claims with source, date, confidence, and risk status. Use when a reel brief or script includes verifiable statements and each claim must be validated before recording.
---

# Reel Research Factcheck

Generate `02-factcheck-matrix.md` from brief and idea data.

## Load these resources
- `assets/templates/02-factcheck-matrix.template.md`

## Inputs
- `idea-input.yaml`
- `01-creative-brief.md`

## Output
- `02-factcheck-matrix.md`

## Required matrix columns
- claim
- tipo_claim (dato|comparacion|causa_efecto|opinion)
- evidencia_resumen
- fuente
- fecha_fuente
- confianza (alta|media|baja)
- riesgo (alto|medio|bajo)
- estado (apto|no_apto)

## Rules
1. Mark verifiable claims without source as `no_apto`.
2. Mark outdated data as `riesgo: alto`.
3. Keep argumentative opinions separated from factual claims.
4. Add a final summary of blocked claims and replacement options.
