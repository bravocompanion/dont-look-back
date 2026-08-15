# DON'T LOOK BACK — Godot v0.18

A first-person survival-horror prototype for Godot 4.x with desktop + responsive mobile controls, LAN co-op, host-authoritative horror encounters, survival systems, persistent world saves, Journal discoveries, responsive menus, and runtime AI navigation/perception.

## v0.18 — AI + Navigation Pass

v0.18 upgrades monster movement from mostly direct pursuit into a lightweight runtime navigation/perception layer designed around the project's dynamically generated labyrinth and exterior world.

New autoload systems:
- `AINavigationSystem`
- `AINavigationRebuildGuard`
- `AINoiseRelaySystem`

The existing `CoopHorrorSystem` remains responsible for authoritative monster damage, downed/revive logic, monster state broadcast, and team-wipe behavior.

### Runtime waypoint navigation

The current world is assembled by GDScript at runtime, so v0.18 uses an `AStar3D` waypoint graph rather than requiring a pre-baked static navmesh.

Navigation points cover:
- opening corridor
- labyrinth zig-zag routes and relay branches
- exterior path from the labyrinth exit to the cabin
- forest routes
- Abandoned House approaches/interior
- Old Gas Station
- Warehouse approaches and shelf aisles
- Old Water Pump
- deep forest routes

Waypoint links are only created when:
- points are within the configured link range
- direct ray checks are unobstructed
- additional left/right clearance checks are unobstructed

A delayed rebuild guard waits for the runtime Labyrinth and Exterior geometry to exist and allows several frames for CSG/collision data to settle before forcing the final navigation graph rebuild.

### AI perception states

The navigation system tracks four behavior modes:
- `CHASE` — a standing survivor is visible and can be pursued
- `INVESTIGATE` — a recent audible event has a known location
- `SEARCH` — line of sight/noise has been lost but the monster remembers the last known location
- `PATROL` — no current target; the monster moves between regional patrol points

The AI stores a last-known position and search/investigate timers rather than instantly knowing a hidden player's exact position forever.

### Hearing / player noise

Movement now generates lightweight AI noise events based on measured survivor movement speed:
- sprinting creates the strongest recurring movement noise
- normal walking produces a smaller hearing event
- downed survivors do not emit the normal walk/sprint event through this system

Important interactions also generate AI noise:
- opening/closing a normal door
- rattling a locked exit
- unlocking the exit
- moving the heavy exit door
- starting/refueling the shelter generator
- successful workbench crafting
- using the Old Water Pump

`AINoiseRelaySystem` keeps hearing host-authoritative in LAN co-op. A client interaction sends its noise event to the host; the host inserts it into the AI perception system.

### The Tenant

The signature rule is retained:
- watching The Tenant freezes its pursuit movement
- any standing co-op survivor can still contribute to the watched check

When The Tenant is allowed to move, v0.18 routes its movement toward the current memory goal through the runtime waypoint graph instead of always moving directly through obstacles.

The Tenant can therefore:
- chase a visible survivor
- move toward recent footsteps/interactions
- continue toward the last known location after losing sight
- return to regional patrol behavior when the search expires

Panic, attacks, damage and co-op state synchronization remain handled by the existing horror system.

### Darkness Creature

The Darkness Creature retains its defining light rule:
- nearby protective light still forces retreat/despawn behavior
- directly visible survivors standing in protective light are not selected as normal darkness chase targets by the new perception layer

When it is pursuing outside protective light, v0.18 routes movement around available runtime waypoint connections. This is especially important around the Abandoned House and Warehouse shelves.

A newly created Darkness Creature also receives a safety check; if its spawn appears embedded in blocked geometry, the system can reposition it to the nearest navigation waypoint.

### Solo and co-op authority

Solo:
- the new navigation layer routes Tenant/Darkness movement
- the existing monster scripts continue handling their special rules, attacks, light reactions and lifetime logic

LAN co-op:
- only the HOST drives AI navigation/perception
- clients do not independently pathfind monsters
- client interaction noise is relayed to the host
- host monster transforms continue to be distributed through `CoopHorrorSystem`

Night difficulty tuning from `NightThreatSystem` is preserved. Its speed values are read by the navigation layer before the old direct movement path is suppressed for that frame.

## v0.17 Front End retained

Main menu:
- CONTINUE
- NEW GAME
- HOST CO-OP
- JOIN CO-OP
- SETTINGS
- QUIT on desktop

Pause/menu:
- `Esc` on desktop
- `MENU` on mobile
- solo pauses the SceneTree
- co-op keeps the host world running while the local survivor is blocked

Settings remain stored at:

`user://dont_look_back_settings.cfg`

Current settings:
- Master Volume
- Look Sensitivity
- FPS limit: 30 / 60 / 120
- Fullscreen on supported desktop platforms

The title screen version badge is synchronized to v0.18.

## v0.15 Multiplayer Polish retained

LAN co-op target: 2–4 survivors.

Retained systems:
- survivor display names
- Ready / Not Ready
- Host START
- responsive session roster
- teammate Health / DOWNED HUD
- ping estimate
- reconnect attempt + RECONNECT control
- late-join recovery foundation
- shared checkpoint authority
- revive progress UI
- slow downed crawling
- host-authoritative monster damage/state
- shared relays
- shared day/night
- shared generator/campfire state
- shared finite survival pickups

## Persistent World retained from v0.14

World save:

`user://dont_look_back_save_v1.json`

Persistent data includes:
- player position/yaw
- Health/Hunger/Thirst/Stamina
- flashlight battery/state
- Darkness Exposure
- inventory
- Bleeding / Infection / Cold
- relay progress
- labyrinth door state
- checkpoint snapshot/name
- day/time
- generator/campfire fuel
- shelter storage
- finite claimed loot
- Journal entries/order

AI's transient CHASE/SEARCH position is intentionally not written into disk saves. A restored run resumes from the persistent world and the AI reacquires information normally.

## Journal + Door Safety retained

Journal:
- `J` desktop
- `JOURNAL` mobile
- missions, tips, logs, trivia and warnings
- persistent discoveries

Door safety remains active:
- moving collision is disabled before door rotation
- one physics frame is allowed before movement
- collision is restored after motion
- closing collision waits until the local player clears the dangerous hinge area

The new v0.18 door-noise behavior is added on top of this safety logic.

## Survival systems retained

Core stats:
- Health
- Hunger
- Thirst
- Stamina
- Flashlight Battery
- Darkness Exposure
- Cold Exposure
- Bleeding
- Infection

Resources / processing:
- Food
- Clean Water
- Dirty Water
- Medkit
- Cloth
- Bandage
- Wood
- Scrap
- Fuel Can
- Flashlight Battery
- Firewood Bundle
- boiling Dirty Water at the shelter
- workbench crafting
- shared shelter storage

## Current world

Progression covers:
1. opening corridor / The Tenant
2. Apartment 03
3. expanded labyrinth
4. Relay A / B / C
5. final gate
6. The Outside
7. cabin shelter
8. expanded forest
9. Abandoned House
10. Old Gas Station
11. Warehouse
12. Old Water Pump
13. stronger deep-zone night threat

## Controls

No new player buttons are required for v0.18.

Desktop:
- WASD — move / downed crawl
- Mouse — look
- Shift — sprint
- E — interact / revive
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
- left joystick — move / downed movement path
- right swipe — look
- RUN / USE / LIGHT / BATT / FOOD / WATER / MED
- JOURNAL
- MENU

## Testing v0.18

Recommended solo test:
1. Pull latest `main` and press F5 in the existing Godot project.
2. Start/Continue and trigger The Tenant.
3. Break line of sight around corridor/labyrinth geometry and verify the monster does not simply cut straight through a wall.
4. Walk quietly, then sprint while a monster is within hearing range and compare its investigate behavior.
5. Open doors repeatedly near an active threat and verify the interaction can attract investigation.
6. Outside at night, test the Abandoned House and Warehouse shelves while a Darkness Creature is active.
7. Break line of sight and watch for last-known-position/search behavior rather than perfect tracking forever.
8. Verify protective light still repels the Darkness Creature.
9. Verify watching The Tenant still freezes its pursuit.
10. Start/refuel the generator, craft at the workbench and use the water pump while a threat is nearby to test interaction noise.

Recommended two-device LAN test:
1. HOST and JOIN normally, READY both survivors, then START.
2. Let the client sprint/open a door/use a noisy interaction while the host monster is nearby.
3. Verify the HOST AI reacts to the client-generated event.
4. Verify both devices see the same host-driven monster position/state.
5. Break line of sight around the Warehouse/House and check that only the host determines the route.
6. Re-test downed/revive, shared checkpoint, reconnect and mobile controls to confirm v0.15/v0.17 behavior remains intact.

## Asset status

Production asset requirements are tracked in `ASSET_BACKLOG.md` and updated for v0.18.

v0.18 makes these particularly important:
- Tenant search/listen/turn/freeze-transition animations
- Darkness crawl/search/retreat/dissolve animations
- proper footsteps for concrete/wood/dirt/metal with quieter walk and louder sprint variants
- door swing/creak/locked-rattle/heavy-exit SFX
- generator start/loop/refuel mechanical SFX
- workbench hammer/scrape SFX
- hand-pump squeak/clank SFX
- monster investigation/search vocal cues
- collision-safe Warehouse shelves, House furniture/doorways and Gas Station props

The project remains code/procedural-first; the skipped production-art/audio milestone is still not being treated as complete.

## Current limitations

- Runtime Godot validation must still be performed on the development machine; the assistant environment does not contain the Godot executable.
- Navigation is a hand-authored runtime waypoint graph, not a fully baked NavigationMesh.
- The graph represents the current procedural map. Major future geometry changes may require waypoint updates.
- Hearing currently uses gameplay radii; it does not yet model acoustic occlusion, reverb rooms or material-dependent sound propagation.
- AI does not yet have final AnimationTree/turn-in-place/foot-IK presentation.
- Internet matchmaking / NAT traversal is not implemented; co-op remains LAN/IP based.
- Client-specific persistent account profiles are not implemented.
- Final character models, animations, production audio, VFX and environment art are still missing.

## Recommended next update

Before another large story/map expansion, the strongest next milestone is **v0.19 — Art + Audio / AI Presentation Integration**: replace high-impact placeholders, connect movement/search states to final animations, add real surface footsteps/spatial monster audio, then continue story/content expansion from a stronger production base.
