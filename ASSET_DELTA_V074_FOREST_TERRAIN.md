# Asset Delta — v0.74 Forest Terrain Expansion

## Implemented without new external assets

- Forest dimensions doubled from **224 × 304 m** to **448 × 608 m**.
- Runtime terrain is now a deterministic low-poly ArrayMesh with collision.
- Terrain relief is intentionally gentle: broad hills/valleys, roughly **-2.8 m to +3.6 m**.
- Existing ranger yard, mission POIs, quest interactables, loot clusters, and primary/optional trail corridors are flattened with soft shoulders so authored Y positions remain safe.
- Legacy flat `ForestGround` / `ExpansionGround` collisions are disabled when the v0.74 terrain is built.
- Main quest route is clarified as Cabin → Abandoned House → Old Gas Station → Warehouse → Old Mine, with an optional Old Mine → Water Pump branch.
- Forest visual scatter uses one trunk MultiMesh + one crown MultiMesh. Budget: **620 desktop**, **380 mobile/web-mobile**.
- Map boundaries now cover the full **448 × 608 m** footprint.
- No new required gameplay asset is needed for the project to boot or for multiplayer/mobile/desktop logic to run.

## Assets still recommended

### P0 — Terrain material set

Need a tileable forest-ground material suitable for slopes and valleys:

- `forest_ground_basecolor` — moss / dark soil / wet leaf litter blend.
- `forest_ground_normal` — subtle roots, stones, compressed soil.
- `forest_ground_roughness` — mostly matte with small damp patches.
- `forest_ground_ao` — optional; useful on desktop, can be omitted on low-end mobile.
- Recommended source resolution: 2048² master, with 1024² mobile import override where needed.

### P0 — Slope / exposed-soil variant

Needed so hills do not look like one stretched texture:

- exposed dirt / mud BaseColor + Normal + Roughness.
- sparse rock/stone BaseColor + Normal + Roughness.
- leaf-litter variant for valley floors.

### P1 — Natural terrain dressing

- 4–6 rock outcrop variants.
- 4 fallen-log variants.
- 4 stump / broken-tree variants.
- small branch, root, leaf-pile, and forest-debris scatter meshes.
- 3–5 low fern / grass clumps with alpha-cutout materials.

### P1 — Tree LOD upgrade

Current procedural trees are gameplay-safe placeholders. Recommended replacement:

- 4–6 trunk/crown silhouette variants.
- LOD0 / LOD1 meshes.
- far-distance billboard or very-low-poly impostor.
- mobile-friendly material atlas.

### P2 — Terrain readability props

Optional props to help navigation in the larger map without adding HUD clutter:

- trail marker posts.
- old survey ribbons / reflective tape.
- broken warning signs near deep forest.
- subtle mine-direction markers near the warehouse split.

## Performance constraints for future assets

- Preserve MultiMesh-compatible materials whenever possible.
- Avoid per-tree collision on decorative far forest; only gameplay-blocking trunks should get collision.
- Keep transparent foliage overdraw conservative for mobile.
- Prefer atlases and shared materials over one material per prop.
- Do not place large collision meshes inside the flattened mission corridors.

## Preview / documentation asset

The annotated v0.74 map preview is generated separately as JPG from the same terrain-height function and gameplay coordinate table. It is documentation/debug output, not required at runtime.
