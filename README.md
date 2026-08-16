# DON'T LOOK BACK — Godot v0.19.3

First-person survival horror prototype for Godot 4.x with desktop + responsive mobile controls, LAN co-op, host-authoritative horror AI, persistent saves, survival systems, Journal progression, separate Labyrinth/Forest maps, runtime AI navigation, dynamic encounter pacing, and cooperative Labyrinth interactions.

## v0.19.3 — LABYRINTH CO-OP & TEAM TENSION

v0.19.3 makes multiplayer coordination affect the Labyrinth directly while keeping every Arc 1 objective fully completable offline/solo.

### Emergency sync stations

Three optional paired sync stations are now built into Arc 1:

- **M-01 Maintenance SYNC A/B**
- **F-02 Flooded Service SYNC A/B**
- **A-03 Archive SYNC A/B**

Online behavior:

- one survivor arms SYNC A or B
- a different survivor must reach the paired panel within 9 seconds
- the host validates that each survivor is physically close enough to the correct panel
- the same online survivor cannot satisfy both sides

Solo behavior:

- the same player may use both panels
- the solo window is 18 seconds to allow traversal between the separated panels
- these stations are optional and never block Fuse/Valve/Breaker/Lockdown progression

Successful synchronization provides:

- a **36-second emergency protective light pocket**
- temporary breathing room from encounter/horror-event rotations
- one finite team reward: Battery in Maintenance, Water in Flooded Service, Medkit in Archive
- an autosave of the completed sync milestone

The support light is intentionally stronger than normal dim Labyrinth lamps and acts as a real regroup/safe-light pocket. It expires automatically.

### Team tension

Co-op separation now feeds back into horror pacing.

When active survivors spread roughly 18 meters or more apart, the Labyrinth runtime shortens the next encounter/horror-event timers. Staying coordinated does not remove horror, but splitting the team for too long can make the maze respond faster.

While an emergency sync light is active, encounter/horror timers receive a short respite instead. This creates a simple risk/reward loop:

- split up to reach objectives or loot faster
- accept higher encounter pressure while separated
- coordinate a sync station to create a short regroup window

The existing v0.19.1 threat budget still controls which Mourner/Crawler subset is active, so team tension accelerates pacing without forcing every monster active simultaneously.

### Multiplayer authority

The host owns:

- sync-panel validation
- paired-panel timing window
- station completion
- support-light remaining time
- team reward creation
- team-separation pressure timing

Clients receive station progress and support-light state through reliable channel 13. Late joiners receive a state snapshot.

Sync station completion is stored inside the existing Arc 1 `completed` dictionary using dedicated `coop_sync_*` keys. Therefore existing v0.19 save persistence handles these milestones without adding another save-format migration. NEW GAME clears them together with the Arc.

### Performance

The co-op pass remains mobile-conscious:

- six small panel props use primitive geometry
- panel indicator OmniLights remain below protective-light intensity
- only the three temporary support lights become strong protective lights
- support lights have shadows disabled
- no extra navigation mesh or physics simulation is added
- the system is bootstrapped through the existing Arc1 runtime bridge, so `project.godot` is not modified

### Testing v0.19.3

Solo:

1. Reach Maintenance and find M-01 SYNC A/B.
2. Activate one panel and reach the paired panel within 18 seconds.
3. Confirm the support light appears and the Battery reward becomes available.
4. Confirm missing the window resets the pair without blocking the normal Fuse route.
5. Repeat in Flooded Service and Archive.
6. Save after completing a sync station, quit, CONTINUE, and confirm the station remains completed.
7. Confirm the temporary support light itself is not treated as a permanent save reward.

Co-op:

1. Host + client reach M-01.
2. Host arms A; client activates B within 9 seconds.
3. Verify both peers see the same completed panel state and support light.
4. Verify one player cannot activate both sides while online.
5. Move the team more than roughly 18 meters apart and observe faster encounter/horror pressure over time.
6. Regroup inside the emergency support-light pocket and verify a short pacing respite.
7. Complete a station as client and confirm host validation, autosave, and shared finite reward.
8. Late join/reconnect after completion and confirm the completed station state is retained.

## v0.19.2 — LABYRINTH READABILITY & EXPLORATION

v0.19.2 builds on the 30–45 minute Arc 1 route from v0.19/v0.19.1. The goal is to make the Labyrinth difficult to navigate without making it visually meaningless.

### Sector identity

The lower Labyrinth now has a consistent visual navigation language:

- **M-01 Maintenance Wing** — yellow route markers
- **F-02 Flooded Service** — blue route markers
- **A-03 Archive** — green route markers
- **L-04 Lockdown** — red route markers

A pipe-color legend appears near the Arc 1 entrance. Each sector has a large world-space sign, repeated colored route markers, and a distinct landmark pillar. These are deliberately emissive geometry rather than extra realtime lights, so readability improves without turning the Labyrinth into a safe zone or adding unnecessary mobile lighting cost.

### Optional exploration bays

Three optional side areas are added:

- `M-07 STORAGE`
- `F-09 PUMP ANNEX`
- `A-12 RECORDS ANNEX`

They are not required for Arc completion. They reward players who explore with finite shared supplies such as flashlight batteries, Bandage, Bottled Water, Cloth, and Medkit.

Optional cache pickups use the existing persistent claimed-pickup system, so collected supplies do not reappear after save/load.

### Secret Journal finds

Two additional optional Journal entries are placed in exploration areas:

- **Maintenance Color Code** — explains the yellow/blue/green/red navigation language in-world
- **Margin Note in Box A-12** — optional Archive trivia/lore

Journal discoveries remain local per survivor while shared physical supplies remain host-authoritative.

### One-way service shortcuts

Two backtracking shortcuts are added:

- Maintenance service shortcut
- Flooded Service pump shortcut

The shortcut replaces a small section of an existing zig-zag wall with a locked service door. It cannot be opened from the early side. A survivor must first reach the deeper side of the sector, then use **E / USE** to release the latch.

This preserves the first traversal and objective pacing while reducing repetitive backtracking later in the Arc.

Shortcut state is validated by the host in co-op, synchronized to clients, persisted in the world save, reset by NEW GAME, and followed by an AI-navigation graph rebuild after the collision disappears.

### Arc 1 route

1. Opening Corridor + Apartment 03
2. Original Labyrinth — restore 3 emergency relays
3. M-01 Maintenance — restore Fuse A/B/C
4. F-02 Flooded Service — turn both pressure valves
5. A-03 Archive — breaker sequence `B → A → C`
6. L-04 Lockdown — start final console
7. Survive the 2-minute stabilization holdout
8. Final beacon appears
9. Load the separate `forest.tscn` map

The first blind-run target remains roughly **30–45 minutes**, depending on exploration, resource detours, co-op coordination, failed breaker attempts, and enemy pressure. There is no artificial 30-minute timer wall.

## Retained Labyrinth systems

v0.19.3 retains:

- The Tenant freeze-when-watched rule
- Darkness Creature light retreat
- two Mourner + two Crawler Arc enemy instances
- adaptive Encounter Director
- fake footsteps, metal slam, shadow, flicker, and blackout horror events
- steam hazards and electrified puddles
- 19+ lower-Labyrinth dim lights plus older-maze maintenance lights
- M/F/A/L sector readability language
- M-07 / F-09 / A-12 optional exploration bays
- two one-way service shortcuts
- persistent finite loot
- Journal mission tracking and secret notes
- Fuse → Valve → Breaker → Lockdown objective chain
- 2-minute final stabilization holdout
- separate Forest map transition
- host-authoritative multiplayer, downed/revive/crawl, and shared checkpoints

## Controls

Desktop:

- WASD — move / downed crawl
- Mouse — look
- Shift — sprint
- Space — jump
- E — interact / objective / shortcut / SYNC panel / revive
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

- left joystick — movement
- right swipe — look
- RUN
- JUMP
- USE — interaction / objective / shortcut / SYNC panel / revive
- LIGHT
- BATT
- FOOD
- WATER
- MED
- JOURNAL
- MENU

## Current limitations

- Runtime F5 validation must still be performed on the development machine; the assistant environment does not contain the Godot executable.
- Sync panels and emergency-light fixtures are prototype primitive art.
- Final co-op panel audio, panel animations, cables, warning decals, and support-light fixtures are not yet production assets.
- World-space signage and panel placement may need small tuning after production wall/prop assets replace procedural geometry.
- AI navigation remains a runtime AStar waypoint graph rather than a baked NavigationMesh.
- Internet matchmaking/NAT traversal is not implemented; multiplayer remains LAN/IP based.

## Git workflow note

`project.godot` is intentionally **not modified for v0.19.3**. `Arc1NavigationBridge`, already autoloaded from v0.19, creates the Encounter Director, Exploration System, and new Labyrinth Co-op System at runtime. This reduces the chance of another local `project.godot` Pull conflict.

See `ASSET_BACKLOG.md` for current production-asset requirements.
