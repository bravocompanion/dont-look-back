# Asset Delta v0.52 — Wildlife Corpse / Harvest / Bow Sway

## Runtime changes

- Wounded wildlife flee no longer uses the lateral steering term that could create rapid orbiting around the shooter.
- Wounded horizontal speed is hard-capped to base move speed × 1.20 for the existing 3 second wound response.
- If collision sliding reduces distance to the shooter, the next velocity is forced directly away.
- Dead wildlife uses a deterministic procedural side-fall pose instead of remaining upright.
- Living CharacterBody collision is disabled on death; a separate StaticBody3D on collision layer 2 is enabled only for carcass interaction.
- Forest InteractionRay keeps area detection disabled and uses collision mask 3, so it sees normal world bodies plus the dedicated carcass interaction layer without letting corpse bodies block player movement.
- Wildlife loot is no longer auto-granted at the lethal hit. A survivor must approach the carcass with a Hunting Knife and use E / USE.
- Successful harvest grants the species loot and removes the carcass until the existing wildlife respawn cycle.
- Multiplayer harvest uses a host-side carcass claim and distance validation, then synchronizes the collected corpse state.
- Bow draw sway tiers are now 140% while stationary, 180% while walking, and 220% while sprinting relative to the original stationary sway amplitude. The existing smooth jump impulse and 30% full-draw zoom remain.

## Required new assets

None. v0.52 is fully functional with procedural wildlife visuals and the existing item/icon set.

## Production assets still recommended

- Wildlife rigged production models for Deer, Rabbit, Boar, and Wolf.
- Per-species hit reaction animation.
- Per-species death/fall animation to replace the procedural 90-degree side-fall pose.
- Carcass idle/dead pose.
- Hunting Knife first-person/world model and harvest animation.
- Flesh hit / death / harvest SFX and optional blood VFX.
- Existing pending bow first-person/world models and draw/release animation.
- Existing pending `res://assets/audio/draw.mp3`, `shoot.mp3`, `impact.mp3`, and `forest_night.mp3` if they have not yet been added.

## QA

1. Shoot a Deer without killing it and verify it moves away from the shooter without circling; speed must never exceed 120% of its base movement speed during the 3 second wound response.
2. Repeat near trees/rocks and verify collision sliding does not turn into an orbit.
3. Kill each wildlife species and verify the body falls onto its side and remains visible.
4. Walk through/around the corpse and confirm the dead body does not physically block player movement.
5. Aim at the carcass and verify `Harvest <Animal> carcass` appears.
6. Without a Hunting Knife, E / USE must refuse harvest.
7. With a Hunting Knife and inventory room, E / USE grants loot and removes the carcass.
8. With insufficient inventory slots for new loot types, the carcass must remain available.
9. In co-op, two survivors attempting the same carcass must not duplicate loot.
10. Draw the bow while stationary, walking, and sprinting and verify sway increases smoothly without multiple oscillators fighting each other.
