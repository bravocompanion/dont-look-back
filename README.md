# DON'T LOOK BACK — Godot v0.24

First-person survival horror prototype for Godot 4.x with responsive desktop/mobile controls, 2–4 player LAN co-op, persistent saves, bilingual Indonesian/English UI, dynamic flashlight handling, survival systems, adaptive horror AI, Labyrinth Arc 1 progression, reverse evacuation finale, Forest transition, and dynamic horror audio.

## Current build — v0.24 DYNAMIC HORROR AUDIO

v0.24 adds a runtime `DynamicAudioSystem` without adding a new autoload entry to `project.godot`. It is bootstrapped by the existing `FrontEndSystem` together with the flashlight and language systems.

The system auto-discovers `.wav`, `.ogg`, or `.mp3` audio under common project folders such as `res://assets`, `res://audio`, `res://sounds`, `res://sfx`, and `res://music`.

Recognized keywords:

- `music` — gameplay background music
- `hurt` — player hit/damage reaction
- `monster` — monster proximity/threat layer
- `battery` — low flashlight battery warning

Exact filenames like `assets/music.ogg` are preferred, but names such as `background_music.mp3` or `low_battery.wav` are also accepted.

### Dynamic audio behavior

- Gameplay BGM runs while inside gameplay maps and stops on the dedicated main menu.
- BGM restarts after finishing, giving continuous background-music behavior.
- Monster proximity audio begins around 22 m from an active visible threat and becomes louder as the threat gets closer.
- BGM is automatically ducked by up to roughly 5.5 dB during close monster pressure.
- Tenant, Darkness Creature, Mourner, Crawler, Warden, and Evacuation Warden are included in proximity checks.
- `hurt` triggers on significant HP loss, avoiding repeated SFX from tiny starvation/bleeding/infection ticks.
- Low-battery warning begins at the player's current 22% threshold.
- Low-battery reminders are spaced roughly 9 seconds apart; below 10% they become more urgent at roughly 4.8-second intervals.
- All channels use the existing Master bus and therefore follow the Settings MASTER VOLUME slider.

At the time v0.24 code was committed, GitHub `main` did not contain an `assets/` directory. Local audio files will work if they are already inside the Godot project, but they must also be committed if the audio should be present after clone/pull or in builds created from repository-only sources.

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

## Recommended v0.24 test

Audio quick pass:

1. Place/confirm `music`, `hurt`, `monster`, and `battery` files under the local project `assets` folder.
2. Let Godot finish importing them.
3. NEW GAME: BGM should begin.
4. Change MASTER VOLUME: BGM/SFX should follow it.
5. Take a normal monster hit: `hurt` should play once.
6. Approach an active monster from more than 22 m: proximity audio should fade in and become stronger when close.
7. Move away: monster layer should fade and stop.
8. Drain flashlight to 22%: battery warning should play.
9. Stay below 22% with flashlight on: warning repeats without frame-by-frame spam.
10. Replace battery: warning cycle resets.
11. Return to title: gameplay audio stops.

Regression pass:

- flashlight remains energy 6.7 at full battery
- idle/walk/sprint flashlight sway remains functional
- Indonesian/English switching still persists
- Labyrinth objective route remains unchanged
- Forest transition remains available only through normal progression flow
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

`project.godot` is intentionally not modified by v0.22–v0.24 runtime feature additions. Flashlight, Language, and DynamicAudio systems are bootstrapped through existing runtime/autoload systems to reduce conflict risk with local project settings.

The visible in-menu build badge for current `main` is:

`v0.24 • DYNAMIC HORROR AUDIO`

When local `project.godot` differs from remote, back it up or stash changes before Pull instead of blindly discarding local settings.

## Runtime validation limitation

The assistant environment does not contain the Godot executable, so repository changes receive static code/logic review but still require F5/device runtime validation on the development machine.
