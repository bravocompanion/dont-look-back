# Asset Delta — v0.74.3 Forest Terrain Visibility + Traversal

## Implemented without new external assets

- Forest dimensions remain **448 × 608 m**.
- Natural hills/valleys are preserved; the map is **not** rolled back to globally flat terrain.
- Terrain grid is increased from **56 × 76** to **84 × 114**, reducing the approximate terrain cell size from ~8 m to ~5.3 m. This gives yard shoulders and quest roads enough geometric resolution to blend smoothly.
- Authored yards/building pads remain exactly flat.
- Yard transition feathers are widened to roughly **9–12 m** so the flat pad cannot turn into a one-cell lip/step.
- Main quest roads are now **semi-flat gameplay corridors**: centerline keeps only ~18% of natural micro-relief and blends back to full terrain over a ~15 m shoulder.
- Open forest keeps full natural relief, including the larger v0.74 hills and valleys.
- Trail visual ribbons now sample every ~3 m and conform to the smoothed terrain.
- Procedural terrain material is explicitly **double-sided / culling disabled** so the ground remains visible across GL Compatibility, desktop, and mobile front-face conventions.
- Placeholder terrain albedo is slightly brighter for debug/readability until final terrain textures are integrated.
- Forest MovementSystem now uses a **0.55 m floor snap** and a 50° floor-angle allowance only in the Forest scene, preventing tiny downward contact gaps from feeling like ledges.
- v0.74.2 falloff protections remain active: hardened terrain collision, backface collision, safety underlay, post-move containment, terrain-height recovery, transition readiness, and multiplayer transform validation.
- Forest visual scatter remains one trunk MultiMesh + one crown MultiMesh. Budget remains **620 desktop**, **380 mobile/web-mobile**.

## Assets still recommended

### P0 — Terrain material set

The runtime is now visually safe without external textures, but final forest presentation still needs:

- `forest_ground_basecolor` — moss / dark soil / wet leaf litter blend.
- `forest_ground_normal` — subtle roots, stones, compressed soil.
- `forest_ground_roughness` — mostly matte with small damp patches.
- `forest_ground_ao` — optional; desktop useful, low-end mobile may omit it.
- Recommended source resolution: **2048² master**, with **1024² mobile import override** where needed.

### P0 — Road / compacted soil material

Because roads are now a deliberate gameplay corridor, add a dedicated tileable road material:

- `forest_trail_basecolor` — compressed dirt, sparse leaves, subtle mud.
- `forest_trail_normal` — shallow footprints/ruts only; avoid strong height illusion.
- `forest_trail_roughness` — matte, slightly damp variation.
- Must tile cleanly and avoid strong directional seams on bends.

### P0 — Slope / exposed-soil variant

Needed so hills do not look like one stretched material:

- exposed dirt / mud BaseColor + Normal + Roughness.
- sparse rock/stone BaseColor + Normal + Roughness.
- leaf-litter variant for valley floors.

### P1 — Natural terrain dressing

- 4–6 rock outcrop variants.
- 4 fallen-log variants.
- 4 stump / broken-tree variants.
- small branch, root, leaf-pile, and forest-debris scatter meshes.
- 3–5 low fern / grass clumps with alpha-cutout materials.

### P1 — Road readability props

Recommended after traversal is confirmed stable:

- subtle wheel-rut decals or mesh strips.
- occasional flattened leaf patches.
- trail marker posts.
- old survey ribbons / reflective tape.
- broken warning signs near deep forest.
- mine-direction markers near the warehouse split.

### P1 — Tree LOD upgrade

Current procedural trees are gameplay-safe placeholders. Recommended replacement:

- 4–6 trunk/crown silhouette variants.
- LOD0 / LOD1 meshes.
- far-distance billboard or very-low-poly impostor.
- mobile-friendly material atlas.

## Performance constraints after grid increase

- Terrain is still one ArrayMesh + one trimesh collision, not many per-tile bodies.
- Keep decorative vegetation MultiMesh-compatible.
- Avoid per-tree collision on decorative far forest; only gameplay-blocking trunks should get collision.
- Keep transparent foliage overdraw conservative for mobile.
- Prefer atlases and shared materials over one material per prop.
- Do not place large collision meshes inside mission yards or across the quest road corridor.
- `TerrainSafetyUnderlayV742` remains collision-only and must stay invisible.

## Regression coverage

Existing v0.74.2 regression remains:

- `tests/forest_falloff_regression_v742.gd`

New v0.74.3 regression:

- `tests/forest_terrain_traversal_regression_v743.gd`
- checks terrain visibility and cull mode.
- checks increased vertex/triangle density.
- checks all mission-yard centers remain flat.
- samples the main quest road and pump branch for abrupt grades/micro-steps.
- verifies open forest still has significant relief.
- verifies Forest floor-snap settings are active.

Native CI runs both tests with Godot 4.7.2.

## Asset requirement after this update

**New mandatory runtime assets: none.**

New highest-priority art need introduced by this refinement: **P0 dedicated forest trail/compacted-soil material**. The code update itself remains functional with procedural placeholder materials on desktop and mobile.
