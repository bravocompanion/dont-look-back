# DON'T LOOK BACK — Godot v0.15

A first-person survival-horror prototype for Godot 4.x with desktop controls, responsive mobile touch controls, LAN co-op, host-authoritative horror encounters, persistent world saves, journal discoveries, and survival crafting.

## v0.15 — Multiplayer Polish

v0.15 turns the existing LAN foundation into a more deliberate co-op session flow. `MultiplayerPolishSystem` sits on top of the existing `NetworkManager` and `CoopHorrorSystem`, so the host-authoritative monsters, shared loot, world state, mobile controls, and v0.14 save system remain intact.

### Survivor names

Each device now has a local co-op profile stored at:

`user://dont_look_back_coop_profile.cfg`

The profile remembers:
- survivor display name
- last non-localhost LAN host address

Names are synchronized through the host and appear in the session roster, teammate HUD, remote survivor labels, and revive prompts.

### Ready / Start flow

Hosting or joining no longer immediately gives full movement control.

The pre-game flow is:
1. HOST creates the LAN session.
2. Other devices JOIN using the host LAN IPv4.
3. Each player enters a survivor name.
4. Every connected survivor presses READY.
5. The HOST presses START.
6. Clients are grouped near the host and normal gameplay begins.

START requires at least two connected survivors and every current survivor to be READY.

This flow uses the existing Godot ENet session; it does not create a separate scene or replace the current world-save state.

### Late join / session recovery

If a survivor joins a session that has already started, the host sends the active session state and places the reconnecting/late-joining survivor near the host.

If a client loses the host connection:
- the last LAN address is retained locally
- v0.15 makes one automatic reconnect attempt after a short delay
- if that fails, a RECONNECT button remains available

This is basic LAN session recovery, not account-based internet reconnect or NAT traversal.

### Ping / connection status

Clients periodically measure round-trip latency to the host.

The co-op session UI displays a local ping estimate in milliseconds. Host profile data also receives the latest client-reported ping through the normal profile synchronization pass.

### Teammate HUD

During an active co-op session, a responsive TEAM panel shows:
- survivor names
- local-player marker
- Health
- DOWNED state
- current team objective derived from the synchronized world/Journal mission state

Remote survivor world labels now use player names instead of only peer IDs.

### Shared checkpoint authority

Checkpoint progress is now coordinated through the host.

When any survivor activates a new checkpoint:
- that checkpoint request reaches the host
- the host accepts it as the current team checkpoint
- every peer saves its own local survival snapshot at the same shared checkpoint position
- the host's normal v0.14 autosave writes the authoritative world progress to disk

This preserves per-survivor Health/Inventory snapshots while keeping the co-op respawn location synchronized.

A checkpoint already restored from the host v0.14 world save is also sent to peers when the co-op session starts or when a survivor joins an active session.

### Revive progress UI

Interacting with a DOWNED teammate now opens a revive progress bar.

The bar tracks the local revive attempt while:
- the target remains DOWNED
- the reviver remains within the allowed revive distance
- the reviver remains standing

The UI does not determine the outcome. Completion/cancellation remains host-authoritative through `CoopHorrorSystem`.

### Downed crawling

A DOWNED survivor is no longer completely immobile.

While downed in an active co-op session:
- WASD or the mobile joystick allows slow crawling
- mouse look or mobile swipe-look remains available
- the camera is lowered to a downed viewpoint
- sprint and normal player interactions remain unavailable through the disabled normal player controller
- revive is still required to return to standing gameplay

The current prototype keeps the normal player collision capsule; a final crawl pose/collision/animation pass belongs to the asset integration stage.

## Persistent World retained from v0.14

The world save remains stored at:

`user://dont_look_back_save_v1.json`

Desktop:
- K — Save World
- L — Load World while offline

Mobile:
- SAVE — Save World
- LOAD — Load World while offline

Persistent data includes:
- player position/yaw
- Health/Hunger/Thirst/Stamina
- flashlight battery/state
- Darkness Exposure
- inventory
- Bleeding/Infection/Cold
- relay progress
- labyrinth door state
- checkpoint state
- day/time
- generator/campfire fuel
- shelter storage
- finite claimed loot
- Journal entries/order

A connected client cannot write the authoritative host world save. Manual Load remains disabled while a co-op session is active.

## Journal + Door Safety retained from v0.13.1

Journal:
- J on desktop
- JOURNAL on mobile
- current mission
- tips
- mission notes
- logs
- trivia
- warnings
- persistent discoveries through v0.14 saves

Door safety:
- moving-door collision is disabled before rotation
- the script waits for a physics frame before movement
- collision returns after motion
- closing collision waits until the local player clears the dangerous hinge area

## Survival Depth retained from v0.13

- Bleeding from large hits
- Infection from wounds / unsafe water
- Cloth
- Bandage crafting
- Dirty Water
- Clean Water priority
- boiling pot beside the shelter campfire
- Medical Aid using Bandage before Medkit when appropriate

Workbench recipes:
- 2 Wood → Firewood Bundle
- 1 Wood + 2 Scrap → Flashlight Battery
- 2 Cloth → Bandage

## Exterior retained from v0.12

- Abandoned House
- Old Gas Station
- Warehouse
- Old Water Pump
- deep forest loot route
- stronger night threat in the far exterior

## Co-op horror retained from v0.11

While LAN multiplayer is active:
- The Tenant is host-authoritative
- Darkness Creature is host-authoritative
- monsters can switch targets
- any standing survivor can freeze The Tenant by watching it
- nearby teammate light can repel the Darkness Creature
- lethal damage causes DOWNED
- teammates can revive
- all survivors downed triggers team wipe/reload

## Mobile gameplay

- Left virtual joystick — Move / downed crawl
- Right-side swipe — Camera look
- RUN — Sprint while standing
- USE — Interact / pick up / revive / pump / boil water
- LIGHT — Flashlight
- BATT — Replacement battery
- FOOD — Eat
- WATER — Drink Clean Water first, Dirty Water if necessary
- MED — Medical Aid
- JOURNAL — Mission / discoveries
- SAVE — Save host/solo world
- LOAD — Load while offline
- RESTART — Restart when available
- CO-OP — Host/Join lobby

The v0.15 session/roster/teammate/revive UI uses responsive layouts for narrow/mobile screens as well as desktop.

## Desktop controls

- W A S D — Move / downed crawl
- Mouse — Look
- Shift — Sprint while standing
- E — Interact / revive
- F — Flashlight
- B or 4 — Replace Flashlight Battery
- 1 — Food
- 2 — Water
- 3 — Medical Aid
- J — Journal
- K — Save World
- L — Load World while offline
- M — CO-OP lobby
- Esc — Release/capture mouse
- R — Death/checkpoint restart when available

## Testing v0.15

Recommended two-device LAN test:
1. Pull latest `main` on both devices.
2. Open the existing Godot project and press F5 on both.
3. Device A opens CO-OP and HOSTS.
4. Device B enters Device A's LAN IPv4 and JOINS.
5. Enter different survivor names.
6. Confirm both names appear in the roster.
7. Press READY on both devices.
8. Confirm only the host has START and that START unlocks only when everyone is ready.
9. Host presses START.
10. Confirm both players gain movement and the client is grouped near the host.
11. Confirm TEAM HUD shows both names and Health.
12. Take enough monster damage to DOWN one survivor.
13. Confirm the downed survivor can crawl slowly using desktop/mobile movement controls.
14. Other survivor uses E/USE on the downed teammate and confirms the revive progress bar appears.
15. Walk away during revive and confirm the progress UI cancels.
16. Complete a revive while staying close.
17. Reach a checkpoint with either survivor and confirm both devices receive TEAM CHECKPOINT.
18. Disconnect the client unexpectedly and confirm an automatic reconnect attempt occurs.
19. If automatic retry fails, use the RECONNECT control.
20. Confirm names/TEAM HUD return after reconnect.

## Asset backlog

Production asset requirements are tracked in `ASSET_BACKLOG.md` and must be updated as systems change.

Highest-priority assets after v0.15:
- rigged survivor model with 3–4 outfit/material variants
- downed crawl animations
- revive / being-revived animations
- The Tenant model + animation set
- Darkness Creature model + animation set
- footsteps and horror ambience
- revive/downed/lobby UI audio
- ready/host/ping/downed/revive UI icons
- labyrinth material/door art pass
- flashlight and survival pickup models

The current prototype still uses runtime primitives for many environment, survivor, monster, and prop visuals.

## Android/iOS export note

Generating APK/AAB or iOS builds still requires the appropriate Godot export templates and platform setup on the development machine.

For Android LAN multiplayer, enable INTERNET permission in the Android export preset.

## Update in Godot

If the repository is already cloned:
1. Open GitHub Desktop.
2. Select `bravocompanion/dont-look-back`.
3. If local changes would be overwritten, discard them only when you did not intentionally edit those files.
4. Fetch origin.
5. Pull origin.
6. Return to the existing Godot project.
7. Press F5.

## Current limitations

- Runtime Godot validation still needs to be performed on the development machine.
- Internet matchmaking/NAT traversal is not implemented.
- Reconnect recovery is LAN/basic and does not preserve an authenticated account identity.
- Remote client inventories are not persistent account/profile saves.
- Downed crawling still uses the standing collision capsule and has no final animation asset yet.
- Revive progress is a client-side visualization; the host remains authoritative for actual completion.
- Shared checkpoint requests are host-routed but do not yet include anti-cheat validation of the requested checkpoint location.
- Renewable water-pump cooldown is not persisted.
- Active monster transforms are not serialized into the disk save.
- Outdoor monsters still use direct movement rather than full Navigation/pathfinding through complex buildings.

## Next targets

- v0.15.1 — fixes from two-device Ready/Start/reconnect/crawl/revive testing
- v0.16 — Art & Audio Integration: survivor/monster models, downed/revive animations, footsteps, ambience, labyrinth/door materials, survival prop models
- v0.17 — front-end flow: New Game / Continue / Host / Join / Settings
- v0.18 — Navigation/pathfinding and outdoor AI search behavior
- Later — internet-session support and stronger client-profile persistence
