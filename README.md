# DON'T LOOK BACK — Godot v0.58

First-person co-op survival horror for Godot 4.x with responsive desktop/mobile controls, 2–4 player LAN co-op, persistent progression, evidence-driven exploration, survival pressure, adaptive horror systems, and a Ranger-first campaign route.

## Current build — v0.58 GAMEPLAY DEPTH

v0.58 deepens the current campaign instead of adding a new map or monster. It turns investigation into a more active reasoning loop, makes consumables vulnerable actions, gives the Old Mine a shared power-routing rule, extends input locking to camera/actions/mobile, and introduces a high-level recovery budget for major co-op horror encounters.

### v0.58 changes

- Forest investigation now allows Abandoned House and Old Gas Station evidence to be collected in either order.
- Survey Manifest + Radio Trace must be cross-checked at the Ranger Case Board before Mine access can be completed.
- Host validates evidence collection by expected scene, physical target node, downed state, and interaction distance.
- Optional Water Sample now gives a real gameplay benefit: a stabilized emergency light at the Mine junction.
- Old Mine gains a shared UPPER/DEEP support-light routing mechanic; only one main circuit can stay powered at a time.
- Mine circuit switching is host-validated in multiplayer and shared to all peers.
- FOOD/WATER/MED are no longer instant: the player must remain exposed for a short action channel and the item is consumed only on completion.
- Damage/downed/death/invalid footing interrupts a consumable action without consuming the item.
- `GameplayInputLock` now gates movement plus the legacy desktop camera/action path and touch movement/look/action buttons.
- Major co-op Tenant and Darkness Creature encounters use a high-level pacing budget and recovery window instead of freely stacking on top of each other.
- Main menu version badge now reports v0.58.

See `ASSET_DELTA_V058_GAMEPLAY_DEPTH.md` for production-asset status and the runtime validation checklist.

## Current canonical campaign route

The active runtime is Ranger-first:

1. **Ranger Forest** — stabilize the cabin/shelter and investigate the missing survey team.
2. **Abandoned House / Old Gas Station** — investigate these two clue locations in either order.
3. **Ranger Case Board** — synthesize the manifest + radio trace into a Warehouse lead.
4. **Warehouse** — recover the Maintenance Map.
5. **Water Pump** — optional anomaly evidence; now improves Mine lighting safety.
6. **Old Mine** — route support power, recover the Foreman Log, Sealed Shaft Report, and Facility Access Badge.
7. **Labyrinth / Facility Level 03** — restore systems, recover T-03 data, and survive Lockdown.
8. **Restricted Research Facility** — inspect the routing terminal and reveal future anomaly locations.

Future routes may include Hospital, Museum, Laboratory, Cave, and other Labyrinth nodes, but those remain below current gameplay-depth/stability priorities.

## Core gameplay loop

**Prepare → Investigate → Expose yourself to danger → Recover evidence/resources → Survive the encounter → Unlock a deeper anomaly.**

Survival mechanics must support horror decisions rather than become administration. Fuel, food, water, crafting, hunting, fishing, weather, light, wounds, and shelter should create reasons to leave safety, make noise, stay exposed, or spend time under pressure.

## Investigation

v0.58 establishes a stronger investigation rule:

- evidence can be found before the HUD explicitly orders it;
- important clues should require interpretation/synthesis rather than only collection;
- optional evidence should provide tactical information, safety, shortcuts, or other meaningful consequences;
- host authority validates shared progression interactions in multiplayer.

The Ranger Case Board is now the first explicit synthesis step. Future investigation expansion should deepen this pattern rather than turning every clue into a mandatory linear waypoint.

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

### Major-threat pacing

In co-op, v0.58 introduces a high-level major-threat budget. Tenant and Darkness Creature cannot begin as separate simultaneous major encounters, and completing one creates a recovery window before another major encounter can start.

This system does not control monster navigation or combat AI. It only protects pacing so horror has CALM/RECOVERY space between high-pressure moments.

## Ranger Yard

The Ranger Yard is conditionally protected.

Protection exists only while either:

- the shelter generator is running; or
- the campfire has burn time remaining.

The player flashlight does not globally make the yard safe. If shelter protection fails, threats may enter the yard.

## Old Mine power rule

The Mine now has a shared support-power decision:

- **UPPER SHAFT** powers the early support lights;
- **DEEP SHAFT** powers lights nearer the lower evidence/gate route;
- only one main circuit can remain active at a time;
- both entrance and mid-shaft routing stations allow the team to change the active circuit;
- collecting the optional Water Sample enables a smaller stabilized junction light that remains available between the two circuits.

The purpose is to make Mine traversal a light-allocation decision rather than only another evidence corridor.

## Consumables

v0.58 removes instant FOOD/WATER/MED resolution from normal player input.

Current vulnerable durations:

- FOOD — about 2.0 seconds;
- WATER — about 1.4 seconds;
- MEDKIT — about 3.5 seconds.

The player cannot move while the action channel is active. Damage, downed/death state, player replacement, or losing valid footing interrupts the action and preserves the item.

This keeps survival items useful while making the timing of recovery part of the horror decision.

## Multiplayer

Current target: 2–4 survivors.

The game includes:

- Host / Join LAN co-op.
- Shared world/objective state.
- Remote survivor and flashlight representation.
- Host-owned monster damage/state for the main co-op horror systems.
- Downed / revive / team-wipe flow.
- Host-led map transitions.
- Shared finite pickup claims.
- Party-scaled finite supply bonuses for 3–4 players.
- Host-validated relay/pickup/evidence/Mine power interactions.

This remains prototype co-op authority, not a hardened competitive server. Shared shelter inventory consumption is still partly client-local and remains a follow-up before public Internet multiplayer.

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
- 1 — food action
- 2 — water action
- 3 — medkit action
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

`GameplayInputLock` is the central query point for gameplay-blocking UI and temporary vulnerable actions.

Current UI sources:

- Journal
- Crafting
- Stash
- Field Status

v0.58 additionally gates:

- desktop camera / legacy action hotkeys;
- mobile movement / touch look / action buttons;
- consumable-action movement via a temporary manual lock.

New gameplay UI should integrate with this lock rather than adding menu-specific checks directly to gameplay systems.

## Save / progression

Persistent save remains responsible for survival/inventory state, finite pickup claims, checkpoints, investigation/world progression, Journal state, and map-specific systems.

The v0.58 Forest clue-synthesis flag and Water Sample bonus are stored through the existing Investigation `progress_flags` save state.

Checkpoint + finite-loot rollback consistency remains a high-priority follow-up. Team-wipe/reload tests must verify that finite resources cannot be duplicated or incorrectly deleted.

Mine UPPER/DEEP circuit selection is currently a tactical per-session state and may reset on scene/session reload; it is not progression-gating state.

## Platform / export status

Committed export configuration currently contains the Web preset. Native Android and desktop export presets/CI validation remain required before beta/public release.

Native ENet multiplayer is appropriate for native desktop/Android builds. Browser multiplayer requires a browser-compatible transport strategy rather than assuming native ENet behavior.

## v0.58 validation priorities

1. House and Gas Station evidence work in either order.
2. Mine remains locked until both opening clues are synthesized at the Case Board and the Maintenance Map is obtained.
3. Remote evidence requests from the wrong scene/range are rejected.
4. Water Sample enables the stabilized Mine junction light without being required for progression.
5. UPPER/DEEP Mine circuits are mutually exclusive and synchronize to co-op peers.
6. Remote Mine routing requests from outside console range are rejected.
7. FOOD/WATER/MED resolve only after their action duration and are not consumed when interrupted.
8. Journal/Crafting/Stash/Status stop movement, desktop actions/camera, and mobile gameplay controls.
9. Tenant and Darkness major co-op encounters receive recovery separation.
10. Host/client map transitions, down/revive/team-wipe, pickup claims, and v0.57 authority validation do not regress.
11. Test the Mine light count/readability and touch controls on real Android hardware.

## Current technical/gameplay priorities after this pass

- Make checkpoint + finite-loot rollback deterministic.
- Move shared shelter/resource consumption toward host-owned inventory authority.
- Add native Android + Windows/Linux export presets and CI smoke builds.
- Add automated scene/load/save/co-op regression tests.
- Extend high-level horror pacing to solo systems.
- Make Labyrinth stages change gameplay rules, not only objective state.
- Scale 3–4 player horror through split/regroup decisions rather than HP inflation.
- Add a real Research Facility payoff encounter/choice before expanding to a new major map.
- Consolidate monster decision/navigation/motor/network ownership.
- Replace recursive world-light discovery with a light/protection registry or authored areas.
- Replace hard-coded gameplay coordinates with authored scene anchors where practical.
- Add Reduce Flashing accessibility support.
- Replace procedural prototype presentation with production assets after gameplay rules are locked.

## Asset status

v0.58 adds **no mandatory production asset**. The new Case Board synthesis, consumable channels, Mine consoles/lights, and recovery pacing all have procedural/text fallbacks.

New recommended P1 production work is tracked in `ASSET_DELTA_V058_GAMEPLAY_DEPTH.md`:

- medkit/food/water use animation + SFX;
- Ranger Case Board synthesis presentation;
- Mine power-routing consoles, fixtures, switch/hum SFX;
- stabilized Water Sample light presentation;
- subtle post-encounter recovery audio.

Existing P0 monster/survivor/flashlight/footstep/environment production needs remain in `ASSET_BACKLOG.md`.

## Workflow

Project workflow is:

**ChatGPT → GitHub → Godot**

GitHub is the code/source-of-truth layer. Pull the tested branch into Godot and validate runtime behavior on desktop and real Android hardware before treating a gameplay update as release-ready.
