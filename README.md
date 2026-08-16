# DON'T LOOK BACK — Godot v0.24.3

First-person survival horror prototype for Godot 4.x with responsive desktop/mobile controls, 2–4 player LAN co-op, persistent saves, bilingual Indonesian/English UI, dynamic flashlight handling, survival systems, adaptive horror AI, Labyrinth Arc 1 progression, reverse evacuation finale, Forest transition, and dynamic horror audio.

## Current build — v0.24.3 TENANT FLASHLIGHT KILL FEEDBACK

v0.24.3 adds stronger feedback when the flashlight is held on The Tenant and adds a dedicated Tenant death/banish audio cue.

### Tenant flashlight feedback

While The Tenant is inside the real flashlight beam:

- existing `battery.mp3` interference continues to play
- generic flashlight-monster battery drain still ramps from `1.0x` toward `2.0x` across the 3-second exposure window
- Tenant receives an additional rapid flashlight modulation layer after the normal flashlight energy/interference calculation
- rapid flicker begins around `8 Hz` and can rise toward roughly `12 Hz` as the 3-second hold approaches completion
- brightness is not forced completely black; the effect uses a minimum energy factor around `0.22` at high strength

The generic v0.24.1 `battery.mp3` interference remains available for other monsters. Tenant simply receives stronger visual feedback on top of it.

### Tenant death audio

When the 3-second flashlight hold completes and The Tenant changes from active to inactive because of the flashlight kill/banish, the runtime audio system plays a dedicated `tenant death` one-shot.

The resolver accepts `.wav`, `.ogg`, or `.mp3` and normalizes spaces, underscores, and dashes. Examples:

- `tenant death.mp3`
- `tenant_death.mp3`
- `tenant-death.ogg`
- `tenantdeath.wav`

The death cue stops `battery.mp3` first, then plays the Tenant death one-shot at its own mix level.

A dedicated `TenantDeathFeedbackSystem` guards against false triggers: scene changes reset the kill state, and if the flashlight hold falls below the near-complete threshold while Tenant is still active, the death-armed flag is cleared.

### Co-op death feedback

In online play, the host watches the existing per-peer flashlight hold state. When a flashlight kill is confirmed, the host plays the local death cue and sends a reliable Tenant-death feedback RPC on channel 18 so each client plays the same local asset once.

See `ASSET_DELTA_V0243.md` for the new audio requirement and test checklist.

## v0.24.2 PANIC-DRIVEN TENANT

v0.24.2 changes PANIC from a monster-proximity meter into a player-motion meter and rebuilds The Tenant around that rule.

PANIC sources:

- horizontal movement above roughly `4.75 m/s`
- fast mouse/touch-look above roughly `95 deg/s`
- full movement contribution near `6.75 m/s`
- full look contribution near `420 deg/s`
- movement contributes up to `16 panic/s`
- fast look contributes up to `20 panic/s`
- combined gain is capped around `32 panic/s`
- calm movement/look lets panic decay around `6/s`

Normal walking does not automatically increase panic. Sprinting, hard direction changes, fast mouse flicks, and fast touch swipes do.

### The 2-second stillness rule

When a player remains effectively still for `2.0 seconds` — horizontal speed <= `0.12 m/s` and look motion <= `3 deg/s` — The Tenant appears near that player if it is not already active.

The old corridor HorrorTrigger no longer spawns Tenant directly. Pause, menu, Journal, transition, death, and downed state do not count toward the stillness timer.

Tenant spawn tries to appear around `4.2 m` behind/near the player and uses the current navigation clamp, so lower-Labyrinth placement is not restricted to the old opening corridor coordinates. Gameplay maps without a pre-authored `Monster` node receive the runtime Tenant prototype automatically.

### Panic-scaled Tenant

Tenant movement speed scales continuously with the panic of the survivor it is hunting:

- 0% panic — `1.65 m/s`
- 25% — `~1.99 m/s`
- 50% — `~2.33 m/s`
- 75% — `~2.66 m/s`
- 100% — `3.00 m/s`

Tenant damage remains `28 HP` per hit.

Attack cooldown scales with panic:

- 0% panic — `2.40 s`
- 25% — `~2.06 s`
- 50% — `~1.73 s`
- 75% — `~1.39 s`
- 100% — `1.05 s`

At panic 100%, movement is roughly `1.82x` the zero-panic speed and attack attempts can occur roughly `2.29x` as often.

The existing watched/freeze rule remains: keeping The Tenant clearly in sight stops its movement. Looking at it alone does not remove it.

### 3-second flashlight kill / banish

The Tenant disappears only after a continuous `3.0-second` flashlight hold.

Requirements:

- flashlight ON
- battery above zero
- Tenant inside the actual flashlight cone/range
- clear world line-of-sight
- continuous beam contact for 3 seconds

Breaking beam contact resets the Tenant-specific hold. A short contact grace protects the hold from tiny procedural flashlight sway.

The old SafeZone story trigger no longer deletes Tenant automatically.

### Co-op behavior

Each survivor owns a local PANIC meter. A runtime `TenantPanicNetworkBridge` sends local panic + Tenant flashlight contact to the host on RPC channel 17.

The host:

- uses the panic of the survivor currently being hunted for Tenant movement/attack scaling
- owns the 3-second flashlight-dismiss validation
- keeps Tenant navigation/attack authoritative through the existing host simulation
- prevents the older direct co-op Tenant movement path from stacking with AINavigation movement

No new mobile or desktop button is required.

See `V0242_PANIC_TENANT.md` for full tuning and test cases, and `ASSET_DELTA_V0242.md` for production-asset requirements.

## v0.24.1 flashlight monster interference

`battery.mp3` is not a low-battery warning. It is a flashlight-versus-monster interference cue.

The moved SpotLight beam is tested against visible threats using beam direction, cone angle, range, and line-of-sight. Current prototype monster collision is not required for the contact test.

Battery-cost scaling during continuous monster exposure:

- initial contact — `~1.0x`
- 0.75 s — `~1.25x`
- 1.5 s — `~1.5x`
- 2.25 s — `~1.75x`
- 3.0 s+ — maximum `2.0x`

Base flashlight drain is `1.15/s`, so maximum sustained interference drain is approximately `2.30/s`.

Low battery still has visual weakness/flicker, but it does not play `battery.mp3`.

## v0.24 dynamic horror audio

Runtime audio auto-discovers `.wav`, `.ogg`, or `.mp3` under common folders such as `res://assets`, `res://audio`, `res://sounds`, `res://sfx`, and `res://music`.

Recognized keywords:

- `music` — gameplay BGM
- `hurt` — player damage reaction
- `monster` — proximity threat layer
- `battery` — flashlight/monster interference
- `tenant death` — Tenant flashlight-kill confirmation added in v0.24.3

BGM follows Master Volume and ducks during close monster pressure. Monster proximity begins around 22 m and includes Tenant, Darkness Creature, Mourner, Crawler, Warden, and Evacuation Warden.

## v0.23 language settings

Settings supports Bahasa Indonesia and English. Language changes immediately and persists in:

`user://dont_look_back_language.cfg`

Core menu/HUD/gameplay text is bilingual. Stable co-op/sector callouts such as M-01, F-02, A-03, L-04, SYNC, LOCKDOWN, and Warden remain consistent between languages.

## v0.22 flashlight and lighting feel

Full flashlight baseline:

- energy `6.7`
- range `13 m`
- cone angle `28°`

Flashlight handling includes idle breathing sway, walk bob, stronger sprint sway, look inertia, jump/landing response, stress instability, and reduced motion amplitude on mobile. The camera remains comparatively stable to reduce motion sickness.

Normal Labyrinth ambience/fault/evacuation lights remain visually distinct from genuine protective safe lights.

## Current Arc 1 route

1. Opening Corridor + Apartment 03
2. Restore 3 emergency relays
3. M-01 Maintenance — Fuse A/B/C
4. F-02 Flooded Service — Valve A/B
5. A-03 Archive — Breaker B → A → C
6. Isolation Sweep — disable M/F/A Isolation Nodes
7. Return to L-04 Lockdown
8. Survive the 120-second three-phase Lockdown
9. Evacuation Protocol begins
10. Restore A-03 Emergency Override while reversing route
11. Restore F-02 Extraction Override
12. Return toward M-01 while Evacuation Warden hunts
13. Reach M-01 extraction beacon
14. Transition to Forest

A blind Arc 1 run is intended to be roughly 40–60 minutes depending on exploration, co-op coordination, shortcuts, SYNC use, route variation, Archive mistakes, resources, and enemy pressure.

## Multiplayer

LAN/IP co-op supports 2–4 survivors with Host/Join, Ready/Not Ready, shared checkpoints, revive/downed crawl, late join, reconnect support, remote survivor/flashlight representation, and host-led monster/objective/hazard state.

Multiplayer remains prototype-grade LAN authority rather than hardened competitive-server authority; several older RPC paths still need stronger server-side sanity/distance validation before public release.

## Save / Continue

Persistent world save:

`user://dont_look_back_save_v1.json`

It stores survival/inventory state, finite pickup claims, checkpoints, world state, Journal progress, Arc 1 objectives, Isolation/route state, Lockdown, shortcuts, SYNC completion, and Evacuation progress.

Language is intentionally stored separately from world save.

## Controls

Desktop:

- WASD — move
- Mouse — look
- Shift — sprint
- Space — jump
- E — use/interact
- F — flashlight
- B / 4 — replace battery
- 1 — food
- 2 — water
- 3 — medical aid
- J — Journal
- M — co-op UI
- K — save
- L — offline load / language toggle in language-setting context
- Esc — menu

Mobile:

- left joystick — move
- right swipe — look
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

## Recommended v0.24.3 test

1. Let Tenant appear after the existing stillness rule.
2. Aim flashlight at Tenant: `battery.mp3` should begin.
3. Verify Tenant flicker is visibly faster than generic flashlight-monster interference.
4. Release the beam before 3 seconds: Tenant remains and `tenant death` must stay silent.
5. Reacquire Tenant and hold the beam continuously for 3 seconds: Tenant disappears.
6. On successful disappearance, `battery.mp3` stops and `tenant death` plays once.
7. Verify another monster still triggers the original `battery.mp3` interference behavior.
8. Put a wall between flashlight and Tenant: kill hold must not advance.
9. Move to another map with Tenant active: death cue must not fire only because the scene changed.
10. Co-op host/client: successful flashlight kill should produce one death cue on every peer.
11. Verify flashlight full-battery baseline remains energy `6.7`.
12. Verify PANIC speed/attack scaling remains unchanged from v0.24.2.
13. Test rapid flicker at both 30 FPS mobile target and 60 FPS desktop target.

## Current technical priorities

Before public demo/release-candidate status:

- harden older host-side objective/map-transition RPC validation
- make checkpoint + finite-loot rollback consistent
- block MovementSystem while Journal is open
- simplify Evacuation Warden state ownership
- rebalance flashlight battery/darkness economy after runtime playtesting
- add a Reduce Flashing accessibility option before public release
- profile CSG/lights/navigation on real Android hardware
- replace procedural prototype presentation with production assets

## Git workflow note

`project.godot` remains intentionally untouched by v0.22–v0.24.3 runtime feature additions. Flashlight, Language, DynamicAudio, PanicTenant, TenantPanicNetworkBridge, TenantFlashlightFX, and TenantDeathFeedback systems are bootstrapped through existing runtime/autoload infrastructure to reduce conflicts with local project settings.

Current visible menu badge:

`v0.24.3 • TENANT FLASHLIGHT KILL FEEDBACK`

If local `project.godot` differs from remote, back it up or stash changes before Pull instead of blindly discarding local settings.

## Runtime validation limitation

The assistant environment does not contain the Godot executable. Repository changes receive static code/logic review but still require F5/device validation on the development machine.
