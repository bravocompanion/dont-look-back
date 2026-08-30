# Asset Delta — v0.74.4 Forest Terrain Opaque Material

## Implemented in v0.74.4

- Forest dimensions remain **448 × 608 m**.
- Natural hills/valleys, flat mission yards, smooth quest-road corridors, floor snap, and v0.74.2 falloff hardening are preserved.
- Added real Godot material resources instead of relying only on runtime-created placeholder colors:
  - `res://assets/materials/terrain/forest_ground_opaque_v744.tres`
  - `res://assets/materials/terrain/forest_trail_opaque_v744.tres`
- Both resources are `StandardMaterial3D` with transparency disabled, alpha 1.0, metallic 0, high roughness, and culling disabled for two-sided visibility.
- Terrain material is force-applied to both the ArrayMesh surface and `MeshInstance3D` surface override.
- `TerrainMesh.transparency` is forced to `0.0`, visibility is forced on, material overlay is cleared, and shadow casting remains enabled.
- Runtime also re-validates opaque state even if the `.tres` is edited later.
- Trail material is separate from ground material so gameplay roads remain readable without introducing transparent overlays.
- Materials use only solid colors for now, so they are safe for desktop, Android/mobile, and GL Compatibility without external texture imports.

## Current terrain/traversal state retained from v0.74.3

- Terrain grid: **84 × 114**, approximately **5.3 m per cell**.
- Mission yards/building pads remain fully flat.
- Yard transition feather: approximately **9–12 m**.
- Main quest road centerline keeps about **18%** of natural micro-relief and blends back to full terrain over a roughly **15 m** shoulder.
- Open forest retains the large v0.74 hills and valleys.
- Trail ribbon sampling remains approximately every **3 m**.
- Forest movement keeps **0.55 m floor snap** with the existing Forest-only movement path.
- Falloff protection remains: hardened terrain collision, backface collision, safety underlay, post-move containment, terrain-height recovery, transition readiness, and multiplayer transform validation.

## Assets now present in repository

### Runtime material resources

- `forest_ground_opaque_v744.tres` — opaque moss/dark-soil placeholder ground.
- `forest_trail_opaque_v744.tres` — opaque compacted-earth placeholder trail.

These are required internal project resources for v0.74.4 and are already included in the repository. No download or manual import is required.

## External art assets still recommended

### P0 — Final forest ground texture set

Replace/augment the solid-color ground when ready:

- `forest_ground_basecolor` — moss, dark soil, wet leaf litter.
- `forest_ground_normal` — subtle roots, stones, compressed soil.
- `forest_ground_roughness` — mostly matte with small damp variation.
- `forest_ground_ao` — optional; useful on desktop, optional on low-end mobile.
- Recommended master resolution: **2048²**, with **1024² mobile override** where needed.

### P0 — Final trail / compacted-soil texture set

- `forest_trail_basecolor` — compressed dirt, sparse leaves, subtle mud.
- `forest_trail_normal` — shallow footprints/ruts only.
- `forest_trail_roughness` — matte with small damp variation.
- Avoid strong directional seams so the texture works on bends.

### P0 — Slope / exposed-soil variants

- dirt/mud BaseColor + Normal + Roughness.
- sparse rock/stone BaseColor + Normal + Roughness.
- leaf-litter variant for valley floors.

### P1 — Natural terrain dressing

- 4–6 rock outcrop variants.
- 4 fallen-log variants.
- 4 stump/broken-tree variants.
- branches, roots, leaf piles, and forest debris.
- 3–5 fern/grass clumps using conservative alpha cutout.

### P1 — Road readability props

- subtle wheel-rut decals/mesh strips.
- flattened leaf patches.
- trail marker posts.
- survey ribbons / reflective tape.
- broken warning signs near deep forest.
- mine-direction markers near the warehouse split.

### P1 — Tree LOD upgrade

- 4–6 trunk/crown silhouette variants.
- LOD0 / LOD1 meshes.
- far billboard or very-low-poly impostor.
- mobile-friendly material atlas.

## Performance constraints

- Terrain remains one ArrayMesh + one trimesh collision.
- Solid-color `.tres` materials add no texture-memory cost.
- Keep decorative vegetation MultiMesh-compatible.
- Avoid per-tree collision on decorative far forest.
- Keep foliage transparency/overdraw conservative on mobile.
- Prefer shared materials/atlases for future texture upgrades.
- Do not place large collision meshes inside mission yards or across quest-road corridors.
- `TerrainSafetyUnderlayV742` remains collision-only and must remain invisible.

## Regression coverage

Existing tests remain:

- `tests/forest_falloff_regression_v742.gd`
- `tests/forest_terrain_traversal_regression_v743.gd`

New v0.74.4 test:

- `tests/forest_terrain_material_regression_v744.gd`
- verifies both `.tres` resources exist and load as `StandardMaterial3D`.
- verifies transparency is disabled, alpha is 1.0, and culling is disabled.
- verifies runtime terrain surface material and surface override are both opaque.
- verifies `TerrainMesh` is visible with instance transparency at 0.
- verifies all five quest trail meshes use opaque materials.

Native CI now runs v0.74.2, v0.74.3, and v0.74.4 Forest regressions with Godot 4.7.2.

## Asset requirement after this update

**New external mandatory assets: none.**

The two new runtime `.tres` material resources are already committed. Highest-priority future art remains the P0 final forest-ground and trail texture sets; the game no longer depends on those textures just to make the terrain visible and opaque.
