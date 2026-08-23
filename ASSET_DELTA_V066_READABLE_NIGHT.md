# Asset Delta — v0.66 Readable Night

## Mandatory runtime assets

**NONE.**

v0.66 changes only Forest world-lighting balance. It reuses the current procedural sky/environment, moon fill, generator lighting, flashlight and existing scene materials.

## Visual target

- 18:30 remains the reference for the darkest readable world state.
- Gameplay daylight still reaches 0.0 after dusk.
- Forest ambient visual energy is clamped to about 0.08355 once daylight reaches 25% or lower.
- Red/orange twilight tint is removed by the 18:30 threshold and replaced with neutral blue-gray darkness.
- Night remains dark enough for flashlight/local lights to matter, but silhouettes, ground and nearby world geometry should remain readable without crushing to black.

## Recommended P1 production polish

- neutral moon/sky LUT or color-grade pass designed for GL Compatibility;
- subtle non-red dusk gradient sky texture;
- low-cost cloud silhouettes for moonlit nights;
- calibrated forest ground/albedo pass so dark surfaces preserve shape at the 0.08355 ambient floor;
- device brightness QA reference screenshots for desktop, Android and Web.

## Existing P0 unchanged

Final Survivor/co-op variants, FP hands, final Tenant, final Darkness Creature, survivor animation set, monster audio/VFX, FP/world flashlight, four-surface footsteps, and Labyrinth/Mine production environment kits remain higher priority.
