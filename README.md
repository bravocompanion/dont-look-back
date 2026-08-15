# DON'T LOOK BACK — Godot v0.17

A first-person survival-horror prototype for Godot 4.x with desktop + responsive mobile controls, LAN co-op, host-authoritative horror encounters, survival systems, persistent world saves, Journal discoveries, and a responsive front-end flow.

## v0.17 — Main Menu / Game Flow

v0.17 adds `FrontEndSystem` as the high-level entry point for the existing game systems. The gameplay scene remains the same; the front end runs as an autoload overlay so it can coordinate saves, co-op, settings, pause behavior, and mobile input without duplicating the world.

### Main menu

Available actions:
- CONTINUE
- NEW GAME
- HOST CO-OP
- JOIN CO-OP
- SETTINGS
- QUIT on desktop platforms

The title screen is responsive for desktop and narrow/mobile viewports.

### Continue

The existing v0.14 `SaveSystem` still restores a valid disk save during startup while the title overlay is covering the game world. After the short boot check, CONTINUE becomes available and displays a compact summary:
- Day
- world time
- latest checkpoint name

Selecting CONTINUE releases the player into the restored world.

If the save JSON is missing or invalid, CONTINUE remains disabled and the player can start a NEW GAME.

### New Game

NEW GAME now has a destructive confirmation when a persistent world exists.

Confirming it:
1. disconnects any active/connecting network peer
2. deletes the persistent world save
3. resets the runtime checkpoint, relay, shelter, exterior condition, survival-depth, Journal and claimed-loot state using the v0.14 reset path
4. reloads the scene
5. starts the opening corridor as a fresh run

### Host Co-op

HOST CO-OP calls the same `NetworkManager` used by v0.15.

If a persistent host world was restored during boot, hosting starts from that world. If no save exists, the current fresh world is used.

After HOST succeeds, the v0.15 session flow takes over:
- survivor name
- READY / NOT READY
- host START
- teammate HUD
- ping
- shared checkpoint
- downed/revive flow

### Join Co-op

JOIN CO-OP now has a direct LAN IPv4 entry screen on the main menu.

Flow:
1. select JOIN CO-OP
2. enter the host LAN IPv4, for example `192.168.1.10`
3. CONNECT
4. after connection, the v0.15 SESSION panel takes over
5. enter/confirm survivor name, READY, then wait for host START

The last host address from the v0.15 local co-op profile is reused when available.

### Pause / in-game menu

Desktop:
- `Esc` opens the menu during gameplay

Mobile:
- a responsive `MENU` button appears during gameplay

Pause menu actions:
- RESUME
- SAVE WORLD
- SETTINGS
- RETURN TO TITLE
- QUIT on desktop

Solo behavior:
- the SceneTree is paused while the menu is open

Co-op behavior:
- the local survivor is blocked, but the network world continues
- this prevents one client from pausing host-authoritative monsters for the entire team

RETURN TO TITLE disconnects the active co-op peer. A solo/host run can be resumed in memory from the title screen; a disconnected client does not gain an authoritative solo resume from the client world.

## v0.17 Settings

Settings are stored per device at:

`user://dont_look_back_settings.cfg`

Current settings:
- Master Volume: 0–100%
- Look Sensitivity: 0.50x–2.00x
- Performance/FPS limit: 30 / 60 / 120 FPS
- Fullscreen on supported desktop platforms

Look sensitivity applies to both mouse and mobile swipe-look.

The front end uses the runtime Godot APIs for master bus volume, FPS limit, and desktop window mode.

## Mobile input safety

`MobileControls` now separates two concepts:
- `dead_mode` for actual death/restart behavior
- `external_blocked` for menu/session overlays

This means opening the title/pause/session UI clears joystick/look/action state without pretending the player is dead. It also avoids queued touch actions firing immediately after closing a menu.

Touch gameplay remains available after the menu closes, and the existing v0.15 downed-crawl path remains separate from menu blocking.

## v0.15 Multiplayer Polish retained

LAN co-op target: 2–4 survivors.

Retained systems:
- player display names
- local co-op profile
- Ready / Not Ready
- Host START
- responsive session roster
- teammate HP / DOWNED HUD
- ping estimate
- reconnect attempt + RECONNECT control
- late-join session recovery foundation
- shared checkpoint authority
- revive progress UI
- slow downed crawling
- host-authoritative The Tenant
- host-authoritative Darkness Creature
- shared relays
- shared day/night state
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

Desktop manual save remains `K`; the v0.17 pause menu also exposes SAVE WORLD.

Connected clients cannot write the authoritative host world save. Manual disk Load remains an offline operation.

## Journal + Door Safety retained

Journal:
- `J` desktop
- `JOURNAL` mobile
- current mission
- tips
- mission notes
- logs
- trivia
- warnings
- persistent discoveries

Labyrinth door safety:
- moving collision disables before rotation
- waits one physics frame before motion
- collision returns after motion
- closing collision waits until the local player is clear of the hinge area

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
- boiling Dirty Water at the shelter campfire
- crafting at the shelter workbench
- shared storage chest

## Current world

Progression currently covers:
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

Desktop gameplay:
- WASD — move / downed crawl
- Mouse — look
- Shift — sprint while standing
- E — interact / revive
- F — flashlight
- B or 4 — battery
- 1 — food
- 2 — water
- 3 — medical aid
- J — Journal
- K — Save World
- L — Load World while offline
- M — legacy in-game co-op lobby
- Esc — v0.17 pause/menu

Mobile gameplay:
- left joystick — move / supported downed movement path
- right swipe — look
- RUN
- USE
- LIGHT
- BATT
- FOOD
- WATER
- MED
- JOURNAL
- SAVE / LOAD from existing v0.14 UI where available
- CO-OP legacy access
- MENU — v0.17 pause/front end

## Testing v0.17

Recommended desktop test:
1. Pull latest `main`.
2. Open the existing Godot project and press F5.
3. Confirm the title menu appears before movement is possible.
4. If a v0.14/v0.15 save exists, confirm CONTINUE shows Day / time / checkpoint.
5. CONTINUE and verify the restored world is playable.
6. Press Esc and verify the solo menu pauses the world.
7. Change volume, look sensitivity, FPS limit, and fullscreen; close/reopen Settings.
8. Restart the game and verify settings remain.
9. Press NEW GAME and verify the delete confirmation appears when a save exists.
10. Confirm NEW GAME starts the opening corridor with persistent progress reset.

Recommended co-op test:
1. Device A selects HOST CO-OP from the title.
2. Device B selects JOIN CO-OP and enters Device A's LAN IPv4.
3. Confirm v0.15 SESSION / name / READY / START appears after connection.
4. Confirm touch gameplay buttons remain blocked during the pre-game session on mobile.
5. START and verify movement/touch controls become available.
6. Open MENU on one client and verify the host world continues.
7. Resume and verify no stale touch action fires immediately.
8. Test downed/revive/shared checkpoint/reconnect from v0.15.

## Asset status

Production asset needs are tracked in `ASSET_BACKLOG.md` and updated for v0.17.

Highest-impact missing assets now:
- final DON'T LOOK BACK logo
- 16:9 + portrait-safe title key art
- menu/button visual states
- menu/connect/save UI SFX
- rigged survivor + downed/revive animations
- The Tenant final model/animations
- Darkness Creature final model/animations
- core footsteps + horror ambience
- labyrinth materials + production door art
- flashlight / survival pickup models

v0.17 is still placeholder-friendly. The skipped v0.16 production art/audio integration has not been falsely marked complete.

## Current limitations

- Runtime Godot validation must still be performed on the development machine; the assistant environment does not have the Godot executable.
- The main menu is functional but still uses text/primitive Godot styling instead of final art.
- Internet matchmaking / NAT traversal is not implemented; co-op is LAN/IP based.
- Client-specific inventory/profile persistence is not yet a full account/profile system.
- Active monster transforms are not serialized into disk saves mid-attack.
- Outdoor AI still lacks full Navigation/pathfinding through complex structures.
- Final survivor/monster animations, audio, VFX, and environment assets are still missing.

## Recommended next update

Before adding another large map, the strongest next step is an **Art + Audio Integration pass** using `ASSET_BACKLOG.md`, followed by AI Navigation/pathfinding and then story/content expansion.
