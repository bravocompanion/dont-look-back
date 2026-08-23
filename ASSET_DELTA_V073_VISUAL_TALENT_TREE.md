# Asset Delta — v0.73 Visual Talent Tree

## Integrated mandatory runtime asset

The previously generated 20-talent icon set is now integrated as the v0.73 talent atlas.

Runtime representation:
- 320x256 atlas reconstructed in memory,
- 64x64 cell per talent,
- 20 unique talent regions,
- seven compact base64 repository parts,
- no external download/runtime network dependency.

This satisfies the mandatory icon requirement for all existing talent nodes.

## No additional mandatory art for v0.73

Graph connector lines, glow passes, arrowheads, selection borders and state treatments are drawn with native Godot UI primitives. No connector texture is required.

## Recommended P1 polish

- four specialization selector icons: Survival / Scout / Technician / Investigator,
- Talent Point icon in the detail/action panel,
- talent unlock SFX,
- max-rank SFX,
- restrained node-unlock pulse/VFX,
- optional branch rune/ornament texture for high-tier nodes.

## Existing production P0 backlog remains

1. final survivor base model,
2. 3–4 readable multiplayer survivor variants,
3. first-person hands/arms,
4. final Tenant model/rig/animations/audio/VFX,
5. final Darkness Creature model/animations/audio/VFX,
6. first-person + world flashlight models,
7. downed/revive/death animation set,
8. concrete/wood/dirt-grass/metal footsteps,
9. core monster audio,
10. final Labyrinth/Mine environment, material and door kits.

## Mobile/performance notes

- talent atlas is intentionally small,
- one atlas texture avoids 20 separate texture bindings/files,
- connectors use Control `_draw()` rather than particles or 3D nodes,
- no dynamic lights, physics or network replication are added,
- touch selects a node first; spending remains a separate explicit action.
