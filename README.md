# DON'T LOOK BACK — Godot v0.21

First-person survival horror prototype for Godot 4.x with desktop + responsive mobile controls, LAN co-op, host-authoritative horror AI, persistent saves, survival systems, Journal progression, separate Labyrinth/Forest maps, runtime AStar navigation, adaptive encounter pacing, dynamic Labyrinth routes, co-op interactions, and a full Arc 1 evacuation finale.

## v0.21 — LABYRINTH EVACUATION & LIVING MAZE

v0.21 turns the end of Arc 1 into a reverse-route escape instead of ending directly beside the Lockdown Console.

### Current Arc 1 route

1. Opening Corridor + Apartment 03
2. Original Labyrinth — restore 3 emergency relays
3. M-01 Maintenance — restore Fuse A/B/C
4. F-02 Flooded Service — turn Pressure Valve A/B
5. A-03 Archive — breaker sequence `B → A → C`
6. Isolation Sweep — disable the Maintenance, Flooded and Archive Isolation Nodes
7. Return to L-04 Lockdown
8. Survive the 120-second three-phase stabilization finale
9. **NEW: Evacuation Protocol starts**
10. Original L-04 Forest exit is removed
11. Restore the A-03 Emergency Override while moving backward
12. Restore the F-02 Extraction Override
13. Return through Maintenance toward the Arc entrance
14. Reach the new M-01 extraction beacon
15. Transition to the separate Forest map

A first blind Arc 1 run is now expected to land roughly around **40–60 minutes**, depending on exploration, co-op coordination, optional SYNC stations, shortcut use, route variant, enemy pressure, failed Archive attempts and evacuation speed. Experienced runs can be much faster.

## Reverse evacuation finale

Lockdown completion no longer creates an immediate usable Forest transition.

`LabyrinthEvacuationSystem` suppresses the old `OutsideTransitionArc1` and `Arc1FinalBeacon` after Lockdown and starts a reverse-route escape through previously visited sectors.

Base evacuation pressure time is **150 seconds**.

The timer is a pressure target, not an instant-death timer:

- above 0 seconds — standard evacuation pressure
- at 0 seconds — state becomes `EVACUATION CRITICAL`
- the run remains completable
- The Warden becomes faster and detects survivors from farther away
- horror-event cadence becomes more aggressive

This avoids a hard softlock while still making slow evacuation dangerous.

## Emergency Overrides

Two mandatory reverse-route controls are added:

- **A-03 Emergency Override** near the deep Archive return route
- **F-02 Extraction Override** in Flooded Service

Each override:

- uses normal E / USE interaction
- is host-validated in co-op
- adds **18 seconds** to remaining evacuation pressure time
- produces a loud AI-noise event
- autosaves progress
- persists through Continue

After both overrides are restored, the extraction beacon is armed near the M-01 / lower-Labyrinth entrance.

The old final exit at L-04 remains unavailable.

## Evacuation Warden

v0.21 adds a dedicated evacuation instance of **The Warden**.

The old v0.20 Warden remains responsible for Isolation Sweep / Lockdown behavior. During reverse evacuation the original instance is suppressed and only `EvacuationWarden` runs, preventing double-Warden encounters.

Evacuation Warden behavior:

- spawns from the Lockdown end of the map
- uses the existing runtime AStar graph
- follows survivors backward through the Arc
- prioritizes separated survivors in online co-op
- slows near genuine protective world lights
- does not treat flashlight-only state as a full safe pocket
- becomes faster in `EVACUATION CRITICAL`
- movement, attack and transform replication remain host-authoritative

The dedicated evacuation Warden inherits the existing Warden attack, target selection, safe-light reaction and network interpolation behavior.

## Living-maze pressure events

As evacuation time crosses pressure thresholds, the Labyrinth can create temporary emergency shutters.

Pressure thresholds are based around:

- 120 seconds
- 90 seconds
- 60 seconds
- 30 seconds
- critical state

Shutters only remain for roughly **4.5 seconds** and remove themselves automatically. They are designed as route-pressure moments, not permanent gates, so missing a route window cannot permanently softlock the Arc.

Each structural shift also creates AI noise and can accelerate a nearby horror event.

## Evacuation lighting

Ten additional reverse-route emergency strobes are added from Lockdown back toward Maintenance.

They are deliberately kept below the normal protective-world-light threshold:

- emergency orange/red color language
- pulsing intensity
- shadows disabled
- mobile-conscious realtime-light budget
- directional `EVAC` world labels

The final M-01 extraction beacon is intentionally much stronger and visually distinct once both overrides are restored.

## v0.20 systems retained

### Isolation Sweep

After Archive power is restored, Lockdown remains sealed until three Isolation Nodes are disabled:

- M-01 Isolation Node
- F-02 Isolation Node
- A-03 Isolation Node

There are three saved route variants. The selected variant persists in the Arc save so Continue and reconnect do not move objectives.

Isolation shutdowns trigger fault lighting, AI noise and short temporary shutters.

### Three-phase Lockdown

The 120-second Lockdown finale remains split into three pressure phases:

- Phase 1: 120–80 seconds
- Phase 2: 80–40 seconds
- Phase 3: final 40 seconds

Warden and environmental pressure increase toward the end.

## v0.19.x systems retained

### Encounter Director

Mourner/Crawler enemies use an adaptive threat budget rather than all remaining active continuously.

The Director considers:

- Arc stage
- active Tenant / Darkness pressure
- survivor health/downed state
- time spent in the lower Labyrinth
- team-separation pacing hooks

Random horror events include fake footsteps, metal slams, flicker, blackout and fake shadows.

### Environmental hazards

Arc 1 retains:

- Maintenance steam hazard
- Flooded Service electrified puddles
- Flooded Service steam hazard
- Archive steam hazard

Hazard damage remains host-authoritative online.

### Sector readability

Lower-Labyrinth navigation language:

- M-01 Maintenance — dirty yellow
- F-02 Flooded Service — desaturated blue
- A-03 Archive — industrial green
- L-04 Lockdown — emergency red

Optional exploration bays:

- M-07 Storage
- F-09 Pump Annex
- A-12 Records Annex

Two one-way service shortcuts reduce later backtracking after they are opened from the deeper side.

### Co-op SYNC stations

Maintenance, Flooded and Archive contain optional paired SYNC A/B stations.

Online:

- different survivors must use paired terminals inside a 9-second window

Solo:

- the same player can complete both sides within an 18-second window

Successful SYNC provides a temporary protective team-light pocket and finite shared reward.

## Multiplayer authority

LAN/IP multiplayer supports 2–4 survivors.

Host owns authoritative state for:

- Arc objectives
- Isolation Nodes
- evacuation overrides
- evacuation completion
- Warden / Arc enemy movement and attacks
- hazards
- shared finite pickups
- shared checkpoints
- map transition

Evacuation state uses reliable RPC channel 16. Warden movement keeps its existing dedicated replication path.

Late joiners receive the current evacuation snapshot.

## Save / Continue

Arc persistence includes:

- Fuse/Valve/Breaker state
- Isolation Sweep state
- saved route variant
- Lockdown state/time
- SYNC milestones
- one-way shortcuts
- finite claimed pickups
- evacuation started/completed state
- evacuation remaining pressure time
- completed evacuation overrides

The v0.21 evacuation data is stored inside the existing Arc `completed` state and does not require a new save-format migration.

`NEW GAME` clears the Arc state normally.

## Controls

Desktop:

- WASD — move / downed crawl
- Mouse — look
- Shift — sprint
- Space — jump
- E — interact / objective / override / shortcut / revive
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
- USE — interact / objective / override / shortcut / revive
- LIGHT
- BATT
- FOOD
- WATER
- MED
- JOURNAL
- MENU

## Recommended v0.21 runtime test

Solo full route:

1. Run with embedded Game View disabled if the editor still fails to forward input.
2. NEW GAME.
3. Complete 3 relays.
4. Complete Fuse A/B/C.
5. Complete Valve A/B.
6. Complete Archive sequence B → A → C.
7. Verify Lockdown is blocked until all 3 Isolation Nodes are disabled.
8. Complete Isolation Sweep.
9. Start Lockdown and survive all three phases.
10. Confirm the old L-04 Forest exit does **not** remain usable.
11. Confirm evacuation HUD starts near 2:30.
12. Move backward to A-03 Emergency Override and activate it.
13. Confirm roughly +18 seconds and autosave feedback.
14. Continue backward to F-02 Extraction Override and activate it.
15. Confirm M-01 extraction is armed.
16. Observe emergency strobes and temporary shutters while moving back.
17. Let the timer reach zero once and verify the game becomes CRITICAL rather than instantly killing/restarting.
18. Confirm Evacuation Warden continues pursuing in CRITICAL state.
19. Reach M-01 extraction beacon.
20. Confirm Forest transition occurs.

Save regression:

1. Save after the first evacuation override.
2. Quit to desktop.
3. CONTINUE.
4. Confirm Lockdown remains complete, evacuation resumes, first override remains restored, remaining pressure time restores, and the old L-04 exit is still suppressed.

Co-op:

1. Host + client complete Lockdown.
2. Confirm both receive evacuation state.
3. Let client activate A-03 override; host must validate it.
4. Verify both peers see the override complete.
5. Split the team and confirm Warden target pressure remains host-authoritative.
6. Reconnect a client during evacuation and verify state snapshot.
7. Let a client enter the M-01 extraction after both overrides; host should validate extraction and transition the session.

## Performance intent

v0.21 remains mobile-conscious:

- emergency strobes use low-energy OmniLights with shadows disabled
- route labels are lightweight Label3D nodes
- evacuation uses one dedicated Warden rather than stacking another full encounter set
- stage-6 Encounter Director budget already clears regular Mourner/Crawler pressure, leaving Warden as the main chase threat
- temporary shutters use primitive geometry and self-delete
- no volumetric evacuation effects are required for gameplay

## Git workflow note

`project.godot` is intentionally not modified for v0.21.

New runtime systems are created through the existing `Arc1NavigationBridge`. The in-menu build badge reads:

`v0.21 • LABYRINTH EVACUATION & LIVING MAZE`

The development machine should keep using a clean/stashed working tree before Pull. Do not discard unknown local `project.godot` changes without backing them up first.

## Current limitations

- Godot runtime/F5 validation must still be performed on the development machine; the assistant environment does not contain the Godot executable.
- Current environment geometry, override panels, evacuation shutters and Warden visuals remain procedural prototype art.
- AI navigation is still a hand-authored runtime AStar waypoint graph rather than baked NavigationMesh.
- Internet matchmaking/NAT traversal is not implemented; multiplayer remains LAN/IP based.
- Production audio, animation, VFX and environment art are still required.

See `ASSET_BACKLOG.md` for the current production-asset requirements.
