# Asset Delta — v0.40 Flashlight / Cabin / Dawn / Icon HUD

## Required assets

No new production asset is required for this update.

The HUD reuses the existing assets:

- `assets/ui/hud/icon_health.svg`
- `assets/ui/hud/icon_hunger.svg`
- `assets/ui/hud/icon_thirst.svg`
- `assets/ui/hud/icon_stamina.svg`
- `assets/ui/hud/icon_battery.svg`
- `assets/ui/hud/icon_darkness.svg`

## Gameplay / layout changes

- Flashlight first-person beam origin is lowered by 20% of the 0.58 m camera offset (0.116 m).
- Flashlight cone is 20% smaller than the previous 36.4 degree cone: 29.12 degrees.
- Flashlight range remains 65 m and full-battery energy remains 20 until battery drops below 75%.
- Ranger Forest new runs start at 06:00.
- Cabin floor threshold is lowered and the old box step is replaced by a shallow collision ramp so the player can walk into the cabin without jumping.
- Top survival HUD uses icon + numeric value + horizontal bar for Health, Hunger, Thirst, Stamina, Battery and Darkness.

## Existing pending asset

- `res://assets/audio/forest_night.mp3` is still required for the 20:00–05:00 Forest Night ambience system.

## Optional production polish

- Production flashlight first-person/world model aligned to the lower beam origin.
- Flashlight lens/cookie texture tuned for the 29.12 degree cone.
- Cabin doorway threshold/porch ramp production mesh matching the new walkable collision profile.
