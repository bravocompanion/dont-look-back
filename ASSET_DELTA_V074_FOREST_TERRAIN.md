# Asset Delta — v0.74.5 Natural Pathless Forest

## Implemented in v0.74.5

- Forest dimensions remain **448 × 608 m**.
- All separate authored road/path ribbon meshes are removed.
- No path has separate collision geometry.
- The former Cabin → House → Gas → Warehouse → Mine → Pump visual road is no longer rendered.
- The old long tree-free corridor along that route is also removed, allowing decorative forest scatter to cross the former route naturally.
- Mission yards/POIs retain their local vegetation clearance so structures, evidence, loot, and interactions remain readable.
- v0.74.3 terrain traversal smoothing is preserved invisibly in the terrain height function. This keeps the important gameplay corridor comfortable without making it look like an authored road.
- Future path presentation policy: **terrain color/material only**. Do not reintroduce raised ribbon meshes or separate path collision.
- Natural hills/valleys remain unchanged.
- Mission yards remain flat with smooth 9–12 m transition feathers.
- Forest floor snap remains 0.55 m.
- v0.74.2 falloff hardening remains active.
- v0.74.4 opaque terrain material remains active, so the ground stays solid and non-transparent.

## Runtime material state

Active terrain material:

- `res://assets/materials/terrain/forest_ground_opaque_v744.tres`

Dormant optional resource retained for a possible future **color-only** terrain path treatment:

- `res://assets/materials/terrain/forest_trail_opaque_v744.tres`

The dormant trail material is not applied to any runtime trail mesh in v0.74.5 because no trail mesh is created.

## Assets currently present in repository

- `forest_ground_opaque_v744.tres` — active opaque moss/dark-soil placeholder terrain material.
- `forest_trail_opaque_v744.tres` — dormant compacted-earth color reference for possible future terrain-only color variation.

No external download or manual import is required for this update.

## External art assets still recommended

### P0 — Final forest ground texture set

- `forest_ground_basecolor` — moss, dark soil, wet leaf litter.
- `forest_ground_normal` — subtle roots, stones, compressed soil.
- `forest_ground_roughness` — mostly matte with small damp variation.
- `forest_ground_ao` — optional on low-end mobile.
- Recommended master resolution: **2048²**, with **1024² mobile override** where needed.

### P0 — Slope / exposed-soil variants

- dirt/mud BaseColor + Normal + Roughness.
- sparse rock/stone BaseColor + Normal + Roughness.
- leaf-litter variant for valley floors.

### P1 — Natural terrain dressing

Pathless presentation makes natural dressing more important:

- 4–6 rock outcrop variants.
- 4 fallen-log variants.
- 4 stump/broken-tree variants.
- branches, roots, leaf piles, and forest debris.
- 3–5 fern/grass clumps using conservative alpha cutout.

### P1 — Landmark readability props

Use local landmarks instead of a continuous road:

- occasional survey ribbons near quest POIs only.
- broken warning signs near deep forest.
- unique debris clusters around House/Gas/Warehouse.
- mine warning marker close to the Warehouse/Mine sector.
- subtle reflective markers only around important decision points.

### P2 — Optional color-only ground hints

Only if navigation testing later proves the forest too unreadable:

- slightly compressed/less-green ground color patches.
- sparse disturbed leaves.
- very subtle mud color variation.
- must be painted/blended into the terrain material itself.
- must not add a raised path mesh or separate path collision.

## Performance constraints

- Terrain remains one ArrayMesh + one trimesh collision.
- No road/path mesh draw calls in v0.74.5.
- No separate road/path collision.
- Decorative vegetation remains MultiMesh-compatible.
- Avoid per-tree collision on decorative far forest.
- Keep foliage transparency/overdraw conservative on mobile.
- Prefer shared materials/atlases for future texture upgrades.
- Do not attach decorative meshes to `TerrainSafetyUnderlayV742`.

## Regression coverage

Existing tests retained:

- `tests/forest_falloff_regression_v742.gd`
- `tests/forest_terrain_traversal_regression_v743.gd`
- `tests/forest_terrain_material_regression_v744.gd`

New v0.74.5 test:

- `tests/forest_pathless_regression_v745.gd`
- verifies all five legacy path meshes are absent.
- verifies no separate path collision/geometry policy is active.
- verifies the old route is no longer reserved as a tree-free corridor.
- verifies terrain traversal smoothing remains active.
- verifies the future path policy is terrain color/material only.

Native CI runs all Forest regressions with Godot 4.7.2.

## Asset requirement after this update

**New mandatory assets: none.**

Highest-priority future art is now the final forest-ground texture set plus natural terrain dressing. A dedicated trail texture is no longer P0 because v0.74.5 intentionally has no visible authored path. If navigation later needs guidance, use local landmarks or subtle terrain color variation rather than a road mesh.
