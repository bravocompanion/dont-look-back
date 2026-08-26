# Asset Delta — v0.74.2 Forest Terrain + Falloff Hardening

## Implemented without new external assets

- Forest dimensions remain **448 × 608 m**.
- Runtime terrain remains a deterministic low-poly ArrayMesh with collision.
- Terrain relief remains gentle/natural; only authored yards/building pads are fully flat.
- Trails and open forest follow the terrain instead of being globally flattened.
- Existing hills/valleys are preserved.
- `ForestTerrainV74` collision is explicitly kept on collision layer 1 and its `ConcavePolygonShape3D` uses backface collision as an additional fail-safe.
- New invisible `TerrainSafetyUnderlayV742` sits below the legal terrain range and catches bodies only if the terrain contact ever fails.
- Player containment is enforced after the locomotion `move_and_slide()` tick and again by the Forest safety fallback.
- Recovery now compares the player against the expected terrain height instead of relying only on a global Y threshold.
- Horizontal positions are hard-clamped inside the full map bounds if a physics edge contact is missed.
- Forest map transitions now wait for the expanded terrain collision + safety underlay before releasing the player. The old cabin-only `ForestGround` is no longer considered sufficient world readiness.
- Multiplayer host validation rejects Forest transforms that are outside bounds or implausibly below the terrain.
- Forest visual scatter remains one trunk MultiMesh + one crown MultiMesh. Budget: **620 desktop**, **380 mobile/web-mobile**.
- No new required gameplay asset is needed for the project to boot or for the falloff fix to function.

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
- Do not place large collision meshes inside mission yards or directly across quest trails.
- Do not attach decorative meshes to `TerrainSafetyUnderlayV742`; it is collision-only and must remain invisible.

## Regression coverage added in v0.74.2

- `tests/forest_falloff_regression_v742.gd`
- Native CI runs the dedicated falloff test with Godot 4.7.2.
- Test covers terrain collision readiness, backface collision, safety underlay, all four map edges, vertical recovery, deep mine-return position, locomotion safety integration, transition readiness, and multiplayer transform validation.

## Asset requirement after this update

**New mandatory assets: none.**

The falloff fix is entirely code/collision/runtime logic. Recommended terrain/vegetation assets above remain unchanged in priority.
