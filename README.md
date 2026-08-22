# DON'T LOOK BACK — Godot v0.57

First-person co-op survival horror for Godot 4.x with responsive desktop/mobile controls, 2–4 player LAN co-op, persistent progression, evidence-driven exploration, survival pressure, adaptive horror systems, and a Ranger-first campaign route.

## Current build — v0.57 STABILITY / HOST AUTHORITY / INPUT LOCK

v0.57 is a foundation update. It does not add a new map or monster. It hardens the systems already used by the current Ranger campaign before more content is added.

### v0.57 changes

- Adds a central `GameplayInputLock` autoload.
- Movement is blocked while Journal, Crafting, Stash, or Field Status is open.
- Network/co-op menu input respects the same central lock.
- Host validates remote Labyrinth relay activation requests by scene, id, target, active state, and distance.
- Host validates remote pickup requests by target existence, scene ownership, network-pickup contract, claimed state, and distance.
- Remote survivor transforms reject non-finite positions and large one-update teleport jumps before replication.
- Remote survivor HUD stats are clamped to valid 0–100 ranges.
- Shared shelter requests are allow-listed and rejected unless the requesting peer is physically inside the Ranger Yard.
- Main menu version badge now reports v0.57.

See `ASSET_DELTA_V057_STABILITY_AUTHORITY.md` for asset status and the validation checklist.

## Current canonical campaign route

The active runtime is Ranger-first:

1. **Ranger Forest** — stabilize the cabin/shelter and investigate the missing survey team.
2. **Abandoned House** — recover the survey manifest.
3. **Old Gas Station** — recover the radio trace.
4. **Warehouse** — recover the maintenance map.
5. **Water Pump** — optional anomaly evidence.
6. **Old Mine** — recover the foreman log, sealed-shaft report, and Facility Access Badge.
7. **Labyrinth / Facility Level 03** — restore systems, recover T-03 data, and survive Lockdown.
8. **Restricted Research Facility** — inspect the routing terminal and reveal future anomaly locations.

Future routes may include Hospital, Museum, Laboratory, Cave, and other Labyrinth nodes, but those are not the next priority until the current runtime is stable.

## Core gameplay loop

**Prepare → Investigate → Expose yourself to danger → Recover evidence/resources → Survive the encounter → Unlock a deeper anomaly.**

Survival mechanics should support horror decisions rather than become administration. Fuel, food, water, crafting, hunting, fishing, weather, light, wounds, and shelter should create reasons to leave safety, make noise, stay exposed, or spend time under pressure.

## Horror identities

### The Tenant

- Triggered by stillness / panic rules.
- Panic rises from aggressive movement and fast look input.
- Watched/freeze behavior remains part of its identity.
- Panic controls pursuit/attack pressure.
- Continuous flashlight contact can banish it after the existing hold requirement.

The Tenant should remain an observation/panic monster rather than becoming a generic chaser.

### Darkness Creature

- Connected to Darkness Exposure and lack of protective light.
- Light is its primary counter-pressure.
- Must remain mechanically distinct from The Tenant.

## Ranger Yard

The Ranger Yard is conditionally protected.

Protection exists only while either:

- the shelter generator is running; or
- the campfire has burn time remaining.

The player flashlight does not globally make the yard safe. If shelter protection fails, threats may enter the yard.

## Multiplayer

Current target: 2–4 survivors.

The game already includes:

- Host / Join LAN co-op.
- Shared world/objective state.
- Remote survivor and flashlight representation.
- Host-owned monster damage/state for the main co-op horror systems.
- Downed / revive / team-wipe flow.
- Host-led map transitions.
- Shared finite pickup claims.
- Party-scaled finite supply bonuses for 3–4 players.

### v0.57 authority baseline

Remote relay and pickup interactions are now validated by the host before they mutate world state.

This is still prototype co-op authority, not a hardened competitive server. Remote inventory ownership for shared shelter consumption is still a known follow-up task before public Internet multiplayer.

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
- 3 — medical aid
- J — Journal
- M — co-op UI
- K — save
- Esc — menu / close context UI

Mobile:

- Left joystick — move
- Right swipe — look
- RUN
- JUMP
- USE
- LIGHT
- BATT
- FOOD
- WATER
- MED
- JOURNAL
- MENU

The renderer uses Godot `gl_compatibility` for desktop/mobile breadth. Mobile still requires real-device profiling for lights, CSG, foliage, navigation, audio load, and long-session thermals.

## Input ownership

v0.57 introduces `GameplayInputLock` as the central query point for gameplay-blocking UI.

Current dynamic UI sources:

- Journal
- Crafting
- Stash
- Field Status

New gameplay UI should integrate with this lock rather than adding new menu-specific checks directly to MovementSystem.

## Save / progression

Persistent save remains responsible for survival/inventory state, finite pickup claims, checkpoints, investigation/world progression, Journal state, and map-specific systems.

Checkpoint + finite-loot rollback consistency remains a high-priority follow-up. Team-wipe/reload tests must verify that finite resources cannot be duplicated or incorrectly deleted.

## Platform / export status

Committed export configuration currently contains the Web preset. Native Android and desktop export presets/CI validation remain required before beta/public release.

Native ENet multiplayer is appropriate for native desktop/Android builds. Browser multiplayer requires a browser-compatible transport strategy rather than assuming native ENet behavior.

## v0.57 validation priorities

1. Journal/Crafting/Stash/Status always stop movement on desktop and mobile.
2. Remote relay request from outside interaction range is rejected.
3. Remote pickup request from outside interaction range is rejected.
4. Forged pickup path outside the current scene is rejected.
5. Simultaneous pickup claims award the pickup once.
6. Large one-update remote teleport state is ignored.
7. Shelter action from outside Ranger Yard is rejected.
8. Host/client map transitions still preserve state.
9. Down/revive/team-wipe behavior is unchanged.
10. Test 30 FPS mobile and 60 FPS desktop targets.

## Current technical priorities after this pass

- Make checkpoint + finite-loot rollback deterministic.
- Move shared shelter/resource consumption toward host-owned inventory authority.
- Add native Android + Windows/Linux export presets and CI smoke builds.
- Add automated scene/load/save/co-op regression tests.
- Consolidate monster decision/navigation/motor/network ownership.
- Replace recursive world-light discovery with a light/protection registry or authored areas.
- Replace hard-coded gameplay coordinates with authored scene anchors where practical.
- Add Reduce Flashing accessibility support.
- Add a high-level horror/threat pacing director before stacking more major threat systems.
- Replace procedural prototype presentation with production assets after the foundation is stable.

## Asset status

v0.57 adds **no new required production assets**. Existing P0/P1/P2 production needs are tracked in `ASSET_DELTA_V057_STABILITY_AUTHORITY.md` and `ASSET_BACKLOG.md`.

## Workflow

Project workflow is:

**ChatGPT → GitHub → Godot**

GitHub is the code/source-of-truth layer. Pull the tested branch into Godot and validate runtime behavior on desktop and real Android hardware before treating a gameplay update as release-ready.
