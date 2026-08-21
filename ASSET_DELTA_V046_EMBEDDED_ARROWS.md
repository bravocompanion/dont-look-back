# Asset Delta v0.46 — Embedded Arrows

## Gameplay update
- Recoverable arrows now stay visually embedded in living wildlife after impact.
- The arrow stores its impact transform relative to the animal and follows the animal's movement/rotation.
- If the animal dies, becomes hidden, or despawns, the arrow detaches and remains at its last world transform so it can still be recovered.
- Existing 80% recoverable / 20% break-on-impact rule remains unchanged.
- Draw power, projectile speed, effective range, damage falloff, wildlife HP and multiplayer host authority from v0.45 remain unchanged.

## Required assets
No new asset is required for gameplay logic. The procedural arrow remains functional.

## Production polish still recommended
P0:
- Bow first-person model with visible bow string and nocked-arrow socket.
- Production arrow model with shaft, arrowhead and fletching sized to match the projectile collision.
- Bow draw / hold / release animation.
- Wildlife hit reaction animation for deer, rabbit, boar and wolf.
- Arrow impact SFX for flesh, wood, dirt/stone and metal.

P1:
- Small flesh-entry VFX / blood puff at the impact point.
- Optional embedded-arrow sockets or bone attachment support when final rigged wildlife models replace procedural wildlife.
- Arrow break splinter VFX and SFX.

## Mobile / multiplayer note
The attachment system uses transform tracking rather than spawning extra physics joints, keeping the cost low on mobile. Host resolves impact and sends the wildlife `animal_id`; each peer attaches the local projectile to its synchronized local wildlife node.
