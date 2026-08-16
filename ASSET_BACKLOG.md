# DON'T LOOK BACK — Asset Backlog

Updated for **v0.19.3 — LABYRINTH CO-OP & TEAM TENSION**.

The prototype remains code/procedural-first. v0.19.3 adds paired co-op sync panels, temporary emergency safe-light pockets, team-separation pressure, and shared finite rewards while retaining full solo compatibility.

## P0 — New needs from v0.19.3

### SYNC panel kit

Need a production paired-panel family for Maintenance, Flooded Service, and Archive:

- industrial wall-mounted SYNC panel body
- A/B plate variants
- sector-color variants: dirty yellow, desaturated blue, industrial green
- chunky physical activation switch/button
- cable/conduit connection points
- locked/no-power state
- armed/waiting state
- paired-success state
- small indicator lamp that is clearly **not** a protective safe light

Animations:

- button/switch press
- relay engage
- armed pulse
- timeout/failure reset
- paired synchronization success

Audio:

- panel button clack
- relay click
- electrical handshake chirp
- armed countdown pulse
- timeout buzz
- successful two-panel synchronization tone

### Emergency team-light fixture

The 36-second support-light reward needs final art distinct from normal dim lamps:

- heavy emergency ceiling/wall fixture
- protected industrial lens/cage
- powered ON state
- short startup/flicker animation
- shutdown/fade state
- optional floor/wall safe-light marking

Audio:

- emergency lamp startup
- stable powered hum
- 10-second remaining warning optional
- shutdown click/power-down

Gameplay readability requirement:

- support light must be immediately recognizable as genuinely protective
- normal M/F/A/L route colors must not look equally safe
- safe-light readability must survive low-brightness mobile screens
- keep realtime shadows disabled for the temporary support lights

### Team-tension audio

The team-separation mechanic should eventually communicate pressure through sound instead of a large HUD:

- subtle radio/static increase when survivors are far apart
- distant footstep/metal activity escalation layer
- teammate radio interference cue
- short regroup relief sting optional
- support-light ambience that masks or lowers tension layers

Avoid explicit arcade warning sirens for normal separation. The horror should imply that splitting up is dangerous rather than display a large numeric danger meter.

### Co-op reward cache presentation

SYNC completion rewards need a small shared cache style:

- compact battery case for M-01
- emergency water container/crate for F-02
- medical wall box/case for A-03
- opened/claimed state optional
- shared-world pickup icon treatment

### Co-op signage

Need unobtrusive environmental instructions:

- `SYNC A`
- `SYNC B`
- `PAIRED EMERGENCY CIRCUIT`
- `TWO OPERATORS REQUIRED` variant for online flavor
- maintenance diagram showing two separated terminals feeding one emergency light

Solo mode must not visually imply a hard multiplayer requirement because solo can complete both panels sequentially.

## P0 — v0.19.2 readability/exploration assets retained

### Sector readability kit

- `M-01 MAINTENANCE` wall sign
- `F-02 FLOODED SERVICE` wall sign
- `A-03 ARCHIVE` wall sign
- `L-04 LOCKDOWN` wall sign
- M-07 / F-09 / A-12 number plates
- directional arrows
- worn stencils
- warning/hazard stripes
- wall route legend

Color language:

- Maintenance — dirty yellow/amber
- Flooded Service — desaturated blue
- Archive — industrial green
- Lockdown — emergency red

### Color-coded conduit / pipe kit

- horizontal/vertical conduit
- elbows / T-junctions
- cable trays
- brackets/mounts
- damaged variants
- yellow/blue/green/red painted stripe versions

Use shared materials/atlases and mostly opaque surfaces for mobile.

### Shortcut service door

- industrial service hatch
- concrete-compatible frame
- mechanical latch
- locked-from-other-side state
- open state
- latch pull / metal scrape / stop clunk audio

### Optional exploration bays

M-07 Storage:
- shelves
- battery crate
- medical box
- tool cases
- lockers

F-09 Pump Annex:
- pump assembly
- manifolds/pipes
- grates
- wet decals
- water storage

A-12 Records Annex:
- shelves
- archive boxes
- folders/papers
- damaged cabinets
- medical storage

## P0 — v0.19.1 encounter / hazard assets retained

Steam:
- damaged outlet
- pressure fixture
- burst VFX + mobile low-overdraw variant
- buildup cue
- steam hiss

Electrical:
- electrified puddle material
- exposed cable / junction box
- arcs/sparks
- floor-current pulse
- buzz/discharge audio

Random horror events:
- 4–6 distant metal slams
- fake concrete/metal footsteps
- ballast flicker
- blackout power-down/recovery
- shadow-crossing silhouette + scrape cue

## P0 — Arc 1 monsters

### The Mourner

- final tall narrow humanoid mesh
- rig + mobile LOD
- idle/listen
- stalk
- investigate
- light-slow reaction
- turns/search
- attack
- dragging footsteps / cloth creak / breathing / impact audio

### The Crawler

- final distorted low crawling mesh
- rig + mobile LOD
- idle/slow/fast crawl
- light hesitation/retreat
- directional turns
- search/listen
- attack lunge
- claw/hand contacts / crawl loop / lunge / hiss audio

### The Tenant

- final rigged humanoid horror model
- freeze transition
- unseen walk
- chase
- investigate/search
- attack

### Darkness Creature

- unique non-Tenant silhouette
- crawl/search
- attack
- light recoil
- retreat/dissolve

## P0 — Arc 1 environment / objectives

Maintenance:
- modular concrete walls
- Fuse A/B/C
- conduit/cable trays
- utility doors
- pipes
- grime/rust decals

Flooded Service:
- wet concrete
- shallow-water material
- pressure valves
- pipe network
- grates
- water leak VFX

Archive:
- shelves with simple collision proxies
- document boxes
- cabinets
- Breaker A/B/C
- aisle signs
- paper/debris

Lockdown:
- final console
- heavy gate/bulkhead
- security pillars
- alarm fixtures
- final beacon fixture

## P0 — Lighting / audio

Fixture states:
- OFF
- DIM AMBIENT
- FAULT / FLICKER
- SAFE / POWERED
- SYNC SUPPORT
- LOCKDOWN PULSE

Labyrinth ambience:
- Maintenance hum
- Flooded drip/pipe loop
- Archive ventilation/paper settling
- Lockdown machinery/alarm layers
- fake/real footsteps sharing some sonic language
- team-separation tension variants

Player/co-op:
- concrete/wet/metal footsteps
- jump/landing
- breathing/sprint breathing
- heartbeat
- damage/downed
- revive / being revived
- SYNC activation voice/breath effort optional

## P1 — Survivor / UI

Survivor:
- rigged base model
- 3–4 outfit/material variants
- first-person hands
- world flashlight
- movement/jump/landing
- downed crawl
- revive / being revived
- hit/death poses

Multiplayer UI:
- Ready/Host/Ping icons
- teammate HP/downed/revive
- reconnect icon
- compact mobile layouts
- subtle paired-SYNC status icon optional

Do not turn SYNC into a large permanent HUD objective because the stations are optional.

## P1 — Forest / exterior retained

- sun/moon discs
- day/dusk/night sky
- low-cost clouds/fog
- cabin kit
- gas station
- warehouse
- abandoned house
- generator/workbench/storage/campfire props

## P2 — VFX / polish

- SYNC relay sparks
- emergency-light startup flicker
- electric arcs
- steam
- shallow-water ripple
- wet footsteps
- blackout recovery sparks
- Lockdown pulse
- Mourner shadow distortion
- Crawler floor scrape/dust
- Darkness dissolve
- Tenant shadow distortion
- cold breath
- flashlight dust

## Mobile + desktop constraints

- SYNC panels should use shared materials and simple collision
- panel indicator lights remain low-energy/non-protective
- emergency support lights may be strong but keep shadows disabled
- avoid transparent overdraw-heavy steam/electric effects
- signage must remain legible at phone resolution
- route colors and SYNC indicators must remain distinguishable for color-impaired players through labels/shapes, not color alone
- use low-poly collision proxies for doors, panels, shelves, pipes and crates
- enemy meshes require LODs
- avoid 4K textures except hero/menu art

## Recommended production order after v0.19.3

1. SYNC panel A/B kit + interaction animation/audio
2. Emergency support-light fixture + powered hum/startup/shutdown
3. Sector signage + M/F/A/L conduit kit
4. Shortcut service door/hatch
5. M-07 / F-09 / A-12 room dressing
6. Team-tension / horror-event spatial audio
7. Steam/electric hazard production VFX/audio
8. Arc dim-light fixture kit
9. Mourner final model/animation/audio
10. Crawler final model/animation/audio
11. Fuse/Valve/Breaker/Lockdown objective props
12. Survivor production model + co-op animations
13. Tenant final model/animation
14. Darkness Creature final model/animation
15. Forest sky/sun/moon art
16. Front-end branding + multiplayer UI polish
