# DON'T LOOK BACK — Godot v0.18.1

A first-person survival-horror prototype for Godot 4.x with desktop + responsive mobile controls, LAN co-op, host-authoritative horror encounters, survival systems, persistent world saves, Journal discoveries, responsive menus, runtime AI navigation/perception, and separate Labyrinth/Forest maps.

## v0.18.1 — Labyrinth Lighting + Separate Forest Map

### Labyrinth visibility pass

The expanded labyrinth is still intentionally dark, but it is no longer meant to be unreadable without staring only at the flashlight cone.

v0.18.1:
- raises the four existing maze ambience lights slightly
- increases their range so walls/corners remain faintly readable
- adds four additional low-energy cold ambience lights at deeper maze turns
- keeps all new ambience below the player's protective-light threshold
- keeps relay lights as the meaningful safe/high-power light sources

The result should be dim blue-gray visibility rather than pitch-black geometry. The flashlight is still important and Darkness Exposure remains dangerous.

### Labyrinth and Forest are now different scenes

Map files:
- `res://scenes/main.tscn` — opening corridor, Apartment 03 and Labyrinth
- `res://scenes/forest.tscn` — The Outside, cabin, forest and exterior landmarks

`OutsideDirector` no longer builds the exterior inside the Labyrinth scene. `LabyrinthDirector` no longer builds labyrinth geometry inside the Forest scene.

This reduces the amount of unrelated world geometry active in one scene and gives future maps a cleaner loading boundary.

### Loading transition

Leaving the final labyrinth gate now uses `MapTransitionSystem`.

Flow:
1. player reaches the final Outside transition after all 3 relays are active
2. controls are locked
3. a full-screen `THE OUTSIDE` loading overlay appears
4. the Labyrinth scene is replaced by `forest.tscn`
5. runtime Forest geometry is allowed to initialize
6. player Health/Hunger/Thirst/Stamina, inventory, flashlight/battery, Darkness Exposure, Bleeding and Infection are restored
7. player is placed at the Forest entrance
8. a new `Forest entrance` checkpoint is created and autosaved
9. controls are restored

A collision boundary now closes the back edge of the Forest entrance so the player cannot walk behind the newly separated map and fall off the ground.

### Co-op map synchronization

Map changes remain host-authoritative.

When the active party leaves the labyrinth:
- HOST sends the Forest transition to every connected peer
- every survivor loads `forest.tscn`
- each survivor preserves their own current local survival/inventory state during the scene swap
- monster/world authority continues to live on the host

Late join also receives the host's active map. If the host is already in Forest, a joining client loads Forest before continuing the v0.15 Ready/Start flow. If the host is still in Labyrinth while a client has a local Forest save loaded in the background, that client is synchronized back to the Labyrinth map for the session.

### Save/Continue across maps

The v0.18.1 SaveSystem wrapper adds the active scene path to new saves.

Continue/Load can now select the correct scene before applying the saved player/world state.

Older v0.14–v0.18 saves are migrated without deleting them:
- player positions at `z <= -52` are interpreted as Forest saves
- earlier positions are interpreted as Labyrinth saves

Finite pickup persistence is also normalized to scene-relative keys so older Outside pickup paths created under `/root/Main/OutsideWorld/...` continue to match the new `/root/ForestMap/OutsideWorld/...` structure.

`NEW GAME` always returns to `main.tscn`, even if the title screen was opened while the current run was in Forest.

## v0.18 — AI + Navigation retained

Monster movement uses a lightweight runtime `AStar3D` waypoint graph with four perception states:
- `CHASE`
- `INVESTIGATE`
- `SEARCH`
- `PATROL`

The graph is now map-aware. Labyrinth loads only corridor/labyrinth navigation points; Forest loads only exterior navigation points. The rebuild guard waits for the active map's runtime geometry before rebuilding.

The Tenant retains its signature rule: watching it freezes pursuit movement. Darkness Creature still retreats from protective light. Walk/sprint movement and noisy interactions continue to generate host-authoritative AI hearing events.

## Front End / Save / Multiplayer retained

Main menu:
- CONTINUE
- NEW GAME
- HOST CO-OP
- JOIN CO-OP
- SETTINGS
- QUIT on desktop

Desktop pause: `Esc`.
Mobile pause: `MENU`.

Persistent world save:
`user://dont_look_back_save_v1.json`

Local settings:
`user://dont_look_back_settings.cfg`

LAN co-op target remains 2–4 survivors with:
- display names
- Ready / Not Ready
- Host START
- teammate Health / DOWNED HUD
- ping/reconnect foundation
- shared checkpoint authority
- downed crawling and revive progress
- host-authoritative monster state/damage
- shared relays/day-night/shelter state
- shared finite survival pickups

## Survival / Journal retained

Stats:
- Health
- Hunger
- Thirst
- Stamina
- Flashlight Battery
- Darkness Exposure
- Cold Exposure
- Bleeding
- Infection

Resources include Food, Clean/Dirty Water, Medkit, Cloth, Bandage, Wood, Scrap, Fuel Can, Flashlight Battery and Firewood Bundle.

Journal:
- `J` desktop
- `JOURNAL` mobile
- missions, tips, logs, trivia and warnings
- persistent discoveries

## Controls

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
- left joystick — move / downed movement
- right swipe — look
- RUN / USE / LIGHT / BATT / FOOD / WATER / MED
- JOURNAL
- MENU

No new gameplay button is required for the map transition.

## Testing v0.18.1

Solo recommended test:
1. Start a NEW GAME and reach the expanded labyrinth.
2. Verify maze walls and turns are faintly visible without making the area feel bright.
3. Stand under a dim ambience light and verify Darkness Exposure still behaves as unsafe darkness; relay/high-power lights should remain the meaningful protection.
4. Activate Relay A/B/C and pass the final gate.
5. Confirm the loading overlay appears and the game changes to `forest.tscn`.
6. Verify Health, Hunger, Thirst, Stamina, inventory, flashlight battery and conditions survive the transition.
7. Verify the player spawns around `(0, 0.92, -57.5)` and cannot walk behind the Forest entrance edge.
8. Save in Forest, quit, restart and CONTINUE; the game should restore directly into Forest rather than putting a Forest coordinate inside the Labyrinth scene.
9. Use NEW GAME from a Forest run/title state and verify it returns to the opening Labyrinth map.
10. Re-test Darkness Creature navigation in House/Warehouse after the split.

Co-op recommended test:
1. HOST + JOIN in Labyrinth and START normally.
2. Activate all relays and have either survivor enter the final transition.
3. Confirm both devices display loading and arrive in Forest together.
4. Verify survivor inventory/stats remain correct on both devices.
5. Disconnect/rejoin a client while HOST remains in Forest; the joining client should synchronize to Forest.
6. Test a HOST in Labyrinth against a client whose local disk save would normally restore Forest; the client should synchronize to the host's Labyrinth scene for that session.
7. Re-test shared pickups, checkpoint, downed/revive, AI hearing and mobile controls.

## Asset status after v0.18.1

Production requirements are tracked in `ASSET_BACKLOG.md`.

Newly important assets from this patch:
- low-power labyrinth emergency/maintenance light fixture model
- emissive/flicker variants for dim maze lighting
- Forest entrance barrier/tree-line replacement for the current collision placeholder
- `THE OUTSIDE` loading-screen/key-art plate, center-safe for desktop and mobile
- loading transition ambience/stinger
- optional map-name icon/treatment for future multi-map loading screens

Existing high-priority needs remain final survivor/Tenant/Darkness models and animation, surface footsteps, monster audio, labyrinth material kit, production doors, forest vegetation and landmark props.

## Current limitations

- Runtime Godot validation must still be performed on the development machine; the assistant environment does not contain the Godot executable.
- Loading currently uses a functional Godot UI overlay rather than final branded loading artwork.
- Forest entrance boundary is a procedural placeholder and should become believable terrain/tree/fence art later.
- Navigation remains a hand-authored runtime waypoint graph rather than a fully baked NavigationMesh.
- Internet matchmaking/NAT traversal is not implemented; co-op remains LAN/IP based.
- Final character models, animations, production audio, VFX and environment art are still missing.

## Recommended next update

After validating v0.18.1, the strongest next milestone remains **Art + Audio / AI Presentation Integration**: production labyrinth lighting fixtures/materials, real footsteps and spatial monster audio, final monster/survivor animation states, then a branded loading/front-end pass before another large story map.
