# Asset Delta v0.57 — Stability, Host Authority, Input Lock

## Gameplay / technical changes

- Project version moves to v0.57.
- Adds `GameplayInputLock` as a central gameplay input gate.
- Movement now stops while Journal, Crafting, Stash, or Field Status UI is open.
- Co-op UI input also respects the central input lock.
- Host now validates remote relay requests by scene, relay id, target existence, active state, and player distance.
- Host now validates remote pickup requests by target existence, current scene ownership, network-pickup contract, claimed state, and player distance.
- Remote player transforms receive a basic finite-value and teleport sanity check before being accepted for replicated survivor state.
- Remote survivor HUD stats are clamped to valid gameplay ranges before replication.
- Shared shelter actions are limited to an allow-list and are rejected unless the requesting peer is physically inside the Ranger Yard.

## New required assets

None.

v0.57 is intentionally a stability / authority update. It should not create new mandatory production-art dependencies.

## New recommended assets

None specifically required by the new code.

Production polish may later add a subtle blocked-action UI/audio cue when an interaction is rejected by the host, but this is optional and should use the existing HUD notification style first.

## Existing pending P0 production assets

- Final rigged The Tenant model.
- Tenant emergence / freeze / stalk / panic chase / attack / flashlight reaction / banish presentation.
- Final Darkness Creature model with light recoil / retreat / dissolve presentation.
- Survivor base body plus 3–4 readable co-op variants.
- First-person arms and world/remote-player body representation.
- First-person and world flashlight models.
- Survivor downed / revive / hit / death animation set.
- Core monster movement / proximity / attack audio.
- Surface footsteps for concrete, wood, dirt/grass, and metal.
- Production Labyrinth wall/floor/ceiling materials and door set.

## Existing pending P1/P2 assets from v0.56

P1:
- Ranger generator start / idle / failure / repair audio.
- Campfire loop / extinguish audio.
- Distinct powered / unpowered cabin exterior light fixtures.
- Shelter protected / exposed emissive status indicator.
- Production Hunting Bow and Arrow first-person/world models.
- Production Hunting Knife and harvest animation.
- Wildlife locomotion / hit / flee / death animations.
- Production Tenant / wildlife audio and VFX.

P2:
- Additional POI loot-container / dressing variants.
- Co-op stash / supply-crate variants.

## Existing pending audio files

- `res://assets/audio/forest_night.mp3`
- `res://assets/audio/draw.mp3`
- `res://assets/audio/shoot.mp3`
- `res://assets/audio/impact.mp3`

## Validation checklist

Desktop:
- Open Journal while moving: movement must stop immediately.
- Repeat with Crafting, Stash, and Field Status.
- Close the UI: movement must resume without stuck input.

Co-op:
- A client next to a relay can activate it.
- A client far from that relay cannot activate it through a forged request.
- Two players racing for one pickup produce only one accepted claim.
- A forged pickup path outside the current scene is rejected.
- Large one-frame remote teleport submissions are ignored by the host.
- Shelter action sent outside Ranger Yard is rejected.

Mobile:
- Journal/menu lock works while touch movement is held.
- Closing the UI does not leave virtual movement stuck.
- Validate at both 30 FPS and 60 FPS targets.

## Remaining v0.57 authority work

This first authority pass does **not** yet make remote inventories server-authoritative. Legacy shelter interactions still consume client inventory locally before the shared host state is changed. A later v0.57.x pass should move shared interaction inventory consumption to host-owned state before public Internet multiplayer.
