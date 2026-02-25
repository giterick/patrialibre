# Reels Production Agent System

## Objective
Convert free-form reel ideas from conversation text into a complete production package.

## Required architecture
- Use `reel-orchestrator` as the entrypoint skill.
- Run the modular skills in this exact order:
1. `reel-intake-brief`
2. `reel-research-factcheck`
3. `reel-script-structure`
4. `reel-production-pack`
5. `reel-oncamera-direction`
6. `reel-editing-publishing`

## Input model
- Primary input is free text from conversation.
- Persist extracted structure in `idea-input.yaml`.
- Output folder per idea: `docs/reels/ideas/YYYY-MM-DD-<slug>/`.

## Extraction rules for `idea-input.yaml`
Map free text to the following schema:

```yaml
idea_id: string
fecha_objetivo: YYYY-MM-DD
mensaje_central: string
linea_tematica: economica|social|institucional
audiencia_objetivo: string
objetivo_video: string
segmento_preferido: string
duracion_segundos: integer
cta_objetivo: string
plataformas: [string]
tono: string
contexto_local_rd: string|null
fuentes_iniciales: [string]
restricciones_legales: [string]
locacion: string|null
recursos_disponibles: [string]
```

### Defaults
- `segmento_preferido`: `auto`
- `duracion_segundos`: `75`
- `plataformas`: `["instagram"]`
- `tono`: `racional_firme`
- `audiencia_objetivo`: `jovenes y clase media pensante en Republica Dominicana`
- `objetivo_video`: `educar, generar recordacion y aumentar compartidos`
- `cta_objetivo`: `Comparte este video si quieres un pais de oportunidades.`
- `fecha_objetivo`: current date if missing

### Blocking conditions
- Missing `mensaje_central` after extraction.
- Missing `linea_tematica` and no clear thematic match.
- Any required document not generated.

If blocked:
- Write `00-manifest.yaml` with `status: blocked`.
- Add `missing_required_fields` and explicit follow-up questions.

## Output package per idea
1. `00-manifest.yaml`
2. `01-creative-brief.md`
3. `02-factcheck-matrix.md`
4. `03-script-master.md`
5. `04-shotlist-storyboard.md`
6. `05-call-sheet-lite.md`
7. `06-direccion-talento.md`
8. `07-plan-arte-y-recursos.md`
9. `08-edicion-post.md`
10. `09-publicacion-multired.md`
11. `10-checklist-pregrabacion.md`

## Editorial policy (global)
- Never use proper names for spokesperson/talent.
- Only use: `talento`, `voceria`, or `responsable`.
- Keep tone `racional_firme`.
- Use results-based argumentation; avoid extremism and personal attacks.
- Every verifiable claim must include source and date.
- Claims without evidence must be marked `no_apto`.

## Quality gates
Before finalizing `00-manifest.yaml`, verify:
1. Script duration target remains in the 60-90 seconds range.
2. `03-script-master.md` contains:
- Hook
- Problema
- Comparacion
- Propuesta
- Cierre + CTA
3. Fact-check matrix includes `estado` per claim.
4. No proper names are used for on-camera role.
5. Publishing plan includes Instagram plus adaptations for TikTok and YouTube Shorts.
