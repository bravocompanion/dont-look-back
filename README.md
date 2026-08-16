# DON'T LOOK BACK — Godot v0.19

First-person survival horror prototype for Godot 4.x with desktop + responsive mobile controls, LAN co-op, host-authoritative monsters, persistent saves, survival systems, Journal progression, separate Labyrinth/Forest maps, runtime AI navigation, and dynamic Forest sun/moon lighting.

## v0.19 — ARC 1: THE LABYRINTH

v0.19 turns the Labyrinth into the first full gameplay arc instead of a short transition area.

### Pacing target

Arc 1 is designed for roughly **30–45 minutes on a first blind run** depending on exploration, co-op coordination, resource detours and failed breaker attempts. Experienced/speedrun play can be faster; there is no artificial 30-minute wall-clock lock.

The old three emergency relays now open the entrance to a much larger lower labyrinth instead of immediately sending the player to Forest.

### Arc 1 route

1. Opening Corridor + Apartment 03
2. Original Labyrinth — restore 3 emergency relays
3. Maintenance Wing — restore 3 fuse boxes
4. Flooded Service — turn 2 pressure valves
5. Archive — complete breaker sequence `B → A → C`
6. Lockdown — prepare supplies and start the final console
7. Survive a 2-minute stabilization holdout
8. Final beacon appears
9. Exit Arc 1 and load `forest.tscn`

A wrong Archive breaker resets the breaker sequence, triggers a temporary maintenance-light blackout/fault alarm, and increases enemy pressure.

### Larger labyrinth

`LabyrinthArc1System` builds a second runtime labyrinth section from approximately `z=-51` to `z=-141`.

The extension contains:
- Maintenance Wing zig-zag routes
- side-room fuse objectives
- Flooded Service corridors
- pressure-valve detours
- Archive shelves and split paths
- sequential breaker puzzle
- Lockdown chamber
- final escape route
- two mid-arc safe-light/checkpoint pockets
- survival supply detours
- three new Journal notes

The old `PerimeterBack` wall and pre-v0.19 Forest transition are removed once Arc 1 is ready. Forest transition is only created again after Lockdown is completed.

## New enemies

Arc 1 adds four host-authoritative enemy instances on top of The Tenant and Darkness Creature.

### The Mourner

Two Mourner instances appear as Arc 1 progresses.

Behavior:
- tall humanoid placeholder silhouette
- tracks nearby survivors
- investigates AI noise such as footsteps, sprinting, switches and alarms
- slowed by protective light but not completely disabled
- uses the shared runtime AStar3D graph
- non-instant-kill contact damage

### The Crawler

Two Crawler instances become active deeper in the Archive/Lockdown sections.

Behavior:
- low fast silhouette
- higher detection radius
- faster pressure than Mourner
- avoids pursuing survivors who are currently protected by strong light
- becomes more aggressive during Lockdown
- host-authoritative damage and movement in co-op

Arc 1 enemy transforms are replicated from host to clients. Clients do not run independent authoritative enemy movement.

## Arc 1 lighting

The Labyrinth remains dark, but navigation is more readable.

Original maze:
- previous dim lamps retained
- five additional maintenance lamps added
- fixture placeholders added to dim-light positions
- ambient lamps remain below `0.1` energy so they do not become protective safe zones

Arc 1 extension:
- 19 dim maintenance lamps
- cool gray/green horror tint
- broad low-cost coverage with shadows disabled
- blackout flicker during breaker faults
- emergency pulsing during Lockdown
- two stronger safe/checkpoint lamps where players can recover and plan

The flashlight, relay lights and designated safe lamps remain meaningfully stronger than ambient lamps.

## Survival / exploration rewards

Arc 1 side paths contain finite shared supplies:
- Flashlight Batteries
- Canned Food
- Bottled Water
- Bandage
- Medkit
- Cloth

These pickups use the existing host-authoritative pickup system in co-op and the persistent claimed-pickup save system.

## Save / Continue

v0.19 persists Arc 1 state:
- completed fuse boxes
- completed valves
- breaker sequence progress
- Lockdown active/completed state
- remaining holdout time
- Arc elapsed time
- Arc checkpoint stage

Autosaves occur at major Arc milestones. `NEW GAME` resets Arc 1 progress together with the rest of the world.

Two deeper checkpoint locations are added after major sector completion. Existing v0.15 shared-checkpoint polling distributes host checkpoint changes to connected survivors.

## Journal

The Journal mission tracker is now Arc-aware.

New Arc notes:
- `Maintenance Route Sheet`
- `Archive Breaker Tag`
- `Lockdown Procedure`

The breaker note explicitly records the `B → A → C` sequence so the puzzle can be solved through exploration rather than guessing.

## AI navigation

The v0.18 runtime AStar3D graph now includes Arc 1 waypoint and patrol sets.

In `main.tscn`, positions deeper than the old `z=-53` boundary are now treated as Arc 1 Labyrinth rather than as Forest. Tenant, Darkness and Arc enemies therefore use the correct Labyrinth clamp/patrol/navigation rules.

The navigation rebuild guard waits for both:
- `LabyrinthExpansion`
- `Arc1Expansion`

before rebuilding the Labyrinth graph.

## Multiplayer

Arc 1 keeps the existing host-authoritative model.

Shared state includes:
- Arc stage
- fuse/valve completion
- breaker progress
- Lockdown state/time
- enemy activation
- Arc enemy transforms
- damage
- finite supplies
- checkpoints

Objective interactions from clients are requested through the host. A client cannot independently open an Arc gate.

## Controls

Desktop:
- WASD — move / downed crawl
- Mouse — look
- Shift — sprint
- Space — jump
- E — interact / revive / Arc objective
- F — flashlight
- B or 4 — battery
- 1 — food
- 2 — water
- 3 — medical aid
- J — Journal
- K — Save World
- L — Load World while offline
- Esc — pause/menu

Mobile:
- left joystick — move / downed movement
- right swipe — look
- RUN
- JUMP
- USE — interaction / Arc objective / revive
- LIGHT
- BATT
- FOOD
- WATER
- MED
- JOURNAL
- MENU

## Testing v0.19

Use a clean Pull before testing. Because `project.godot` changed, preserve local edits with stash instead of discarding important local settings.

Recommended solo test:
1. Start NEW GAME.
2. Complete Apartment 03 and all three old relays.
3. Confirm the old final gate now leads deeper into the Labyrinth instead of directly loading Forest.
4. Confirm the old back wall has an opening aligned with the final-beacon route.
5. Restore Fuse A/B/C and verify the first Arc gate disappears.
6. Turn both pressure valves and verify the next gate opens/checkpoint saves.
7. Reach Archive and try one intentionally wrong breaker; verify blackout/fault behavior.
8. Complete `B → A → C` and verify Lockdown opens.
9. Start the final console and survive the 2-minute holdout.
10. Verify the final transition only appears after stabilization finishes.
11. Enter the final transition and confirm `forest.tscn` loads normally.
12. Save midway through Arc 1, close the game, CONTINUE, and confirm completed objectives stay completed.

Recommended enemy/light test:
1. Compare walking versus sprinting near a Mourner.
2. Verify a Mourner can investigate noise.
3. Verify strong protective light slows a Mourner.
4. Verify a Crawler refuses normal pursuit of a survivor currently in protective light.
5. Trigger a breaker fault and observe enemy pressure plus dim-light flicker.
6. Verify all ambient lamps remain dim and do not stop Darkness Exposure by themselves.
7. Verify safe checkpoint lamps do provide a clearly stronger lit pocket.

Recommended co-op test:
1. Host + one client, READY, START.
2. Let the client interact with a fuse/valve and verify host progress updates for both players.
3. Verify both clients see the same Arc gate state.
4. Verify Arc enemy motion originates from host and remains synchronized.
5. Verify Arc enemy damage uses the existing downed/revive flow.
6. Verify shared checkpoint state updates after Flooded Service/Archive milestones.
7. Join/reconnect while host is mid-Arc and verify Arc objective state synchronizes.

## Retained systems

v0.19 retains:
- separate `main.tscn` Labyrinth and `forest.tscn` Forest maps
- v0.18 AI CHASE / INVESTIGATE / SEARCH / PATROL
- The Tenant freeze-when-watched rule
- Darkness Creature light retreat
- health/hunger/thirst/stamina
- battery + Darkness Exposure
- cold, bleeding and infection
- crafting/shelter/storage
- persistent world save
- LAN Host/Join + Ready/Start
- downed/revive/crawl
- shared checkpoint flow
- desktop + mobile responsive controls
- Forest dynamic sun/moon cycle

## Current limitations

- Runtime F5 validation still has to be performed on the development machine; the assistant environment does not contain the Godot executable.
- Arc 1 production geometry is still procedural CSG/primitive art.
- Mourner/Crawler visuals are prototype meshes without final rigs or animations.
- Arc 1 has gameplay pacing designed for 30–45 minutes first-run, but actual completion time depends on player behavior.
- AI navigation remains a hand-authored runtime AStar waypoint graph rather than baked NavigationMesh.
- Internet matchmaking/NAT traversal is not implemented; multiplayer remains LAN/IP based.
- Final production audio, VFX, character art, environment modules and animation are still required.

## Asset status

See `ASSET_BACKLOG.md`. v0.19 adds new priority needs for Mourner/Crawler production models, Arc 1 maintenance/flood/archive/lockdown environment kits, objective props, additional dim-light fixtures, alarm/blackout audio, and Lockdown presentation.
