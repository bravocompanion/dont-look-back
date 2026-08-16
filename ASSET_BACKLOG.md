# DON'T LOOK BACK — Asset Backlog

Updated for **v0.24 — DYNAMIC HORROR AUDIO**.

The project is still code/procedural-first. Gameplay systems are ahead of final art/audio production, so the highest-value work now is replacing prototype presentation while keeping mobile/desktop performance targets.

## P0 — v0.24 audio integration

### Required existing audio files

The new runtime audio system expects these four keyword assets inside the Godot project, preferably under `res://assets/`:

- `music` — background music
- `hurt` — player hit reaction
- `monster` — proximity threat cue/layer
- `battery` — low flashlight battery warning

Accepted runtime resolver formats:

- `.ogg`
- `.wav`
- `.mp3`

Recommended naming:

- `assets/music.ogg`
- `assets/hurt.wav`
- `assets/monster.ogg`
- `assets/battery.wav`

Partial names such as `background_music`, `player_hurt`, `monster_near`, and `low_battery` are also recognized.

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

Battery:

- short electrical chirp/click/weak-beep warning
- must remain recognizable at low phone volume
- avoid a long alarm because warning can repeat at low battery

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

Audio still needed beyond v0.24 four-file integration:

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
- freeze/unseen movement/chase/search/attack
- turn animation support
- distortion/shadow treatment
- movement/breath/proximity/attack SFX

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
- heartbeat/panic
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
- Tenant distortion
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
- profile runtime CSG and OmniLights on actual Android hardware

## Recommended production order after v0.24

1. Commit/verify the four v0.24 audio files (`music`, `hurt`, `monster`, `battery`)
2. First-person flashlight + hand rig + battery animation/SFX
3. Warden production model/animations/audio
4. Isolation Node + Lockdown interlock production kit
5. Evacuation Override + extraction beacon + shutter kit
6. Sector signage/conduit/environment materials
7. Mourner production pass
8. Crawler production pass
9. Survivor model + co-op animations
10. Hazard VFX/audio
11. Tenant production pass
12. Darkness Creature production pass
13. Full spatial ambience/footstep mix
14. Forest/exterior production art
15. Front-end branding + localization polish

See `ASSET_DELTA_V024.md` for the exact v0.24 audio integration contract.
