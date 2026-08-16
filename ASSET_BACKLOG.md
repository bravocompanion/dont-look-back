# DON'T LOOK BACK — Asset Backlog

Updated for **v0.24.2 — PANIC-DRIVEN TENANT**.

The project is still code/procedural-first. Gameplay systems are ahead of final art/audio production, so the highest-value work now is replacing prototype presentation while keeping mobile/desktop performance targets.

## P0 — v0.24.2 Panic-Driven Tenant

The Tenant production pass now needs to support movement-driven panic and a 3-second flashlight banish mechanic.

Animation / presentation:

- near-player emergence/materialize animation for the 2-second stillness trigger
- freeze/watched pose that remains readable while the player keeps it in sight
- low-panic stalk locomotion around 1.65 m/s
- medium-panic locomotion blend around 2.3 m/s
- high-panic chase locomotion up to 3.0 m/s
- attack animation/recovery that can visually support cooldowns from 2.40 s down to about 1.05 s
- flashlight-hit reaction loop
- 3-second banish/dissolve/distortion animation

VFX/audio:

- low-overdraw appearance distortion
- flashlight reaction that intensifies over the 0–3 second hold
- banish dissolve/pop effect
- emergence sting
- panic-scaled footsteps/breath/body-creak
- flashlight burn/interference layer
- banish release sound

Optional panic feedback:

- subtle PANIC HUD pulse at 50%+
- stronger pulse at 75%+
- restrained movement-driven heartbeat/breath layer

See `ASSET_DELTA_V0242.md` for the exact v0.24.2 production delta.

## P0 — v0.24 audio integration

### Required existing audio files

The runtime audio system expects these four keyword assets inside the Godot project, preferably under `res://assets/`:

- `music` — background music
- `hurt` — player hit reaction
- `monster` — proximity threat cue/layer
- `battery` — flashlight/monster interference cue while the beam is held on a monster

Accepted runtime resolver formats:

- `.ogg`
- `.wav`
- `.mp3`

Recommended naming:

- `assets/music.ogg`
- `assets/hurt.wav`
- `assets/monster.ogg`
- `assets/battery.mp3`

Partial names such as `background_music`, `player_hurt`, and `monster_near` are also recognized. For the interference cue, prefer a basename containing `battery`.

### Repository requirement

At implementation time GitHub `main` did not contain an `assets/` directory. If these files currently exist only on the development PC, they need to be committed so clones, collaborators, and repository-based Android/desktop builds include them.

### Audio production recommendations

Music:

- seamless or near-seamless horror ambience loop
- avoid constant loud melody
- leave headroom for monster cue and environmental SFX
- `.ogg` preferred for longer files

Hurt:

- short player vocal/body impact
- ideally 3–5 variants later
- no long reverb tail that masks nearby horror audio

Monster proximity:

- designed to tolerate repeated playback while danger remains close
- dark pulse/drone/breath/heartbeat style works better than a single loud jumpscare hit
- should remain readable on phone speakers

Battery / interference:

- electrical instability/glitch character rather than a low-battery alarm
- should tolerate repeated/looped playback during a flashlight hold
- readable on phone speakers without becoming piercing
- optional 2–3 variants later to reduce repetition

## P0 — Flashlight / lighting production

First-person flashlight:

- production flashlight model
- first-person hand/forearm rig
- world/remote-player version
- switch animation
- battery replacement animation
- idle breathing pose
- walk movement
- sprint movement
- jump/landing response
- optional flashlight beam cookie/dust

Lighting fixtures:

- dirty fluorescent fixture
- caged industrial lamp
- dim/off/flicker/fault states
- genuine protective safe-light visual language
- evacuation red/orange fixture
- low-overdraw emissive LODs

Audio still needed beyond the four-file integration:

- flashlight switch on/off
- battery insert/remove
- electrical buzz/flicker
- bulb relay clicks
- failing fluorescent hum

## P0 — The Warden

Production model:

- broad/heavy industrial humanoid silhouette
- distinct from Tenant/Mourner/Crawler/Darkness
- readable chest/core feature
- mobile LOD
- simple collision proxy

Animations:

- idle/listen
- heavy patrol
- pursuit
- isolated-target acceleration
- safe-light hesitation
- attack/recovery
- evacuation faster pursuit
- aggressive turn/corner response

Audio:

- heavy footsteps
- body/mechanical creak
- breathing/growl
- chest/core pulse
- attack impact
- safe-light discomfort
- evacuation re-entry cue

## P0 — Isolation / Lockdown / Evacuation kit

Isolation Nodes:

- Maintenance/Flooded/Archive variants
- sealed/active/shutdown/fault states
- industrial housing
- lever/rotary handle
- breaker/core bank
- conduit + warning labels
- shutdown animation/audio

Lockdown interlock:

- physical cover larger than final console
- 0/3 → 3/3 state display
- mechanical lock bars
- release animation
- mechanical release SFX

Temporary shutters:

- industrial drop/sliding shutter
- rails/frame
- actuator
- simple collision proxy
- close/open animation
- slam/motor/rattle/open SFX
- optional low-cost dust/sparks

Evacuation Override A/F:

- distinct wall-mount control body
- heavy switch/handle
- waiting/red state
- restored/green state
- sector labels
- reconnect surge + relay audio

M-01 extraction beacon:

- strong green/white emergency fixture
- extraction floor marking
- EXIT/SURFACE/EVAC signage
- armed state
- stable powered hum
- transition sting into Forest

## P0 — Labyrinth environment/readability

Sector kit:

- M-01 Maintenance signage
- F-02 Flooded Service signage
- A-03 Archive signage
- L-04 Lockdown signage
- M-07/F-09/A-12 optional room plates
- directional arrows
- worn stencils/decals

Conduit navigation:

- straight/elbow/T modules
- cable trays/brackets
- damaged variants
- yellow/blue/green/red route variants

Environment modules:

- concrete/plaster/tile wall/floor/ceiling textures
- normal + roughness maps
- pipes
- utility doors
- fuse/valve/breaker props
- archive shelves/boxes
- wet concrete/shallow water materials
- drainage grates
- debris/clutter

Service shortcut doors:

- hatch/industrial service door
- latch
- locked/open state
- latch release + scrape/clunk audio

## P0 — Core monsters

The Tenant:

- final rigged humanoid horror model
- freeze/unseen movement/panic-scaled chase/search/attack
- near-player emergence support
- flashlight reaction + 3-second banish
- turn animation support
- distortion/shadow treatment
- movement/breath/proximity/attack/banish SFX

Darkness Creature:

- unique silhouette
- crawl/search/attack
- light recoil/retreat
- dissolve/disappear
- darkness forming/retreat SFX

The Mourner:

- tall narrow production model
- mobile LOD
- listen/stalk/investigate/light-slow/attack
- dragging footsteps/breathing/attack audio

The Crawler:

- low distorted rig
- crawl/fast pursuit/light hesitation/search/lunge
- crawl/contact/lunge audio

## P0 — Survivor/co-op presentation

One production survivor base with 3–4 visual variants.

Need:

- rigged survivor
- outfit/material variants
- first-person arms
- world flashlight attachment
- backpack/utility points
- idle/walk/run/strafe
- jump/fall/landing
- hit reaction
- downed idle/crawl
- revive teammate/being revived
- death/team-wipe pose

Co-op UI/audio:

- Ready/Host/Ping icons
- teammate/downed/revive indicators
- reconnect icon
- SYNC panel state icons
- subtle team-separation/static cue
- regroup relief cue

## P0 — Hazards and horror-event assets

Steam:

- damaged vent/pipe fixture
- mobile-safe steam VFX
- buildup cue + burst hiss

Electrical:

- electrified puddle material
- exposed cable/junction box
- arc/spark VFX
- buzz/discharge audio

Horror event audio/visuals:

- 4–6 metal slam variants
- fake footsteps by surface
- fluorescent flicker
- blackout down/recovery
- fake shadow silhouette
- scrape/cloth/movement cues

## P0 — General player/audio

Footsteps:

- concrete walk/sprint
- wet concrete
- metal
- wood
- dirt/grass
- jump/landing
- downed crawl

Player:

- breathing
- sprint breathing
- movement-driven panic heartbeat
- multiple hurt variants
- bleeding/downed/revive

Interaction:

- doors
- locked door
- heavy gate
- fuse
- valve
- breaker
- isolation node
- evacuation override
- SYNC
- pickup
- generator/workbench/water pump

## P1 — Forest / exterior

- visible sun/moon discs
- dawn/day/dusk/night sky
- stars optional
- lightweight clouds/fog
- cabin production kit
- gas station kit
- warehouse props
- abandoned house props
- generator/workbench/storage/campfire
- forest ambience layers
- dirt/grass foliage modules with mobile LOD

## P1 — Front-end / localization

- final DON'T LOOK BACK logo
- title art + mobile crop
- menu background
- final buttons/icons
- loading/save/checkpoint indicators
- Indonesian/English typography QA
- terminology sheet for co-op callouts
- curated Indonesian translation for long Journal lore

## P2 — VFX polish

- flashlight dust
- Warden core pulse/distortion
- Darkness dissolve
- Tenant emergence/flashlight-banishing distortion
- evacuation dust/debris
- shutter sparks
- shallow-water ripple/splash
- pipe leaks
- blackout recovery sparks
- Lockdown pulse
- extraction bloom
- cold breath
- campfire smoke/sparks

## Mobile + desktop constraints

- prioritize `.ogg` compression for long BGM/ambience
- verify SFX remain audible on phone speakers without clipping
- keep most decorative realtime lights shadowless
- use shared materials/atlases
- avoid volumetric fog as a required gameplay effect
- low-overdraw particles
- simple collision proxies
- monster/survivor mobile LODs
- avoid 4K textures except hero/menu art
- test red/orange/green state readability at low phone brightness
- high-panic Tenant attack animation must remain readable at 30 FPS
- Tenant animation/root motion must not fight host-authoritative navigation
- profile runtime CSG and OmniLights on actual Android hardware

## Recommended production order after v0.24.2

1. Commit/verify the four audio files (`music`, `hurt`, `monster`, `battery`)
2. Tenant emergence + flashlight banish animation/VFX/audio
3. Tenant panic-scaled locomotion + fast attack/recovery variants
4. First-person flashlight + hand rig + battery animation/SFX
5. Warden production model/animations/audio
6. Isolation Node + Lockdown interlock production kit
7. Evacuation Override + extraction beacon + shutter kit
8. Sector signage/conduit/environment materials
9. Mourner production pass
10. Crawler production pass
11. Survivor model + co-op animations
12. Hazard VFX/audio
13. Darkness Creature production pass
14. Full spatial ambience/footstep mix
15. Forest/exterior production art
16. Front-end branding + localization polish

See `ASSET_DELTA_V024.md` for the audio integration contract and `ASSET_DELTA_V0242.md` for the current Tenant/PANIC production delta.
