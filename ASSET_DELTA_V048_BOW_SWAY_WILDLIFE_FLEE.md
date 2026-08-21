# Asset Delta — v0.48 Bow Sway + Wildlife Flee Fix

## Runtime changes

- Bow draw sway is no longer represented by a moving aim marker.
- Procedural sway now moves/rotates the first-person camera directly.
- Sway strength scales with horizontal movement, sprint state, airborne state and vertical jump/fall velocity.
- Projectile direction uses the actual swayed camera forward vector at release.
- Wounded wildlife enters a dedicated flee state after arrow damage.
- Flee threat is the actual hunter peer position where available.
- Wounded Deer/Rabbit/Wolf/Boar move predominantly away from the hunter instead of circling around survivors.
- Wolf/Boar can return to their normal hostile behaviour only after the wound flee state expires.
- Existing real HP, draw-powered damage/range, physical arrows, 80% recovery / 20% break and embedded-arrow attachment remain active.

## New required assets

None. v0.48 is a gameplay/steering/camera-motion update and runs with the existing procedural placeholders.

## Existing production asset debt unchanged

- First-person hunting bow model with animated string and nocked-arrow socket.
- World/remote-player bow model.
- Draw start / draw loop / full tension / release animations.
- Arrow production model and impact variants.
- Bow creak, release, arrow flight, impact, break and pickup SFX.
- Final Deer/Rabbit/Boar/Wolf rigged models and wound/hit/flee animations.
- Flesh hit VFX/SFX and optional embedded-arrow bone/socket support.
- `res://assets/audio/forest_night.mp3` remains pending.

## QA focus

1. Hold draw while standing still: camera sway should be subtle and the HUD aim marker must not move.
2. Hold draw while walking: sway should increase slightly.
3. Hold draw while sprinting: camera/head sway should be clearly stronger but still controllable.
4. Hold draw while jumping/falling: sway should become strongest and projectile aim should follow the visible camera motion.
5. Release during any state: camera must return cleanly without permanent rotation/position drift.
6. Shoot Deer/Rabbit: wounded target must run away from the shooter.
7. Shoot Wolf/Boar: wounded target must flee during wound response instead of orbiting/attacking immediately.
8. Co-op client shoots wildlife: HOST should steer the animal away from that client's synchronized position.
9. Embedded recoverable arrows must continue following moving wounded wildlife.
