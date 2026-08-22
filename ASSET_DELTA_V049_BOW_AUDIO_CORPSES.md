# Asset Delta — v0.49 Bow Audio + Persistent Wildlife Corpses

## New required audio assets

Add these exact files:

- `res://assets/audio/draw.mp3` — one continuous bow/string tension sound designed to be stretched to the full 1.35 s draw window. Do not bake a loop into the source.
- `res://assets/audio/shoot.mp3` — short bow release/string snap/arrow launch one-shot.
- `res://assets/audio/impact.mp3` — short generic arrow impact one-shot suitable for 3D positional playback.

The runtime has compatibility fallbacks for the same filenames at `res://`, but `res://assets/audio/` is the production location.

## Corpse visuals

No new model is required for the v0.49 logic fix. The existing wildlife visual now remains visible after lethal damage until the existing respawn/reset cycle.

Production improvement still recommended:

- deer/rabbit/boar/wolf death animation or ragdoll pose;
- separate dead-body collision/interaction shape if manual harvesting is restored;
- blood/death decal or wound mesh;
- species-specific impact/flesh SFX to replace the single generic `impact.mp3` later.

## Existing pending assets unchanged

- `res://assets/audio/forest_night.mp3` remains pending.
- Production bow FP/world model, hand animation, string animation, wildlife rigs, hit/flee animation, Tenant/Darkness models, Mine/Facility art and broader SFX debt remain unchanged.

## Runtime QA

1. Hold draw from 0 to 100%: `draw.mp3` should start once and finish around max draw, without looping.
2. Release at roughly 50%: draw audio stops and `shoot.mp3` plays once.
3. Cancel draw through a menu/state change: draw audio stops and no shoot sound should play.
4. Hit terrain and wildlife: `impact.mp3` should originate from the world impact position.
5. Multiplayer: authoritative impact should produce one positional impact sound on each peer.
6. Kill each wildlife species: the body must remain visible, stop moving, and no longer collide with players/arrows.
7. Wait for the normal respawn timer: the animal should reset to living/visible/collidable state.
