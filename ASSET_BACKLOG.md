# DON'T LOOK BACK — Asset Backlog

Updated for **v0.19.2 — LABYRINTH READABILITY & EXPLORATION**.

The current prototype is still code/procedural-first. v0.19.2 adds sector identity, color-coded navigation language, optional exploration bays, one-way service shortcuts, and hidden cache/lore locations on top of the v0.19/v0.19.1 Arc 1 gameplay.

## P0 — New needs from v0.19.2

### Sector readability kit

Need a reusable Labyrinth navigation kit that stays readable in dim lighting without making the level feel arcade-like:

- `M-01 MAINTENANCE` wall sign
- `F-02 FLOODED SERVICE` wall sign
- `A-03 ARCHIVE` wall sign
- `L-04 LOCKDOWN` wall sign
- smaller room-number plates such as M-07 / F-09 / A-12
- directional arrow decals
- worn/stenciled number decals
- hazard/warning stripe decals
- wall-mounted route map / color legend

Color language:

- Maintenance — dirty yellow/amber
- Flooded Service — desaturated blue
- Archive — industrial green
- Lockdown — emergency red

The colors should remain readable on low-brightness mobile displays but must not resemble protective flashlight/safe-zone lighting.

### Color-coded conduit / pipe kit

Production replacement for the prototype emissive route bars:

- horizontal conduit segments
- vertical conduit segments
- elbows / junctions / T-junctions
- cable trays
- pipe brackets
- wall/ceiling mounts
- damaged/broken variants
- painted stripe versions in yellow/blue/green/red

Recommended approach:

- mostly opaque materials with subtle emission only where needed
- atlas/shared materials to reduce mobile draw calls
- simple collision or no collision for decorative conduit
- reusable modular lengths rather than unique meshes per corridor

### Shortcut door / service hatch

Two one-way shortcuts now need final presentation:

- industrial maintenance service door/hatch
- wall frame matching concrete Labyrinth modules
- mechanical latch/handle
- LOCKED FROM OTHER SIDE state
- UNLOCKED/OPEN state
- optional small indicator light

Animations/audio:

- latch pull
- heavy lock release
- metal scrape/open
- final stop/clunk
- optional rattling interaction from wrong side

The final art must preserve the current gameplay rule: the shortcut cannot visually imply it is usable from the early side.

### Optional exploration bays

M-07 Storage:

- maintenance storage shelving
- battery crate
- medical supply box
- tool cases
- spare conduit/pipe props
- small locker variants

F-09 Pump Annex:

- compact pump assembly
- pipe manifolds
- drainage grate
- valve hardware
- water-stained wall decals
- emergency bottled-water storage

A-12 Records Annex:

- archive boxes
- document shelves
- loose folders/papers
- damaged cabinet
- handwritten inventory labels
- small medkit/storage cabinet

Cache dressing:

- 3–5 crate variants
- open/closed supply cases
- cardboard archive boxes
- plastic maintenance bins
- straps/tape/labels

### Landmark silhouettes

Each sector needs one memorable landmark shape visible from several meters away:

- Maintenance: tall conduit/fuse pillar
- Flooded: pump/pipe tower
- Archive: distinctive shelf/sign column
- Lockdown: heavy red security structure

These should be recognizable by silhouette even when color visibility is poor.

### Exploration Journal props

New v0.19.2 notes need physical paper variants:

- Maintenance Color Code sheet
- A-12 inventory sheet / margin note
- wall-mounted route legend
- stained maintenance clipboard
- archive inventory form

## P0 — v0.19.1 Encounter / hazard assets retained

Steam hazards:

- damaged steam outlet
- pipe-pressure fixture
- steam burst VFX
- low-overdraw mobile steam variant
- pressure build-up cue
- burst hiss

Electrical hazards:

- electrified puddle material
- exposed cable / junction box
- electrical arcs/sparks
- floor-current pulse VFX
- idle buzz
- discharge crack
- high-voltage signage

Random horror events:

- 4–6 distant metal-slam variants
- fake concrete/metal footsteps
- fluorescent ballast flicker
- blackout power-down/recovery
- shadow-crossing silhouette material
- cloth/scrape movement cue

## P0 — Arc 1 monster assets

### The Mourner

Model:

- tall narrow humanoid silhouette
- rigged production mesh
- mobile LOD
- readable head/shoulder shape in dim corridors

Animations:

- idle/listen
- stalk
- investigate
- light-slow reaction
- turn left/right
- search
- attack

Audio:

- dragging footsteps
- cloth/body creak
- breathing/moan
- investigate cue
- attack impact

### The Crawler

Model:

- distorted low crawling silhouette
- rig for rapid directional changes
- mobile LOD

Animations:

- idle crawl
- slow crawl
- pursuit crawl
- light hesitation/retreat
- turn
- search/listen
- attack lunge

Audio:

- hand/claw concrete contacts
- fast crawl loop
- stop/listen cue
- lunge cue
- light retreat hiss

## P0 — Arc 1 environment modules

Maintenance:

- modular concrete walls
- fuse boxes A/B/C
- conduit/cable trays
- utility doors
- pipe clusters
- grime/rust decals

Flooded Service:

- wet concrete material
- shallow-water floor
- pipe network
- pressure valves
- drainage grates
- water leak VFX
- puddle decals

Archive:

- modular shelves with simple collision proxies
- document boxes
- cabinets
- breaker A/B/C panels
- aisle signs
- paper/debris props

Lockdown:

- final console
- heavy gate/bulkhead
- security pillars
- emergency fixtures
- powered final beacon
- alarm signs

## P0 — Lighting kit

Need fixture states for:

- OFF
- DIM AMBIENT
- FAULT / FLICKER
- SAFE / POWERED
- LOCKDOWN PULSE

Fixture variants:

- fluorescent strip
- cage light
- dirty maintenance lamp
- broken fixture
- wall emergency light
- safe/checkpoint lamp

Normal dim fixtures must remain visually distinct from genuinely protective safe light.

## P0 — Core survivor / horror assets retained

Survivor:

- rigged base survivor
- 3–4 outfit/material variants
- first-person hands
- world flashlight attachment
- idle/walk/run/jump/landing
- downed crawl
- revive / being revived
- hit/death poses

The Tenant:

- final rigged model
- freeze pose/transition
- unseen walk
- chase
- investigate/search
- attack

Darkness Creature:

- unique non-Tenant silhouette
- crawl/search
- attack
- light recoil
- retreat/dissolve

## P0 — Audio ambience

Labyrinth layers:

- Maintenance electrical hum
- Flooded pipe/drip ambience
- Archive ventilation/paper settling
- Lockdown machinery/alarm layers
- distant door slams
- fake and real footsteps that intentionally share some sonic language

Player:

- walk/sprint footsteps by surface
- jump/landing
- breathing/sprint breathing
- heartbeat/panic
- damage/bleeding
- downed/revive

## P1 — Forest / exterior retained

- visible sun disc
- visible moon disc
- dawn/day/dusk/night sky
- lightweight cloud layer
- mobile-safe fog
- cabin production kit
- gas station props
- warehouse props
- abandoned-house props
- generator/workbench/storage/campfire

All navigation-sensitive exterior props need simple collision proxies.

## P1 — Front-end / multiplayer UI

- final DON'T LOOK BACK logo
- title key art 16:9 + mobile crop
- menu background
- button states/icons
- save/checkpoint/loading assets
- Ready/Host/Ping/Downed/Revive icons
- reconnect icon
- compact mobile variants

## P2 — VFX / polish

- flashlight dust
- shallow-water ripples
- wet footsteps
- pipe leaks
- electrical sparks
- blackout recovery sparks
- Lockdown pulses
- final-gate debris/dust
- Mourner shadow distortion
- Crawler scrape/floor dust
- Darkness dissolve
- Tenant shadow distortion
- cold breath
- campfire smoke/sparks
- generator exhaust

## Mobile + desktop constraints

- prefer shared materials/atlases for signs and route markers
- keep decorative conduit collision-free where possible
- avoid many overlapping realtime lights
- most dim Labyrinth lamps should keep shadows disabled
- route colors must remain readable without high emission
- use simple collision proxies for doors, shelves, pumps, pipes and crates
- avoid transparent overdraw-heavy water/steam effects on mobile
- enemy meshes require LODs
- avoid 4K textures except hero/menu art
- world-space signage must remain legible at phone resolution

## Recommended production order after v0.19.2

1. Sector signage + yellow/blue/green/red conduit kit
2. Shortcut service door/hatch + latch animation/audio
3. M-07 / F-09 / A-12 optional-room dressing
4. Hazard readability pass: steam/electric assets + audio
5. Horror-event spatial audio: fake footsteps/slams/flicker/blackout
6. Arc dim-light fixture kit
7. Mourner production model/animation/audio
8. Crawler production model/animation/audio
9. Fuse/valve/breaker/Lockdown objective props
10. Arc ambience + Lockdown audio layers
11. Survivor production model + co-op animations
12. Tenant final model/animation
13. Darkness Creature final model/animation
14. Forest sky/sun/moon art pass
15. Front-end branding + multiplayer UI polish
