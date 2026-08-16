# DON'T LOOK BACK — Godot v0.24.1

First-person survival horror prototype for Godot 4.x with responsive desktop/mobile controls, 2–4 player LAN co-op, persistent saves, bilingual Indonesian/English UI, dynamic flashlight handling, survival systems, adaptive horror AI, Labyrinth Arc 1 progression, reverse evacuation finale, Forest transition, and dynamic horror audio.

## Current build — v0.24.1 FLASHLIGHT MONSTER INTERFERENCE

v0.24.1 keeps the runtime `DynamicAudioSystem` from v0.24 and changes `battery` audio into a flashlight-versus-monster interference cue.

The system auto-discovers `.wav`, `.ogg`, or `.mp3` audio under common project folders such as `res://assets`, `res://audio`, `res://sounds`, `res://sfx`, and `res://music`.

Recognized keywords:

- `music` — gameplay background music
- `hurt` — player hit/damage reaction
- `monster` — monster proximity/threat layer
- `battery` — flashlight/monster electrical interference

Exact filenames like `assets/music.ogg` and `assets/battery.mp3` are preferred, but partial keyword names are also accepted.

### Dynamic audio behavior

- Gameplay BGM runs while inside gameplay maps and stops on the dedicated main menu.
- BGM restarts after finishing, giving continuous background-music behavior.
- Monster proximity audio begins around 22 m from an active visible threat and becomes louder as the threat gets closer.
- BGM is automatically ducked by up to roughly 5.5 dB during close monster pressure.
- Tenant, Darkness Creature, Mourner, Crawler, Warden, and Evacuation Warden are included in proximity checks.
- `hurt` triggers on significant HP loss, avoiding repeated SFX from tiny starvation/bleeding/infection ticks.
- `battery.mp3` is no longer a low-battery warning. It plays only while the flashlight beam is contacting a visible monster through a clear line of sight.
- `battery.mp3` volume and pitch rise slightly as continuous monster exposure approaches 3 seconds.
- All channels use the existing Master bus and therefore follow the Settings MASTER VOLUME slider.

### Flashlight monster interference

When the flashlight is ON, the game tests the actual moved SpotLight beam against active monsters using beam direction, cone angle, current range, and world line-of-sight.

The check does not depend on production monster collision. This is important because current procedural Mourner/Crawler visuals are Node3D-based prototype meshes.

Continuous monster exposure is capped at 3 seconds for battery-cost scaling:

- initial contact — approximately `1.0x` normal flashlight drain
- 0.75 s — approximately `1.25x`
- 1.5 s — approximately `1.5x`
- 2.25 s — approximately `1.75x`
- 3.0 s and longer — maximum `2.0x`

Current base battery drain is `1.15/s`, so maximum sustained interference drain is approximately `2.30/s`.

The flashlight also flickers while a monster remains inside the beam. Flicker becomes faster/deeper as exposure approaches 3 seconds. A short `0.16 s` contact grace prevents normal procedural flashlight sway from constantly resetting the effect.

Leaving the monster, turning the flashlight off, losing line-of-sight, or running out of battery resets interference and returns drain to `1.0x`.

Low battery still has its existing visual weakness/flicker behavior, but it no longer plays `battery.mp3`.

At the time the audio system was introduced, GitHub `main` did not contain an `assets/` directory. Local audio files work if already inside the Godot project, but they must also be committed if audio should be present after clone/pull or in repository-only builds.

See `ASSET_DELTA_V024.md` for exact audio requirements and testing.

## v0.23 language settings

Settings supports:

- Bahasa Indonesia
- English

Language changes are immediate and persistent in `user://dont_look_back_language.cfg`.

The main menu, gameplay settings, core HUD, survival stat labels, inventory/common items, interaction prompts, death/restart messaging, mission UI, and major Arc 1 objective language have bilingual coverage. Sector and co-op callouts such as M-01, F-02, A-03, L-04, SYNC, LOCKDOWN, and Warden remain stable across languages.

Long-form Journal lore is still intended for curated translation rather than automatic replacement.

## v0.22 flashlight and lighting feel

Full flashlight baseline:

- energy `6.7`
- range `13 m`
- cone angle `28°`

Flashlight motion is procedural rather than rigidly attached to the camera:

- idle — subtle breathing sway
- walk — breathing + footstep bob
- sprint — larger pitch/yaw/roll movement
- fast look — small flashlight inertia/lag
- jump — takeoff kick
- landing — impact dip
- low stamina / health / panic / darkness — additional controlled instability
- mobile — approximately 74% of desktop motion amplitude

The camera remains comparatively stable to reduce motion sickness.

Normal Labyrinth ambience lights remain below the protective-light threshold. Decorative/fault/evacuation lights are navigation and mood sources, not automatic safe zones.

## Current Arc 1 route

1. Opening Corridor + Apartment 03
2. Restore 3 original emergency relays
3. M-01 Maintenance — Fuse A/B/C
4. F-02 Flooded Service — Valve A/B
5. A-03 Archive — Breaker B → A → C
6. Isolation Sweep — disable M/F/A Isolation Nodes
7. Return to L-04 Lockdown
8. Survive the 120-second three-phase Lockdown
9. Evacuation Protocol begins
10. Reverse through A-03 and restore Emergency Override
11. Reverse through F-02 and restore Extraction Override
12. Return toward M-01 while Evacuation Warden hunts
13. Reach M-01 extraction beacon
14. Transition to Forest

A blind Arc 1 run is intended to be roughly 40–60 minutes depending on exploration, co-op coordination, shortcuts, SYNC use, route variation, failed Archive attempts, resources, and enemy pressure.

## Labyrinth gameplay systems

The lower Labyrinth contains:

- adaptive Encounter Director
- Mourner + Crawler enemy rotation
- Tenant and Darkness pressure
- The Warden elite hunt
- three saved Isolation route variants
- temporary pressure shutters
- environmental steam/electrical hazards
- sector color/signage language
- optional supply bays
- Journal notes
- one-way service shortcuts
- paired optional co-op SYNC stations
- temporary genuine safe-light rewards
- 3-phase Lockdown finale
- reverse-route Evacuation finale

The evacuation timer is a pressure target rather than an instant death timer. At zero it becomes `EVACUATION CRITICAL`; the run remains completable but the Warden and horror pressure intensify.

## Multiplayer

LAN/IP co-op supports 2–4 survivors.

Existing systems include:

- Host / Join
- Ready / Not Ready
- host Start
- survivor names
- remote flashlight/avatar representation
- teammate/downed UI
- revive
- downed crawl
- shared checkpoint
- reconnect support
- late-join map/state synchronization
- host-led monster/objective/hazard state

Important current limitation: multiplayer is still prototype-grade LAN authority rather than hardened competitive server authority. Some older RPC paths need additional server-side position/sanity validation before public release.

## Save / Continue

Persistent world save:

`user://dont_look_back_save_v1.json`

It includes player survival state, inventory, finite pickup claims, relay/world state, checkpoints, Journal progress, Arc 1 progression, Isolation state, route variant, Lockdown state, shortcuts, co-op SYNC completion, and Evacuation progress.

Language preference is intentionally stored separately from world save.

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
- L — offline load / language toggle inside language UI context
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

UI and button layout scale from viewport short-side values for phone/tablet/desktop responsiveness.

## Recommended v0.24.1 test

Audio + flashlight interference quick pass:

1. Place/confirm `music`, `hurt`, `monster`, and `battery` files under the local project assets/audio folders and let Godot finish importing them.
2. NEW GAME: BGM should begin.
3. Change MASTER VOLUME: BGM/SFX should follow it.
4. Take a normal monster hit: `hurt` should play once.
5. Approach an active monster from more than 22 m without aiming the flashlight at it: `monster` proximity should fade in; `battery.mp3` should remain silent.
6. Drain flashlight below 22% while not aiming at a monster: `battery.mp3` should remain silent.
7. Aim the flashlight directly at a visible monster: `battery.mp3` should start and the flashlight should flicker.
8. Hold beam for about 1.5 seconds: total battery drain should be around `1.5x` normal.
9. Hold beam for 3 seconds or more: drain should cap at `2.0x` and must not continue increasing.
10. Aim away or put a wall between player and monster: interference audio/flicker should stop and drain should return to `1.0x`.
11. Repeat against Tenant, Darkness Creature, Mourner, Crawler, Warden, and Evacuation Warden.
12. Return to title: gameplay audio stops.

Regression pass:

- flashlight remains energy 6.7 at full battery
- idle/walk/sprint flashlight sway remains functional
- low-battery visual behavior still functions without `battery.mp3`
- Indonesian/English switching still persists
- Labyrinth objective route remains unchanged
- desktop and mobile controls remain responsive

## Current technical priorities

Before treating the project as a public demo/release candidate, priority stabilization work includes:

- harden host-side validation for older Arc objective/map-transition RPCs
- make checkpoint + finite-loot rollback consistent
- block MovementSystem while Journal is open
- simplify Evacuation Warden state ownership
- rebalance flashlight battery/darkness economy after runtime playtesting
- profile runtime CSG/lights/navigation on real Android hardware
- move more prototype procedural art/audio into production assets

## Git workflow note

`project.godot` is intentionally not modified by v0.22–v0.24.1 runtime feature additions. Flashlight, Language, and DynamicAudio systems are bootstrapped through existing runtime/autoload systems to reduce conflict risk with local project settings.

The visible in-menu build badge for current `main` is:

`v0.24.1 • FLASHLIGHT MONSTER INTERFERENCE`

When local `project.godot` differs from remote, back it up or stash changes before Pull instead of blindly discarding local settings.

## Runtime validation limitation

The assistant environment does not contain the Godot executable, so repository changes receive static code/logic review but still require F5/device runtime validation on the development machine.
