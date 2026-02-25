---
name: reel-orchestrator
description: Orchestrate end-to-end reel production package generation from free-form Spanish idea text. Use when a user shares a raw reel idea in conversation and wants automatic extraction into idea-input.yaml, ordered execution of modular reel skills, and delivery of all production documents with quality gates.
---

# Reel Orchestrator

Execute the complete reel workflow from idea intake to final package.

## Load these resources
- `references/workflow.md`
- `assets/templates/idea-input.template.yaml`
- `assets/templates/manifest.template.yaml`
- `scripts/parse_idea_text.ps1`
- `scripts/validate_reel_package.ps1`
- `scripts/build_pages_publicados.ps1`

## Inputs
- Free-form idea text from conversation.
- Optional constraints from user: target date, platform priority, legal restrictions, location, available resources.

## Outputs
- Create folder `docs/reels/ideas/YYYY-MM-DD-<slug>/`.
- Write `idea-input.yaml`.
- Write `00-manifest.yaml`.
- Ensure all numbered output documents exist.

## Step-by-step workflow
1. Parse free-form text into `idea-input.yaml`.
   - Prefer `scripts/parse_idea_text.ps1` for deterministic extraction.
2. Apply defaults for missing non-critical fields.
3. Detect blocking gaps and populate `missing_required_fields`.
4. Run skills in this order:
   - `reel-intake-brief`
   - `reel-research-factcheck`
   - `reel-script-structure`
   - `reel-production-pack`
   - `reel-oncamera-direction`
   - `reel-editing-publishing`
5. Validate quality gates.
   - Prefer `scripts/validate_reel_package.ps1` for package checks.
6. Update `00-manifest.yaml` with final status.
7. If `status: approved`, rebuild public pages index.
   - Run `scripts/build_pages_publicados.ps1`.
   - This step also updates `DOCS_VERSION` in `index.html` for cache busting.
   - Use `-SiteBaseUrl` if the GitHub Pages base domain/path differs.

## Blocking logic
Set `status: blocked` when:
- `mensaje_central` is missing.
- `linea_tematica` cannot be resolved.
- Required output files are missing.

When blocked:
- Keep generated partial files.
- Add precise follow-up questions in `00-manifest.yaml`.

## Editorial enforcement
- Never use proper names for spokesperson/talent.
- Use only `talento`, `voceria`, or `responsable`.
- Mark any unsupported claim as `no_apto`.

## Publication rule
- Do not include ideas in public pages indexes unless `00-manifest.yaml` has `status: approved`.
- Public links must be generated as full absolute GitHub Pages URLs with hash route and `?v=<DOCS_VERSION>`.
