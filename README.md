# DON'T LOOK BACK — Godot v0.20

First-person survival horror for Godot 4.x with desktop + responsive mobile controls, LAN co-op, host-authoritative horror AI, persistent saves, survival systems, Journal progression, separate Labyrinth/Forest maps, runtime AStar navigation, adaptive encounter pacing, co-op interactions, and a 30+ minute Arc 1 Labyrinth.

## v0.20 — LABYRINTH MAJOR OVERHAUL

v0.20 turns the existing v0.19.x Labyrinth systems into one connected chapter loop instead of independent feature layers.

The established Arc 1 route remains:

1. Opening Corridor + Apartment 03
2. Original Labyrinth — restore 3 emergency relays
3. M-01 Maintenance — restore Fuse A/B/C
4. F-02 Flooded Service — turn both pressure valves
5. A-03 Archive — complete breaker sequence `B → A → C`
6. **NEW: Isolation Sweep — disable 3 sector Isolation Nodes**
7. Return to L-04 Lockdown
8. Survive the 2-minute multi-phase stabilization finale
9. Follow the final beacon into the separate Forest map

The first blind-run target is now roughly **35–55 minutes**, depending on exploration, route variant, co-op coordination, shortcut use, failed breaker attempts, optional caches, SYNC stations, and encounter pressure. Experienced runs can be faster.

## Isolation Sweep

After Archive breaker power is restored, the Lockdown Console is physically sealed by an isolation interlock.

Three new mandatory nodes become active:

- M-01 Maintenance Isolation Node
- F-02 Flooded Service Isolation Node
- A-03 Archive Isolation Node

The player must backtrack through the lower Labyrinth and shut down all three before Lockdown can begin.

This phase deliberately connects earlier systems:

- v0.19.2 service shortcuts reduce backtracking
- M/F/A/L signage helps mental navigation
- optional caches become meaningful preparation
- v0.19.3 SYNC support lights can provide temporary regroup zones
- Encounter Director pressure continues during the sweep
- The Warden becomes active while isolation is incomplete

Isolation completion is stored inside the existing Arc `completed` state, so it uses the existing v0.14+ world-save pipeline without a new save format.

## Three route variants

A new Arc 1 run receives one of three Isolation layouts.

The saved route variant changes the authored location of the Maintenance, Flooded and Archive Isolation Nodes. The variant is stored in the Arc save and remains stable after Continue/reconnect.

This is not procedural maze generation: the Labyrinth keeps authored geometry and navigation, while critical late-Arc targets move among vetted locations. The goal is replay variation without destroying level readability or multiplayer determinism.

The HUD identifies the active route mutation as Variant 1/2/3 during the sweep.

## Temporary route shutters

Disabling an Isolation Node causes a short local systems failure:

- maintenance lighting faults
- a loud AI noise event is emitted
- Encounter Director pressure can accelerate
- a temporary metal shutter closes a nearby route for about 7.5 seconds
- the shutter always reopens automatically

The shutters are intentionally temporary so they can create chase beats without permanently soft-locking a run.

Host and clients receive the same shutter event in multiplayer.

## The Warden

v0.20 adds a new elite Arc 1 threat: **The Warden**.

Prototype behavior:

- becomes active during the Isolation Sweep
- returns during the later Lockdown phases
- prioritizes survivors who are far from teammates in co-op
- isolated targets make it move faster
- normal personal flashlight does not fully neutralize it
- strong world/safe-light pockets slow it significantly
- uses the existing runtime AStar navigation helper
- host owns movement and damage in multiplayer
- position/active state is replicated to clients
- deals non-instant-kill damage through the existing health/downed pipeline

The Warden is an elite pressure layer, not another always-on standard enemy.

When The Warden is active, `LabyrinthMajorGatekeeper` trims the simultaneous Mourner/Crawler set:

- Isolation Sweep: maximum 1 Arc standard enemy alongside The Warden
- Lockdown: maximum 2 Arc standard enemies alongside The Warden

Tenant/Darkness pressure remains handled by the existing Encounter Director rules.

This prevents the major update from becoming an uncontrolled 6–7 enemy pile-up and keeps CPU/draw pressure more appropriate for mobile hardware.

## Multi-phase Lockdown finale

The original 120-second Lockdown remains, but v0.20 divides it into three pressure phases:

### Phase 1 — 120–80 seconds

- initial stabilization
- maintenance fault pulse
- Encounter Director begins tightening timing
- The Warden remains absent for the first short preparation window

### Phase 2 — 80–40 seconds

- faster encounter rotation
- stronger fault events
- The Warden is active
- standard Arc enemy count remains budget-limited

### Phase 3 — final 40 seconds

- fastest horror-event pressure
- emergency route lighting becomes the primary visual language
- Warden aggression rises
- player/team must keep moving until stabilization completes

The finale remains completable solo and in 2–4 player co-op.

## Guidance lighting pass

v0.20 adds 12 low-cost floor/wall guidance points across Maintenance, Flooded, Archive and Lockdown.

These lights:

- use small emissive strips
- use low-energy OmniLights with shadows disabled
- remain below the protective-light threshold
- improve floor-edge/navigation readability on desktop and low-brightness mobile displays
- become warmer/redder toward Lockdown

They are not safe zones. Existing safe/checkpoint/SYNC lights remain visibly and mechanically stronger.

## Existing Arc systems retained

### Encounter & pacing — v0.19.1

- CALM / UNEASY / DANGER / SEVERE / LOCKDOWN internal pressure states
- limited active Mourner/Crawler subset
- fake footsteps
- distant metal slam
- flicker
- blackout
- fake corridor shadow
- steam hazards
- electrified puddles
- host-authoritative hazard damage

### Readability & exploration — v0.19.2

- yellow M-01 Maintenance identity
- blue F-02 Flooded identity
- green A-03 Archive identity
- red L-04 Lockdown identity
- route markers and landmark silhouettes
- M-07 Storage optional cache
- F-09 Pump Annex optional cache
- A-12 Records Annex optional cache
- two one-way service shortcuts
- optional Journal finds

### Co-op & team tension — v0.19.3

- paired SYNC A/B stations in Maintenance/Flooded/Archive
- 9-second online two-survivor synchronization window
- 18-second solo fallback
- 36-second temporary protective support light
- shared Battery/Water/Medkit rewards
- increased encounter pressure when survivors spread too far apart
- temporary pacing respite while emergency support light is active

## Enemy roster in Arc 1

Current gameplay threats:

- **The Tenant** — freeze-when-watched rule
- **Darkness Creature** — darkness exposure / protective-light pressure
- **The Mourner x2** — noise-oriented stalkers
- **The Crawler x2** — fast low-profile pressure
- **The Warden x1** — elite isolation/team-separation hunter

Encounter systems limit simultaneous activation rather than running every enemy continuously.

## Save / Continue

Persistent Arc state includes:

- survival/player inventory state
- relay state
- fuse progress
- valve progress
- breaker progress
- Lockdown state/time
- checkpoint stage
- claimed finite pickups
- v0.19.2 shortcut state
- v0.19.3 SYNC completion state
- **v0.20 Isolation Node completion**
- **v0.20 route variant**

Old saves remain usable:

- an old save before Archive simply receives its route variant when the new system initializes
- an old save already inside an active Lockdown can continue the existing holdout instead of being forced backward
- an old completed Arc remains completed

`NEW GAME` clears Arc major-state data together with the existing Arc state.

## Multiplayer authority

Host owns:

- Arc objectives
- Isolation Node validation
- saved route variant
- temporary shutter events
- Warden target/movement/damage
- Encounter Director enemy selection
- hazards
- SYNC station completion
- shared pickups/checkpoints
- Lockdown timer

Clients receive reliable major-state snapshots and Warden transform updates.

The Isolation Node interaction validates the requesting survivor's physical position before accepting a client request.

## Controls

Desktop:

- WASD — move / downed crawl
- Mouse — look
- Shift — sprint
- Space — jump
- E — interact / objective / Isolation / SYNC / shortcut / revive
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

- left joystick — movement/downed movement
- right swipe — look
- RUN
- JUMP
- USE — interaction/objective/Isolation/SYNC/shortcut/revive
- LIGHT
- BATT
- FOOD
- WATER
- MED
- JOURNAL
- MENU

## Recommended v0.20 solo test

1. Use a clean Pull and run in a separate game window if the Godot embedded Game View still does not forward input on the development machine.
2. NEW GAME.
3. Complete Apartment 03 + the original 3 relays.
4. Complete Fuse A/B/C.
5. Complete both pressure valves.
6. Complete Archive breaker sequence `B → A → C`.
7. Confirm the HUD changes to `ISOLATION SWEEP`.
8. Approach Lockdown Console before completing Isolation; the red interlock cover must block direct interaction.
9. Find the three M/F/A Isolation Nodes using route signs, saved route variant and shortcuts.
10. Disable one node and confirm temporary blackout/fault + temporary shutter.
11. Confirm the shutter automatically disappears after roughly 7.5 seconds.
12. Confirm The Warden appears during the sweep.
13. Enter a strong world safe-light pocket and confirm The Warden slows rather than being removed by a normal dim route lamp.
14. Disable all 3 Isolation Nodes.
15. Return to Lockdown and confirm the interlock cover is gone.
16. Start Lockdown and verify Phase 1 → 2 → 3 messaging/pressure.
17. Survive 120 seconds and confirm final Forest transition still appears.
18. Save during Isolation Sweep, quit, Continue, and verify the same route variant + completed nodes are retained.

## Recommended v0.20 co-op test

1. Host + client complete Archive.
2. Confirm both peers receive the same Isolation Node layout.
3. Let the client disable one Isolation Node; host must validate physical distance and both peers must receive the same progress.
4. Confirm both peers see the temporary shutter event.
5. Separate survivors and confirm The Warden favors/accelerates toward isolated targets.
6. Regroup at a SYNC/world safe-light pocket and confirm Warden movement slows.
7. Verify standard Mourner/Crawler pressure is reduced while Warden is active.
8. Reconnect during Isolation Sweep and verify route variant + node completion sync.
9. Complete all 3 nodes and confirm both peers lose the Lockdown interlock.
10. Complete all three final Lockdown phases and transition to Forest.

## Mobile / desktop performance intent

v0.20 remains mobile-conscious:

- no new volumetric effects
- no NavigationMesh bake requirement
- Warden uses one prototype mesh hierarchy
- guidance lights have shadows disabled
- route strips are cheap emissive geometry
- temporary shutters exist only for short events
- Warden activation reduces the standard Arc enemy set
- multiplayer remains 2–4 survivors
- UI/controls remain responsive through the existing mobile control layer

## Git workflow note

`project.godot` is intentionally **not modified for v0.20**.

The already-autoloaded `Arc1NavigationBridge` now creates these runtime systems:

- `LabyrinthEncounterDirector`
- `LabyrinthExplorationSystem`
- `LabyrinthCoopSystem`
- `LabyrinthMajorSystem`
- `LabyrinthMajorGatekeeper`

This keeps the major update out of `project.godot` and reduces the chance of repeating the earlier local Discard/Pull conflict.

The visible menu badge is `v0.20 • LABYRINTH MAJOR OVERHAUL`.

## Current limitations

- Runtime F5 validation must still be performed on the development machine because the assistant environment does not contain the Godot executable.
- The Warden is currently a procedural placeholder without final rig/animation/audio.
- Isolation Nodes, interlock cover, shutters and guidance strips use prototype meshes/materials.
- Temporary shutters use timed authored positions, not a fully procedural route-generation system.
- AI navigation remains runtime AStar waypoint navigation rather than a baked NavigationMesh.
- Internet matchmaking/NAT traversal is not implemented; multiplayer remains LAN/IP based.
- Production environment art, enemy models, animations, spatial audio and VFX are still required.

See `ASSET_BACKLOG.md` for current production asset priorities.
