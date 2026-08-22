# DON'T LOOK BACK — Godot v0.59

First-person co-op survival horror for Godot 4.x with responsive desktop/mobile controls, 2–4 player LAN co-op, persistent progression, evidence-driven exploration, survival pressure, adaptive horror systems, and a Ranger-first campaign route.

## Current build — v0.59 CHECKPOINT / FINITE-LOOT CONSISTENCY

v0.59 fixes the fail-state model after the v0.58 gameplay-depth pass. Checkpoints are now deterministic time snapshots instead of only respawn positions.

### v0.59 changes

- Checkpoint captures a shared snapshot of world/progression/finite-loot state.
- Each co-op peer captures its own checkpoint inventory and survival payload instead of inheriting the host inventory.
- Solo death and synchronized co-op team wipe restore the checkpoint snapshot after scene reload.
- Finite supplies claimed after the checkpoint roll back and respawn exactly once.
- Inventory obtained after the checkpoint also rolls back, preventing duplication.
- Supplies claimed before the checkpoint remain claimed after a wipe.
- Investigation/evidence, Labyrinth Arc 1, shelter/generator/campfire/storage, renewable/radiation state, Journal/world state, and Mine power routing are included in the snapshot path.
- Mine UPPER/DEEP circuit selection is now persistent through save/checkpoint restore.
- Normal map transitions no longer trigger an old checkpoint restore.
- Persistent save stores the v0.59 checkpoint snapshot; old checkpoint saves receive a best-effort migration.
- Checkpoint restore grants a short horror recovery window so a major threat does not immediately restart on respawn.
- Main menu badge now reports v0.59.

See `ASSET_DELTA_V059_CHECKPOINT_CONSISTENCY.md` for the asset and validation delta.

## Current campaign route

1. **Ranger Forest** — stabilize the cabin and investigate the missing survey team.
2. **Abandoned House / Old Gas Station** — collect the opening clues in either order.
3. **Ranger Case Board** — synthesize Manifest + Radio Trace.
4. **Warehouse** — recover the Maintenance Map.
5. **Water Pump** — optional anomaly evidence with a Mine-lighting benefit.
6. **Old Mine** — route UPPER/DEEP support power and recover the Facility Access Badge.
7. **Labyrinth / Facility Level 03** — restore systems, recover T-03 data, survive Lockdown, and use the safe-lamp checkpoints.
8. **Restricted Research Facility** — inspect the routing terminal and reveal future anomaly routes.

Future Hospital/Museum/Laboratory/Cave routes remain deferred until the current gameplay/platform foundation is stable.

## Core gameplay loop

**Prepare → Investigate → Expose yourself to danger → Recover evidence/resources → Survive encounter → Unlock deeper anomaly.**

Survival mechanics should create horror decisions rather than administrative chores.

## Investigation

- Abandoned House and Old Gas Station evidence may be collected in either order.
- Manifest + Radio Trace require Case Board synthesis before the Warehouse lead is complete.
- Host validates evidence interaction scene, physical target, state, and distance.
- Optional Water Sample gives a tactical stabilized light in the Mine.

## Old Mine power rule

- **UPPER SHAFT** powers early support lights.
- **DEEP SHAFT** powers lower support lights.
- Only one main circuit stays active.
- Entrance and junction stations can change the shared circuit.
- Water Sample adds a smaller stabilized junction light.
- v0.59 persists the selected circuit through save/checkpoint restore.

## Consumables

Normal FOOD/WATER/MED inputs are vulnerable action channels:

- FOOD — about 2.0 s
- WATER — about 1.4 s
- MEDKIT — about 3.5 s

Movement is blocked during the action. Damage/downed/death/invalid footing cancels it and preserves the item.

## Checkpoint semantics — v0.59

A checkpoint is a **time snapshot**.

When a checkpoint is captured it records the current shared world plus each peer's local checkpoint survivor payload.

On solo death or co-op team wipe:

1. the current scene reloads;
2. shared world/progression returns to checkpoint state;
3. each survivor returns to their own checkpoint inventory/stats;
4. post-checkpoint finite loot respawns;
5. pre-checkpoint finite loot stays claimed;
6. post-checkpoint objective progress rolls back;
7. a short recovery budget prevents an immediate major-threat restart.

This is intentionally different from the old behavior where player state could rewind while world state continued forward.

Normal map transitions are not checkpoint restores.

## Horror identities

### The Tenant

Observation/panic monster. Stillness can trigger it, watched/freeze behavior remains central, and continuous flashlight contact can banish it.

### Darkness Creature

Loss-of-light monster. Darkness Exposure creates pressure and protective light is its primary counter.

### Pacing

Major co-op Tenant/Darkness encounters share a high-level threat budget. A completed encounter creates a recovery window. Checkpoint restore also forces a short recovery interval.

## Ranger Yard

The yard is protected only while the generator is running or the campfire still has burn time. Player flashlight does not globally make the yard safe.

## Multiplayer

Target: **2–4 survivors**.

Current systems include:

- Host / Join LAN co-op;
- shared world/objective state;
- remote survivor + flashlight representation;
- host-owned main monster damage/state;
- downed / revive / team-wipe flow;
- host-led map transitions;
- shared finite pickup claims;
- party-scaled supplies for 3–4 players;
- host-validated relay/pickup/evidence/Mine power interactions;
- synchronized checkpoint world snapshot with per-peer survivor checkpoint payloads.

Shared shelter inventory consumption is still partly client-local and remains a priority before public Internet multiplayer.

## Input ownership

`GameplayInputLock` gates:

- movement;
- desktop camera/action hotkeys;
- mobile movement/look/action controls;
- Journal/Crafting/Stash/Field Status;
- vulnerable consumable actions.

Gameplay input must not leak behind blocking UI.

## Save / progression

Persistent save owns:

- player survival/inventory;
- finite pickup claims;
- checkpoint + v0.59 shared snapshot;
- investigation progression;
- Journal;
- shelter/world state;
- Labyrinth Arc 1 state;
- renewable/radiation state;
- Mine power circuit state.

v0.59 defines rollback semantics explicitly: checkpoint restore rewinds both inventory and finite-loot claims to the same snapshot.

## Maps

- `res://scenes/forest.tscn` — Ranger Forest
- `res://scenes/mine.tscn` — Old Mine
- `res://scenes/main.tscn` — Labyrinth / Facility Level 03
- `res://scenes/research_facility.tscn` — Restricted Research Facility
- `res://scenes/main_menu_ranger.tscn` — current front end

## Controls

Desktop:

- WASD — move
- Mouse — look
- Shift — sprint
- Space — jump
- E — interact/use
- F — flashlight
- B / 4 — battery
- 1 — food
- 2 — water
- 3 — medkit
- J — Journal
- M — co-op UI
- K — save
- L — load
- Esc — menu/context UI

Mobile uses left joystick, right swipe, RUN, JUMP, USE, LIGHT, BATT, FOOD, WATER, MED, JOURNAL, and MENU controls.

Renderer: Godot `gl_compatibility` for desktop/mobile breadth. Mobile target minimum remains stable 30 FPS on realistic Android hardware; desktop target is normally 60 FPS.

## v0.59 validation priorities

1. Reach a Labyrinth safe-lamp checkpoint.
2. Take a finite supply after checkpoint and record inventory.
3. Complete an objective after checkpoint.
4. Die/team-wipe.
5. Confirm post-checkpoint supply respawns exactly once and post-checkpoint inventory is removed.
6. Confirm pre-checkpoint claimed supplies remain absent.
7. Confirm objective/world state returns to checkpoint state.
8. Confirm each co-op peer gets its own checkpoint inventory, not the host inventory.
9. Confirm normal map transition does not restore an old checkpoint.
10. Save after checkpoint, restart application, load, then wipe and repeat the checks.
11. Verify host + 1 client and host + 3 clients.
12. Verify desktop and Android restart flows.

## Current priorities after v0.59

- Real-device and 2–4 player checkpoint regression validation.
- Server-authoritative shared shelter inventory.
- Android + Windows/Linux export presets and CI smoke builds.
- Automated save/checkpoint/co-op regression tests.
- Labyrinth rule-depth pass.
- Solo horror pacing integration.
- 3–4 player split/regroup objective scaling.
- Research Facility payoff encounter/choice.
- Monster ownership cleanup.
- LightRegistry / authored protection volumes.
- Reduce Flashing accessibility.
- Production asset replacement.
- Major content expansion only after the above foundation is stable.

## Asset status

v0.59 requires **no new mandatory production assets**.

Recommended P1 polish only:

- checkpoint activation sting;
- safe-lamp/checkpoint confirmation pulse;
- wipe/restore ambience;
- checkpoint-restored UI icon;
- synchronized co-op checkpoint cue.

Existing Survivor/Tenant/Darkness/flashlight/footstep/environment and v0.58 consumable/Mine/Case Board production needs remain pending in `ASSET_BACKLOG.md`.

## Workflow

**ChatGPT → GitHub → Godot**

GitHub remains source of truth. Pull the tested `main` branch into Godot and validate desktop plus real Android runtime before treating an update as release-ready.
