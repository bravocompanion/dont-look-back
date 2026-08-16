# DON'T LOOK BACK — Asset Backlog

Updated for **v0.20 — LABYRINTH MAJOR OVERHAUL**.

The prototype remains code/procedural-first. v0.20 adds the Isolation Sweep, three saved route variants, temporary route shutters, 12 additional guidance-light points, a three-phase Lockdown finale, and a new elite enemy: **The Warden**.

## P0 — New needs from v0.20

### The Warden

Need a final elite monster visually distinct from Tenant, Mourner, Crawler and Darkness Creature.

Model direction:

- broad-shouldered industrial/humanoid horror silhouette
- noticeably heavier upper body than The Mourner
- narrow or masked head shape
- one readable chest/core feature for silhouette recognition
- damaged security/maintenance language optional
- should remain intimidating at medium distance in dim corridors
- final mesh needs mobile LODs
- simple collision proxy; gameplay collision does not require detailed mesh collision

Rig / animation:

- heavy idle
- slow patrol
- deliberate pursuit walk
- isolated-target acceleration
- safe-light hesitation/slow reaction
- turn left/right
- search/listen
- short heavy attack
- attack follow-through
- reactivation/appearance pose
- Lockdown Phase 3 aggressive locomotion variant optional

Audio:

- heavy distant footstep family
- mechanical/body creak
- low chest/core pulse
- isolated-target pursuit cue
- safe-light discomfort cue
- close breathing/growl
- impact/attack transient
- distant Warden identification sting, used sparingly

Important design rule:

- the Warden should sound recognizably heavier than Mourner
- do not make every appearance use a loud music sting
- personal flashlight should not communicate that it completely defeats the Warden
- strong world safe-light needs a clearer reaction language

### Isolation Node kit

Three sector variants are required:

- M-01 Maintenance Isolation Node
- F-02 Flooded Service Isolation Node
- A-03 Archive Isolation Node

Shared kit:

- industrial wall/floor control body
- central isolation core / rotary element
- power conduit connections
- OFF / NO POWER state
- ACTIVE RED state
- ISOLATED / COMPLETE state
- sector-color markings
- large enough silhouette to find while moving through dim corridors

Animations:

- activation / shutdown interaction
- core spin-down or relay drop
- electrical discharge
- completed dead-state

Audio:

- electrical hum
- interaction clunk
- isolation relay drop
- power collapse
- short sector alarm
- distant system response after shutdown

VFX:

- small sparks
- short red pulse
- power-down flicker
- low-cost mobile electrical version

### Lockdown Isolation Interlock

The final Lockdown Console needs a physical cover/interlock that clearly prevents early activation.

Need:

- heavy red metal cover
- warning text / isolation iconography
- visible lock mechanism
- 3-node status treatment optional
- open/retracted state after Isolation Sweep

Animation/audio:

- locked rattle
- final third-node release
- cover retract/open
- metal stop/clunk

The interlock must visually cover the Lockdown Console collider and should not look like another normal door.

### Temporary route shutters

v0.20 creates short route-block events after Isolation Node shutdown.

Need modular shutter kit:

- compact vertical emergency shutter
- concrete-wall frame
- industrial metal slats/panel
- warning stripe treatment
- red fault indicator
- damaged/rusted variants optional

Animation:

- fast slam/close
- brief closed vibration
- reopen after event
- final settle

Audio:

- warning relay click
- heavy shutter slam
- metal vibration
- reopening motor
- final clunk

Gameplay readability:

- must clearly look temporary/emergency rather than permanently locked
- opening animation must be obvious so players do not assume a dead end

### Guidance floor/wall lights

v0.20 adds 12 low-energy route guidance points.

Need:

- small recessed floor strip
- wall strip variant
- dirty amber maintenance version
- warm red Lockdown version
- broken/flickering version optional

Important:

- guidance lights are **not protective lights**
- they must remain visibly weaker than safe/checkpoint/SYNC lamps
- emission needs to remain readable on low-brightness phones without high realtime-light cost
- production implementation should prefer emissive geometry; tiny OmniLight support only where necessary

### Three route variants

The geometry remains authored, but Isolation targets move among vetted locations.

Production art should support this without obvious empty sockets:

- 2–3 generic node mounting plates per sector
- cable/conduit dead-end caps for unused locations
- removable access-panel dressing
- sector labels that work regardless of selected route variant
- subtle environmental clues near possible node locations

Avoid large unique signage that reveals inactive node positions too easily.

### Lockdown Phase 1 / 2 / 3 presentation

Need finale layers that escalate without changing the whole rendering pipeline.

Phase 1:

- machinery startup
- slow emergency pulse
- low alarm layer
- initial power-fault sparks

Phase 2:

- stronger alarm layer
- faster red-light response
- heavier machinery vibration
- Warden re-entry cue

Phase 3:

- fastest emergency pulse
- intermittent sparks/dust
- high-intensity but short alarm layer
- final stabilization countdown texture/audio cues
- final release sting

Mobile requirement:

- no heavy volumetric fog dependency
- particle counts must scale down cleanly
- avoid many simultaneous shadowed lights

## P0 — v0.19.3 co-op assets retained

### SYNC panels

- industrial A/B panel body
- Maintenance/Flooded/Archive variants
- button/switch
- NO POWER / ARMED / COMPLETE states
- relay/cable connections
- small non-protective indicator light

Animations/audio:

- switch press
- armed pulse
- paired success
- timeout reset
- relay clicks
- synchronization tone

### Emergency team-light fixture

- clearly protective emergency fixture
- startup/flicker
- stable powered state
- shutdown state
- strong visual distinction from dim route lighting

Audio:

- startup
- powered hum
- optional 10-second warning
- shutdown

### Team-tension audio

- subtle radio/static increase when survivors split
- distant environmental activity escalation
- teammate interference cue
- short regroup relief option

Do not use a large arcade danger alarm for normal team separation.

## P0 — v0.19.2 readability / exploration retained

### Sector identity kit

- `M-01 MAINTENANCE`
- `F-02 FLOODED SERVICE`
- `A-03 ARCHIVE`
- `L-04 LOCKDOWN`
- M-07 / F-09 / A-12 plates
- directional arrows
- worn stencils
- warning stripes
- route legend

Color language:

- Maintenance — dirty yellow/amber
- Flooded Service — desaturated blue
- Archive — industrial green
- Lockdown — emergency red

### Conduit / pipe kit

- straight modular conduit
- elbows
- T-junctions
- cable trays
- pipe brackets
- wall/ceiling mounts
- damaged variants
- yellow/blue/green/red painted variants

Prefer shared atlases/materials and collision-free decorative modules where possible.

### Shortcut doors

- maintenance service hatch/door
- frame
- mechanical latch
- LOCKED FROM OTHER SIDE state
- open state
- latch/open/metal scrape audio

### Optional-room dressing

M-07 Storage:

- shelves
- battery/medical cases
- tool boxes
- conduit spare parts
- lockers

F-09 Pump Annex:

- pumps
- manifolds
- drains
- valves
- water-stain decals
- emergency water storage

A-12 Records Annex:

- archive boxes
- shelves
- cabinets
- loose folders/papers
- inventory tags
- medical/storage case

## P0 — v0.19.1 encounter / hazard assets retained

Steam:

- damaged steam outlet
- pipe pressure fixtures
- steam burst VFX
- low-overdraw mobile version
- pressure cue
- burst hiss

Electrical:

- electrified puddle material
- broken junction box
- exposed cable
- sparks/arcs
- floor-current pulse
- electrical buzz/discharge
- warning decals

Horror events:

- 4–6 distant metal-slam variants
- fake concrete/metal footsteps
- fluorescent failure/flicker
- blackout power-down/recovery
- fake shadow silhouette
- cloth/scrape movement cue

## P0 — Existing Arc enemies

### The Mourner

- final rigged tall humanoid
- mobile LOD
- idle/listen/stalk/investigate/search
- light-slow reaction
- turn animations
- attack
- dragging footsteps
- cloth/body creak
- breathing/moan

### The Crawler

- final distorted crawling body
- mobile LOD
- idle/slow/fast crawl
- light hesitation
- directional turns
- search/listen
- attack lunge
- hand/claw floor contacts
- pursuit audio

### The Tenant

- final rigged humanoid horror model
- freeze pose/transition
- unseen walk
- panic chase
- search/investigate
- attack

### Darkness Creature

- distinct non-Tenant silhouette
- crawl/search
- attack
- light recoil
- retreat/dissolve

## P0 — Survivor

Need production multiplayer survivor set:

- one base rigged survivor
- 3–4 outfit/material variants
- first-person hands/arms
- world flashlight attachment
- backpack/utility attachment points
- low-cost remote-player LOD

Animations:

- idle
- walk/run
- strafe/turn
- jump takeoff
- airborne/fall
- landing
- downed idle/crawl
- revive teammate
- being revived
- hit
- death/team-wipe

## P0 — Core Labyrinth environment

Materials:

- clean/dirty concrete
- wet concrete
- painted plaster
- tile
- rusty metal
- structural dark metal
- grime/water/blood decals
- warning stripe decals

Objective props:

- Fuse A/B/C
- Pressure Valve A/B
- Breaker A/B/C
- Lockdown Console
- checkpoint safe-light pillar
- heavy gate/bulkhead

Lighting fixture states:

- OFF
- DIM AMBIENT
- FAULT / FLICKER
- SAFE / POWERED
- SYNC SUPPORT
- LOCKDOWN PHASE PULSE

## P0 — Labyrinth audio layers

Need layered ambience:

- original maze room tone
- Maintenance electrical hum
- Flooded water/pipe ambience
- Archive ventilation/paper settling
- Lockdown machinery
- alarm layers for Phase 1/2/3
- shutter events
- Isolation Node failures
- Warden distant presence
- final gate release
- transition sting into The Outside

Footsteps:

- concrete walk/sprint
- wet concrete
- metal
- wood
- dirt/grass for Forest
- jump/landing
- downed crawl

## P1 — Forest / exterior retained

- visible sun disc
- visible moon disc
- dawn/day/dusk/night sky
- lightweight clouds
- mobile-safe fog
- forest tree/ground production assets
- cabin production kit
- gas station props
- warehouse props
- abandoned house props
- generator/workbench/storage/campfire props

All navigation-sensitive props need simple collision proxies.

## P1 — Front-end / multiplayer UI

- final DON'T LOOK BACK logo
- title key art 16:9
- mobile crop
- menu background
- button states/icons
- save/checkpoint/loading assets
- Ready/Host/Ping icons
- teammate HP/downed/revive treatment
- reconnect icon
- compact mobile layouts

## P2 — VFX / polish

Labyrinth:

- Isolation electrical collapse
- shutter dust/sparks
- Warden core pulse
- Warden subtle shadow distortion
- Lockdown Phase 1/2/3 sparks
- flooded ripples
- wet footsteps
- steam
- electrical puddle arcs
- blackout recovery
- final-gate dust/debris

Global:

- flashlight dust
- cold breath
- blood/bleeding feedback
- Darkness dissolve
- Tenant distortion
- campfire smoke/sparks
- generator exhaust
- wind-driven leaves

## Mobile + desktop constraints

- all new v0.20 guide lights should keep shadows disabled
- Warden final mesh requires at least one mobile LOD
- keep Warden materials compact; prefer one main body material + one core material
- use simple collision proxies for Isolation Nodes and shutters
- keep shutter geometry modular and cheap
- use shared atlases/materials for M/F/A/L signs and conduit
- avoid high-overdraw electrical/steam effects
- avoid large transparent surfaces for flooded areas
- world-space text/signage must remain legible at phone resolution
- strong safe-light and weak guidance-light visual languages must remain distinct
- do not rely on 4K textures except hero/menu art
- test 2–4 survivors + Warden + Encounter Director-selected enemies on mobile performance targets

## Recommended production order after v0.20

1. **The Warden production model + core locomotion/attack/audio**
2. **Isolation Node + Lockdown interlock kit**
3. **Temporary shutter model/animation/audio**
4. **Guidance floor/wall strip kit**
5. Sector signage + conduit kit
6. SYNC panel + emergency support-light kit
7. Hazard readability assets: steam/electric
8. Labyrinth spatial audio: fake footsteps/slams/blackout
9. Lockdown Phase 1/2/3 audio + VFX
10. Mourner final model/animation/audio
11. Crawler final model/animation/audio
12. Fuse/Valve/Breaker/Lockdown production props
13. Survivor model + movement/downed/revive animations
14. Tenant production model/animations
15. Darkness Creature production model/animations
16. Optional M-07/F-09/A-12 room dressing
17. Forest sky/sun/moon art pass
18. Exterior landmark production assets
19. Front-end branding/UI polish
