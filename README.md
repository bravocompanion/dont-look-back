# DON'T LOOK BACK — Godot v0.19.2

First-person survival horror prototype for Godot 4.x with desktop + responsive mobile controls, LAN co-op, host-authoritative horror AI, persistent saves, survival systems, Journal progression, separate Labyrinth/Forest maps, runtime AI navigation, and dynamic Forest sun/moon lighting.

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

Shortcut state is:

- validated by the host in co-op
- synchronized to clients
- persisted in the world save
- reset by NEW GAME
- followed by an AI-navigation graph rebuild after the collision disappears

### v0.19.1 Encounter Director retained

Arc enemies are controlled by an adaptive threat budget rather than remaining active all at once.

Internal pacing states:

- CALM
- UNEASY
- DANGER
- SEVERE
- LOCKDOWN

The budget considers Arc stage, The Tenant/Darkness pressure, survivor health/downed state, and time spent in the lower Labyrinth.

Random horror events remain active:

- distant metal slam
- fake footsteps/noise
- light flicker
- brief blackout
- fake shadow crossing

Timed hazards remain active:

- Maintenance steam burst
- Flooded Service electrified puddles
- Flooded Service steam burst
- Archive steam burst

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

## Enemies

Arc 1 currently combines:

- **The Tenant** — freezes while watched and moves when unseen
- **Darkness Creature** — darkness/light pressure
- **The Mourner x2** — noise-oriented stalkers slowed by protective light
- **The Crawler x2** — faster low-profile pressure that avoids strongly protected survivors

Mourner/Crawler movement and damage are host-authoritative during multiplayer. The Encounter Director chooses the active subset.

## Lighting

The Labyrinth remains intentionally dark but readable:

- original maze has additional dim maintenance fixtures
- lower Labyrinth has 19 dim maintenance lights
- normal ambient lamps remain below the protective-light threshold
- two stronger safe/checkpoint lamps provide intentional regroup pockets
- v0.19.2 route colors are emissive navigation geometry, not protective lights
- breaker faults and horror events can still reduce/flicker maintenance lighting

## Save / Continue

Persistent state now includes:

- player survival/inventory state
- Arc objective progress
- Lockdown state/time
- Arc checkpoints
- claimed finite pickups
- **v0.19.2 shortcut unlock state**

`NEW GAME` clears Arc and exploration shortcut progress.

## Multiplayer

LAN/IP multiplayer retains:

- 2–4 survivors
- Host/Join + Ready/Start
- host-authoritative monsters and Arc objectives
- shared pickups
- shared checkpoints
- downed/crawl/revive
- teammate HUD and ping
- reconnect foundation
- synchronized Arc encounter pacing
- synchronized shortcut state

Shortcut interaction from a client is sent to the host. The host validates that the survivor has actually reached the correct side before unlocking it.

## Controls

Desktop:

- WASD — move / downed crawl
- Mouse — look
- Shift — sprint
- Space — jump
- E — interact / objective / shortcut / revive
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
- USE — interaction/objective/shortcut/revive
- LIGHT
- BATT
- FOOD
- WATER
- MED
- JOURNAL
- MENU

## Testing v0.19.2

Recommended solo regression route:

1. Run with Godot embedded-game mode disabled if the editor Game View still fails to forward input on the development PC.
2. NEW GAME and reach Lower Labyrinth.
3. Verify the entrance legend and M/F/A/L sector signage are visible but do not illuminate the corridor like a safe light.
4. Follow yellow Maintenance markers and enter M-07 Storage; collect one cache item.
5. Reach the far side of the Maintenance shortcut. From the early side it must say locked from the other side; from the deep side E/USE should open it.
6. Return through the opened shortcut and confirm movement + AI navigation do not collide with an invisible door.
7. Repeat with the Flooded Service shortcut.
8. Find F-09 and A-12 optional cache areas.
9. Read both optional Journal entries.
10. Save after unlocking a shortcut, quit, CONTINUE, and confirm the shortcut remains open and collected cache items do not respawn.
11. Confirm the normal Fuse → Valve → Breaker → Lockdown route still works.

Recommended co-op checks:

1. Host + client reach Maintenance.
2. Client attempts the shortcut from the wrong side; it must remain locked.
3. Client reaches the deeper side and unlocks it; host and client should both see the door disappear.
4. Reconnect a client and confirm shortcut state is restored from host.
5. Verify optional supply pickup is still claimed only once for the shared world.
6. Confirm Encounter Director enemy activation remains synchronized while using shortcut routes.

## Current limitations

- Runtime F5 validation must still be performed on the development machine; the assistant environment does not contain the Godot executable.
- Sector signage, colored conduit, optional bays, shortcut doors, and cache dressing are prototype procedural/primitive art.
- World-space signs may require final placement/orientation tuning after visual testing with production wall assets.
- AI navigation remains a runtime AStar waypoint graph rather than a baked NavigationMesh.
- Internet matchmaking/NAT traversal is not implemented; multiplayer remains LAN/IP based.
- Production models, animation, spatial audio, environment modules, VFX, and final UI art are still required.

## Git workflow note

`project.godot` is intentionally **not modified for v0.19.2**. `Arc1NavigationBridge`, already autoloaded from v0.19, now creates both `LabyrinthEncounterDirector` and `LabyrinthExplorationSystem` at runtime. This reduces the chance of another local `project.godot` Pull conflict.

See `ASSET_BACKLOG.md` for the current production-asset requirements.
