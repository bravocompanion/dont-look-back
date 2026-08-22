# Asset Delta — v0.50 Smooth Bow Sway + Short Wounded Flee

## New required assets

None.

v0.50 is a gameplay tuning/runtime pass only.

## Runtime changes

- Non-lethal arrow hits refresh a wounded flee response lasting 3.0 seconds.
- Wounded flee movement speed is exactly 1.20x the species' normal move speed.
- Existing anti-orbit steering remains active so wildlife still runs away from the shooter.
- After the 3 second wound response, normal species AI resumes.
- Bow draw sway now uses one coherent low-frequency camera/head sway layer.
- Walking, sprinting and airborne/jumping each apply a +30% sway amplitude tier.
- Movement-state sway bonuses do not stack, preventing sprint+jump vibration caused by overlapping oscillators.
- Sway transitions are smoothed before being applied to Camera3D.

## Existing pending production assets

No new files are introduced by v0.50. Existing pending assets remain unchanged, including:

- `res://assets/audio/draw.mp3`
- `res://assets/audio/shoot.mp3`
- `res://assets/audio/impact.mp3`
- `res://assets/audio/forest_night.mp3`
- production first-person/world Hunting Bow and Arrow models
- draw/release hand and bow animations
- production wildlife rigs, hit reactions, flee/death animations and corpse poses
- arrow impact/break/pickup VFX/SFX polish beyond the current shared impact cue

## QA focus

1. Shoot each wildlife species without killing it and verify the speed increase is subtle: approximately +20% only.
2. Verify the flee state lasts about 3 seconds, then the animal returns to its normal species behavior.
3. Hold bow draw while standing, walking, sprinting, jumping and sprint-jumping.
4. Verify movement increases sway about 30% but sprint+jump does not create a stacked vibration.
5. Verify camera sway remains smooth and projectile direction still follows the visible camera direction at release.
6. Confirm v0.49 draw/shoot/impact audio and persistent corpse behavior remain intact.
