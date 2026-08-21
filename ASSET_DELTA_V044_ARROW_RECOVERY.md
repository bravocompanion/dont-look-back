# v0.44 — Physical Arrow Recovery Asset Delta

## Runtime status

No new production asset is required for the v0.44 arrow recovery logic to function.

The current implementation builds a lightweight procedural arrow from Godot primitive meshes and uses the existing `arrow` inventory item/icon.

## Implemented gameplay

- Hunting bow now fires a visible physical projectile instead of an instant hitscan result.
- Arrow flight has speed, gravity and an effective damage range.
- HOST resolves multiplayer projectile impact and wildlife damage.
- Every impact rolls a 20% break chance.
- 80% of impacted arrows remain in the world as `Recover Arrow` interactables.
- Desktop recovery uses E through the standard interaction ray.
- Mobile recovery uses the standard USE interaction.
- If inventory is full, the arrow remains in the world instead of being deleted.
- Remote co-op recovery is confirmed before HOST removes the shared projectile.

## Recommended production assets

### P1 — visual polish

- `Arrow_01.glb` or equivalent low-poly hunting arrow model.
- First-person hunting bow model.
- Remote/world hunting bow model.
- Draw / hold / release bow animations.
- Arrow nock/release animation.

### P1 — audio

- Bow string draw SFX.
- Bow release SFX.
- Arrow air pass / whistle SFX.
- Arrow wood impact SFX.
- Arrow dirt/rock/metal impact variants.
- Arrow break/snapping SFX for the 20% destruction roll.
- Arrow pickup/recovery SFX.

### P2 — VFX

- Small wood splinter burst when an arrow breaks.
- Tiny dirt/leaf impact puff for terrain hits.
- Optional blood hit marker for wildlife impact.

## Existing assets reused

- Existing `arrow` inventory item ID.
- Existing arrow inventory/workbench icon from the v0.43 item icon atlas.
- Existing Hunting Bow item and hunting systems.

## Still pending from previous versions

- `res://assets/audio/forest_night.mp3` remains required for the Forest night ambience system if it has not yet been added to the repository.
