# DON'T LOOK BACK — Asset Delta v0.59

## CHECKPOINT SNAPSHOT / FINITE-LOOT CONSISTENCY

v0.59 is a persistence and fail-state update. It changes what happens when a player dies or a co-op party wipes after reaching a checkpoint; it does not add a map, monster, weapon, or required production prop.

## New required assets

**NONE.**

The current safe-lamp/checkpoint presentation remains sufficient for the system update.

## Gameplay persistence rule

A v0.59 checkpoint is a time snapshot.

When a checkpoint is captured it stores:

- checkpoint transform and each peer's local survivor stats/inventory;
- shared finite-pickup claims;
- investigation/evidence progression;
- Labyrinth Arc 1 state;
- shelter/generator/campfire/storage world state;
- renewable/radiation state already owned by SaveSystem;
- Mine UPPER/DEEP power-routing state;
- Journal/world save data already included in the active save schema.

On solo death or co-op team wipe, the current scene reloads and restores that checkpoint snapshot. Supplies taken after the checkpoint respawn because their claims roll back, while the inventory gained after the checkpoint also rolls back. This prevents both duplication and silent item deletion.

Normal map transitions do not trigger checkpoint restoration.

## New recommended assets — P1

These are polish only and do not block v0.59:

- checkpoint activation sting (short, non-musical);
- safe-lamp/checkpoint confirmation pulse;
- team-wipe rewind/restore ambience;
- subtle checkpoint-restored UI icon;
- optional co-op synchronized checkpoint confirmation cue.

Accessibility requirement: any checkpoint pulse must support Reduce Flashing and should default to a slow emissive change rather than rapid full-screen flashing.

## Existing pending P0 assets

Unchanged:

- final Survivor model + 3–4 readable co-op variants;
- first-person arms/hands;
- final Tenant model/rig/animations/audio/VFX;
- final Darkness Creature model/animations/audio/VFX;
- first-person + world flashlight models;
- downed/revive/death animations;
- production footsteps by surface;
- Labyrinth/Mine production environment kit.

## Existing pending P1 assets

Unchanged from v0.58, including:

- FOOD/WATER/MED use animation and SFX;
- Case Board synthesis presentation;
- Mine routing console/light production pass;
- generator/campfire audio;
- Ranger Cabin powered/unpowered visual states;
- wildlife/hunting production content;
- Labyrinth fuse/valve/breaker/lockdown interaction presentation.

## Validation checklist

1. Reach the Mid Safe Lamp checkpoint.
2. Record inventory and visible finite supplies.
3. Take one finite supply after the checkpoint.
4. Advance one objective after the checkpoint.
5. Change Mine/support/world state where applicable.
6. Die/team-wipe.
7. Confirm player inventory returns to checkpoint inventory.
8. Confirm post-checkpoint finite supply respawns exactly once.
9. Confirm pre-checkpoint claimed supply remains absent.
10. Confirm objective/world state returns to checkpoint state.
11. Confirm normal map transition does not teleport the player back to an old checkpoint.
12. Repeat with host + 1 client and host + 3 clients.
13. Save after a checkpoint, restart the application, load, then repeat a wipe.
14. Verify desktop and Android restart flows.

## Asset status after v0.59

- New mandatory production assets: **0**
- New recommended P1 polish assets: **5 small feedback items**
- Existing P0/P1 backlog: **unchanged**
