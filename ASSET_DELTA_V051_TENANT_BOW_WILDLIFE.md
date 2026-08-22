# Asset Delta — v0.51 Tenant, Bow Feel, Wildlife Speed

## Runtime changes

- Deer/Rabbit post-wound proximity fleeing now uses true species base move speed.
- Wounded flee remains +20% for exactly 3 seconds per non-lethal arrow hit.
- Bow draw camera sway tiers:
  - walking: +25%
  - sprint/running: +40%
  - jump launch: one short +50% non-periodic camera/body kick
- Full bow draw smoothly reduces camera FOV by 30%.
- Tenant spawn/active rules:
  - night window only: 20:00-05:00
  - flashlight does not count as world-light protection
  - nearby active OmniLight3D world lights block spawning / targeting
  - stillness delay is randomized 2-10 seconds per eligible stationary window
  - Tenant respawn cooldown is randomized 15-60 seconds after an active encounter ends
  - co-op HOST validates night, world-light state and respawn cooldown

## New assets required

None.

## Existing/pending assets unchanged

- `res://assets/audio/draw.mp3`
- `res://assets/audio/shoot.mp3`
- `res://assets/audio/impact.mp3`
- `res://assets/audio/forest_night.mp3`
- production first-person/world bow
- production arrow/quiver
- wildlife rigs + hit/flee/death animations
- production Tenant model/rig/animations

## QA focus

1. Shoot Deer without killing it: speed should be 2.64 m/s for 3 seconds, then 2.20 m/s while continuing to flee if the player is still close.
2. Rabbit uses 3.36 m/s for 3 seconds, then returns to 2.80 m/s.
3. Draw while still, walking, sprinting and jumping; camera must remain smooth with no competing vibration layers.
4. Full draw should approach 70% of the original FOV (30% FOV reduction) and restore after release/cancel.
5. Before 20:00 and from 05:00 onward, Tenant must not spawn/remain active.
6. Between 20:00-05:00, stand still in darkness: spawn request occurs after a random 2-10 second delay.
7. Repeat beside an active cabin/porch/world OmniLight: Tenant must not spawn. Flashlight alone must not block the spawn timer.
8. After Tenant is dismissed, verify no new authoritative encounter can begin for a random 15-60 seconds.
9. Co-op: a lit target is excluded from Tenant target selection; another dark survivor may still be selected by the HOST.
