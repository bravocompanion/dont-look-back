# Asset Delta — v0.74.6 Natural Pathless Terrain Color

## Implemented in v0.74.6

- Forest dimensions remain **448 × 608 m**.
- Forest remains intentionally **pathless**: no Cabin→House→Gas→Warehouse→Mine→Pump road ribbon mesh, no road collision, and no long tree-free route corridor.
- The v0.74.3 traversal smoothing remains inside terrain geometry only so important traversal stays comfortable without revealing a road visually.
- Terrain now uses **per-vertex natural ground color variation** instead of one flat placeholder color.
- Color sources are only:
  - terrain elevation,
  - terrain slope/normal,
  - deterministic low-frequency + detail variation.
- Route coordinates are deliberately not sampled by the color pass, so the terrain cannot accidentally paint a hidden quest path.
- Runtime palette blends moss/forest floor, leaf litter, damp valley ground, exposed soil, and sparse rocky slope tones.
- Vertex alpha remains **1.0** and the existing v0.74.4 opaque/double-sided material hardening remains active.
- `forest_ground_opaque_v744.tres` is now configured to use vertex colors as albedo while staying fully opaque.
- Natural color variation adds **zero texture samples** and no additional draw call, keeping it safe for desktop and mobile GL Compatibility.
- Terrain remains one ArrayMesh + one trimesh collision.
- v0.74.2 falloff hardening remains active.
- v0.74.5 pathless/tree-scatter policy remains active.

## Runtime material state

Active terrain material:

- `res://assets/materials/terrain/forest_ground_opaque_v744.tres`
  - resource name updated to `ForestGroundNaturalOpaqueV746`.
  - transparency disabled.
  - culling disabled / double-sided.
  - alpha 1.0.
  - vertex color used as albedo.
  - roughness 0.96.

Dormant optional reference only:

- `res://assets/materials/terrain/forest_trail_opaque_v744.tres`

The dormant trail material is not applied at runtime because v0.74.6 has no authored path mesh.

## External art assets still recommended

### P0 — Final forest ground texture set

Vertex colors now provide readable natural variation, but final presentation still benefits from a tileable texture set:

- `forest_ground_basecolor` — subtle moss, dark soil, wet leaf litter without obvious directional pattern.
- `forest_ground_normal` — small roots, pebbles, compressed soil; keep amplitude conservative so smooth traversal does not look bumpy.
- `forest_ground_roughness` — mostly matte with subtle damp patches.
- `forest_ground_ao` — optional; omit on low-end mobile if needed.
- Recommended source: **2048² master**, **1024² mobile override**.

The final BaseColor should be fairly neutral because runtime vertex color will tint it. Avoid very saturated green/brown source textures.

### P0 — Slope / exposed-soil texture variants

For future material blending/polish:

- exposed dirt/mud BaseColor + Normal + Roughness.
- sparse rock/stone BaseColor + Normal + Roughness.
- leaf-litter valley variant.

These are not required by v0.74.6 runtime; current vertex colors already distinguish these terrain conditions at low cost.

### P1 — Natural terrain dressing

Pathless presentation makes local natural detail important:

- 4–6 rock outcrop variants.
- 4 fallen-log variants.
- 4 stump/broken-tree variants.
- branches, roots, leaf piles, small debris.
- 3–5 fern/grass clumps with conservative alpha cutout.

### P1 — Landmark readability props

Navigation should use local landmarks instead of continuous roads:

- survey ribbon close to quest POIs only.
- broken warning signs in deep forest.
- recognizable debris clusters around House/Gas/Warehouse.
- mine-warning marker only near the Warehouse/Mine sector.
- occasional reflective marker at important decision points, not along an entire route.

### P2 — Optional color-only route hints

Only if playtesting later shows navigation is too difficult:

- slightly different compacted ground tint,
- sparse disturbed leaves,
- subtle mud coloration.

Any future hint must be blended into the existing terrain color/material. **Do not add a raised path mesh, dedicated path collision, or tree-free corridor.**

## Performance constraints

- One terrain ArrayMesh + one terrain trimesh collision.
- Vertex color adds one PackedColorArray to the existing ~84 × 114 terrain grid; no extra draw calls.
- Zero extra terrain texture samples in v0.74.6.
- No road/path draw call or collision.
- Decorative forest remains MultiMesh-compatible.
- Avoid per-tree collision for decorative distant trees.
- Keep foliage overdraw conservative on mobile.
- Future textures should share materials/atlases where possible.
- `TerrainSafetyUnderlayV742` remains collision-only and invisible.

## Regression coverage

Retained:

- `tests/forest_falloff_regression_v742.gd`
- `tests/forest_terrain_traversal_regression_v743.gd`
- `tests/forest_terrain_material_regression_v744.gd`
- `tests/forest_pathless_regression_v745.gd`

Added in v0.74.6:

- `tests/forest_terrain_color_regression_v746.gd`
- checks color array count equals vertex count.
- checks sampled terrain contains multiple natural colors instead of one flat color.
- checks every sampled vertex remains alpha 1.0.
- checks runtime material consumes vertex colors while remaining opaque.
- checks route-based coloring is disabled.
- checks all legacy path meshes remain absent.
- checks the color pass adds no mobile texture sampling cost.

Native CI runs all Forest regressions with Godot 4.7.2.

## Asset requirement after this update

**New mandatory external assets: none.**

Highest-priority future art remains the final neutral forest-ground texture set and natural terrain dressing. A dedicated trail/path texture is still not required because the Forest is intentionally pathless.