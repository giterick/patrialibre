# Produccion de Reels

## Objetivo
Este modulo permite tomar una idea en texto libre y generar un paquete completo de produccion para reels.

## Flujo operativo
1. Escribir la idea en la conversacion.
2. Activar `reel-orchestrator`.
3. El orquestador extrae campos y guarda `idea-input.yaml`.
4. El orquestador ejecuta skills modulares en orden.
5. Se genera el paquete de salida en `docs/reels/ideas/YYYY-MM-DD-<slug>/`.

## Paquete estandar de salida
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

## Politica editorial obligatoria
- No usar nombres propios para el rol de voceria.
- Solo usar `talento`, `voceria` o `responsable`.
- Tono por defecto: `racional_firme`.
- Todo claim verificable incluye fuente y fecha.
- Claim sin evidencia suficiente: `no_apto`.

## Contrato de `idea-input.yaml`
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

## Estructura recomendada de una idea en texto libre
```text
Tema principal:
Problema que quiero explicar:
Resultado o propuesta:
Publico:
Llamado a la accion:
Datos o fuentes que ya tengo:
Restricciones o contexto local:
```

## Nota de implementacion
Si faltan campos criticos, el sistema genera `00-manifest.yaml` con `status: blocked` y preguntas puntuales para completar la idea.

## Publicacion en GitHub Pages
### Regla de publicacion
- Solo se publica una idea cuando `00-manifest.yaml` tiene `status: approved`.
- Estados distintos de `approved` no aparecen en el indice publico.

### Archivos visibles en Pages
- Se muestran solo los `.md` del paquete estandar.
- No se publican en el menu `idea-input.yaml` ni `00-manifest.yaml`.

### Flujo para publicar
1. Generar y revisar el paquete en `docs/reels/ideas/<idea-folder>/`.
2. Marcar `status: approved` en `00-manifest.yaml`.
3. Ejecutar el script de build de paginas publicas.
4. Hacer push/merge para que GitHub Pages refleje el indice actualizado.

### Cache busting por deploy
- El build de paginas publicas actualiza `DOCS_VERSION` en `index.html`.
- Los links publicos se generan como rutas hash absolutas (`#/docs/...`) con `?v=<DOCS_VERSION>`.
- El sitio recarga sidebar/homepage con esa version para minimizar necesidad de hard refresh.

## Scripts utiles (PowerShell)
```powershell
powershell -ExecutionPolicy Bypass -File skills\validate_skills.ps1
powershell -ExecutionPolicy Bypass -File skills\reel-orchestrator\scripts\parse_idea_text.ps1 -IdeaTextPath docs\reels\examples\idea-completa.txt -OutputYamlPath docs\reels\ideas\2026-02-25-ejemplo\idea-input.yaml
powershell -ExecutionPolicy Bypass -File skills\reel-orchestrator\scripts\validate_reel_package.ps1 -IdeaFolder docs\reels\ideas\2026-02-25-ejemplo
powershell -ExecutionPolicy Bypass -File skills\reel-orchestrator\scripts\build_pages_publicados.ps1
```
