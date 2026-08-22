# Asset Delta v0.56 — Co-op Supply Scaling + Powered Safe Zone

## Gameplay changes
- Ranger Yard threat protection now requires either the shelter generator to be running or the campfire to have burn time remaining.
- Player flashlight does not activate Ranger Yard protection.
- When shelter protection is offline, Darkness/Tenant/hostiles are no longer automatically cancelled or evicted merely because they enter the fenced yard.
- Shelter status UI reports `YARD SAFE` / `YARD EXPOSED` on compact layouts and `RANGER YARD: PROTECTED` / `EXPOSED` on wider layouts.
- Solo and 2-player worlds retain the v0.55 base finite resource economy.
- 3-player parties receive deterministic extra shared finite supplies at Abandoned House, Old Gas Station, Warehouse and Mine.
- 4-player parties receive an additional smaller supply tier.
- Unclaimed bonus supplies are removed if party size drops below their tier and return if the party grows again.
- Claimed bonus supplies remain persistent through the existing SaveSystem/network pickup claim path.

## New required assets
None. v0.56 uses existing procedural pickup visuals, shelter lights and HUD text.

## Recommended production assets
P1:
- Ranger generator start/idle/failure/repair audio.
- Campfire loop and extinguish audio.
- Distinct powered/unpowered cabin exterior light fixtures.
- Small shelter status indicator/emissive panel showing protected vs exposed state.

P2:
- Additional POI container/loot dressing variants so 3–4 player bonus supplies do not look like loose prototype boxes.
- Co-op stash/supply crate visual variants.

## Existing pending assets
- `res://assets/audio/forest_night.mp3`
- `res://assets/audio/draw.mp3`
- `res://assets/audio/shoot.mp3`
- `res://assets/audio/impact.mp3`
- Production first-person/world Hunting Bow and Arrow models.
- Production Hunting Knife and harvest animation.
- Wildlife locomotion/hit/flee/death animations.
- Production Tenant/wildlife audio and VFX.
