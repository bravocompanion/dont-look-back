# Asset Delta — v0.74.1 Forest Terrain Refinement

## Implemented without new external assets

- Forest dimensions remain **448 × 608 m**.
- Runtime terrain remains a deterministic low-poly ArrayMesh with collision.
- Broad hills/valleys from v0.74 are preserved at roughly **-2.8 m to +3.6 m**.
- **Only authored yards / building pads are fully flat now.** Open forest and quest trails have gentle low-frequency natural relief.
- Ranger fenced yard remains flat for shelter, checkpoint, multiplayer regrouping, and base interactions.
- Abandoned House, Old Gas Station, Warehouse, Water Pump, and Old Mine keep only compact flat pads around their authored structures/interactables.
- Main and optional trail visuals now conform to terrain height instead of using horizontal floating box strips.
- Tree clearance from trails is preserved, so the more natural route surface does not create tree blockers.
- Legacy flat `ForestGround` / `ExpansionGround` collisions stay disabled when the expanded terrain is built.
- Forest visual scatter remains one trunk MultiMesh + one crown MultiMesh. Budget: **620 desktop**, **380 mobile/web-mobile**.
- Map boundary collision is strengthened to **24 m high**, extending down to **Y -8 m**, to prevent slipping under the terrain edge.
- A local fall-recovery guard restores the player to the most recent grounded in-bounds position if they drop below **Y -5.2 m** or escape the hard map bounds.
- Recovery is deliberately short-range during normal falls so it remains compatible with the current multiplayer remote-step validation.
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
- Do not place large collision meshes inside authored flat yards or across the conforming trail ribbons.

## Runtime safety notes

- Flat-yard policy is for interactables/structures only; routes should retain small natural elevation changes.
- Do not lower the fall-recovery threshold above the legitimate terrain floor without rechecking the minimum terrain elevation.
- If future terrain relief exceeds the current **-2.8 m** minimum, update the fall guard and boundary depth together.

## Preview / documentation asset

The annotated map preview should reflect the v0.74.1 height function: yards flat, routes/open forest lightly uneven, and the larger hills/valleys unchanged. It is documentation/debug output, not required at runtime.
