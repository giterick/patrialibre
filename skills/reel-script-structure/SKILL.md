---
name: reel-script-structure
description: Build a 60-90 second reel script with fixed structure, hook variants, and CTA variants based on approved brief and fact-check outputs. Use when script writing must follow a consistent persuasive format without extremism.
---

# Reel Script Structure

Generate `03-script-master.md`.

## Load these resources
- `assets/templates/03-script-master.template.md`

## Inputs
- `idea-input.yaml`
- `01-creative-brief.md`
- `02-factcheck-matrix.md`

## Output
- `03-script-master.md`

## Structure requirements
1. Hook (0-5s)
2. Problema (5-20s)
3. Comparacion (20-40s)
4. Propuesta (40-65s)
5. Cierre con autoridad + CTA (65-90s)

## Generation rules
- Provide 2 hook variants.
- Provide 2 closing variants.
- Use only claims with `estado: apto`.
- Keep language simple, direct, and non-extremist.
- Do not use proper names for spokesperson role.

## Validation
- Include estimated duration per block.
- Keep full script within 60-90 seconds.
