# DON'T LOOK BACK — Asset Backlog

Updated for **v0.21 — LABYRINTH EVACUATION & LIVING MAZE**.

The prototype is still code/procedural-first. v0.21 adds the reverse evacuation finale, two emergency override stations, a dedicated Evacuation Warden, ten reverse-route emergency strobes, temporary structural shutters and a new extraction point near the M-01 entrance.

## P0 — New needs from v0.21

### Evacuation override kit

Need production art for the two mandatory reverse-route controls:

- A-03 Emergency Override
- F-02 Extraction Override
- industrial wall-mount body
- heavy manual switch / breaker handle
- emergency-red waiting state
- restored green state
- cable/conduit connections
- sector-specific wear / labels
- simple collision proxy

Animations:

- cover/open action optional
- handle pull / breaker throw
- relay lock-in
- successful circuit restore

Audio:

- heavy switch pull
- relay clack
- electrical reconnect surge
- short success confirmation
- loud environmental power thump used as AI-noise language

Gameplay readability:

- override must be recognizable from 4–6 meters
- must not visually resemble a normal Archive breaker
- green restored state must not look like a permanent safe light
- mobile version needs readable state at low screen brightness

### Evacuation emergency-light kit

Need final replacement for the ten procedural reverse-route strobes:

- red/orange industrial strobe fixture
- ceiling version
- wall version
- arrow/chevron version
- damaged/flickering variant
- EXIT / EVAC / M-01 directional signage
- low-cost emissive-only LOD variant

Required states:

- OFF
- evacuation pulse
- unstable rapid pulse
- critical-state pulse

Important gameplay rule:

- evacuation strobes are **not protective lights**
- final M-01 extraction beacon must be visually much stronger and clearly safe/usable
- most strobe lights should keep realtime shadows disabled

Audio:

- evacuation pulse hum
- intermittent electrical buzz
- relay ticking
- distant alarm layer
- critical-state faster alarm layer

### M-01 extraction beacon

Need a final extraction fixture near the lower-Labyrinth entrance:

- strong industrial emergency beacon
- green/white extraction lens
- wall or ceiling route marker
- extraction floor marking
- EXIT / SURFACE / EVAC text treatment
- powered/armed state

Audio:

- extraction armed confirmation
- stable powered beacon hum
- final transition sting into Forest

### Evacuation shutter / route-collapse kit

Temporary v0.21 shutters need production replacements:

- fast emergency blast shutter
- damaged rolling gate variant
- segmented industrial bulkhead
- track/frame modules
- warning light strip
- floor stop / guide rail

Animation:

- rapid close
- impact/clunk
- vibration/hold
- automatic reopen after several seconds

Audio:

- motor wind-up
- metal slam
- stressed metal vibration
- reopen motor
- final stop clunk

VFX:

- dust kick on close
- small debris
- optional sparks

Gameplay constraint:

- shutters must communicate that they are temporary
- geometry must never look like a permanent dead end
- mobile collision should remain one simple proxy

### Evacuation Warden presentation

The v0.21 dedicated evacuation instance uses the same Warden creature but needs a stronger escape-state presentation rather than a second model.

Additional animation needs:

- evacuation re-entry / wake pose
- faster pursuit locomotion
- critical-state pursuit variant
- aggressive corner turn
- heavy corridor stop/listen
- extraction-denial attack optional

Additional audio:

- evacuation spawn/re-entry sting
- heavy pursuit loop
- increasing footstep cadence
- distant core pulse
- critical-state roar / mechanical strain
- near-extraction pressure cue

VFX:

- stronger chest/core pulse
- subtle red reflection response under evacuation lights
- short appearance distortion
- critical-state core intensity variant

### Reverse-route ambience

Need layered finale audio that changes as the player moves backward through the Arc:

- Lockdown evacuation siren
- Archive alarm bed
- Flooded Service pressure alarms
- Maintenance emergency relay hum
- distant structural impacts
- intermittent shutter movement
- electrical failure pops
- Warden heavy footsteps that can travel between sectors

Critical-state layer:

- faster alarm rhythm
- heavier building groans
- stronger electrical instability
- reduced quiet gaps

Avoid a constant loud action-game mix. There should still be brief gaps where the Warden is heard more clearly than the alarm.

## P0 — Retained v0.20 assets

### The Warden

Model direction:

- broad-shouldered industrial/humanoid horror silhouette
- heavier upper body than The Mourner
- narrow/masked head shape
- readable chest/core feature
- mobile LODs
- simple collision proxy

Core animations:

- heavy idle
- deliberate pursuit walk
- isolated-target acceleration
- safe-light hesitation
- turn left/right
- search/listen
- heavy attack
- attack recovery
- Lockdown aggressive variant

Core audio:

- heavy footsteps
- body/mechanical creaks
- chest/core pulse
- close breathing/growl
- attack impact
- safe-light discomfort cue

### Isolation Node kit

Need three themed production nodes:

- M-01 Maintenance Isolation Node
- F-02 Flooded Isolation Node
- A-03 Archive Isolation Node

Shared states:

- sealed/no power
- active
- shutdown
- fault surge

Need:

- industrial housings
- switches / handles
- cables
- sector labels
- electrical fault VFX
- shutdown animation
- shutdown SFX

### Lockdown interlock

Need final physical cover around the Lockdown Console:

- heavy isolation cover
- locking bars
- status indicator
- 0/3 → 3/3 state language
- unlock/retract animation
- heavy mechanical unlock audio

### Isolation route shutters

Retain:

- temporary industrial shutters
- fault warning light
- close/open animation
- short metal slam SFX
- dust/sparks optional

### Major guidance-light kit

Need production replacement for v0.20 floor/wall guide strips:

- low-energy amber route strip
- emergency red Lockdown strip
- damaged strip variants
- modular straight/corner pieces
- low-cost emissive material

These lights are navigation aids, not safe lights.

## P0 — Retained v0.19.3 co-op assets

### SYNC panel kit

- industrial SYNC A/B panel body
- Maintenance/Flooded/Archive variants
- no-power state
- armed state
- timeout state
- paired-success state
- physical switch/button
- relay animation

Audio:

- button clack
- relay click
- armed pulse
- timeout buzz
- paired success tone

### Temporary team safe-light

- strong emergency fixture
- startup flicker
- powered state
- shutdown state
- clear protective-light visual language

### Team-tension audio

- subtle radio/static increase when survivors separate
- teammate interference
- distant activity escalation
- regroup relief cue

## P0 — Retained v0.19.2 exploration assets

### Sector navigation kit

- M-01 Maintenance signage
- F-02 Flooded Service signage
- A-03 Archive signage
- L-04 Lockdown signage
- M-07 / F-09 / A-12 room plates
- directional arrows
- worn stencils
- warning decals
- route legend

Color language:

- Maintenance — dirty yellow
- Flooded — desaturated blue
- Archive — industrial green
- Lockdown — emergency red

### Conduit / pipe navigation kit

- straight pipe/conduit modules
- vertical modules
- elbows
- T-junctions
- brackets
- cable trays
- damaged variants
- yellow/blue/green/red painted variants

### Service shortcut doors

- industrial service hatch
- latch/handle
- locked-from-other-side state
- open state
- latch release animation
- metal scrape/clunk audio

### Optional room dressing

M-07 Storage:

- tool cases
- shelves
- battery crate
- medical box
- maintenance bins

F-09 Pump Annex:

- compact pumps
- pipe manifolds
- drainage props
- water storage

A-12 Records Annex:

- archive boxes
- document shelves
- folders/papers
- damaged cabinet
- med storage

## P0 — Retained v0.19.1 hazard / event assets

Steam:

- damaged steam outlet
- pressure-pipe fixture
- low-overdraw steam VFX
- buildup cue
- burst hiss

Electrical:

- electrified puddle material
- exposed cable/junction box
- electrical arcs/sparks
- floor-current pulse
- buzz/discharge audio

Random horror events:

- 4–6 distant metal-slam variants
- fake concrete/metal footsteps
- fluorescent flicker audio
- blackout power-down/recovery
- fake shadow silhouette
- movement scrape/cloth cue

## P0 — Core monster assets

### The Tenant

- final rigged humanoid horror model
- freeze pose / transition
- unseen walk
- chase
- investigate/search
- turn support
- attack
- shadow distortion

### Darkness Creature

- unique non-Tenant silhouette
- crawl/search
- attack
- light recoil
- retreat
- dissolve/disappear

### The Mourner

- tall narrow rigged monster
- mobile LOD
- idle/listen
- stalk
- investigate
- light-slow reaction
- turn
- attack
- dragging footsteps / breathing / attack audio

### The Crawler

- low distorted crawler rig
- mobile LOD
- slow crawl
- fast pursuit
- light hesitation
- turn
- search/listen
- lunge attack
- crawl/contact audio

## P0 — Survivor assets

Need one production survivor base with 3–4 multiplayer variants.

Model:

- rigged survivor
- outfit/material variants
- first-person arms/hands
- world flashlight attachment
- backpack/utility points

Animations:

- idle
- walk/run
- strafe
- jump takeoff
- fall
- landing
- turn
- downed idle
- downed crawl
- revive teammate
- being revived
- hit reaction
- death/team-wipe pose

## P0 — Arc 1 environment modules

Maintenance:

- modular concrete walls
- fuse boxes A/B/C
- cable trays/conduit
- utility doors
- pipes
- grime/rust decals

Flooded Service:

- wet concrete
- shallow-water material
- pipe network
- pressure valves
- drainage grates
- leak VFX
- water decals

Archive:

- shelf modules
- document boxes
- cabinets
- breaker A/B/C panels
- aisle signs
- paper/debris props

Lockdown:

- final console
- heavy bulkhead
- pillars
- alarm lights
- industrial cables
- emergency signs

All navigation-sensitive props need simple collision proxies.

## P0 — Lighting states

Production fixtures need:

- OFF
- DIM AMBIENT
- FAULT / FLICKER
- SAFE / POWERED
- LOCKDOWN PULSE
- EVACUATION PULSE
- EVACUATION CRITICAL

Normal ambient and evacuation-route lights must remain distinct from genuinely protective safe lights.

## P0 — Core audio

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
- hurt/bleeding
- downed/revive

Interactions:

- normal door
- locked door
- heavy gate
- fuse
- valve
- breaker
- isolation node
- evacuation override
- SYNC panel
- pickup
- generator/workbench/water pump

## P1 — Forest / exterior retained

- visible sun disc
- visible moon disc
- day/dawn/dusk/night sky
- lightweight cloud layer
- stars optional
- mobile-safe fog
- cabin production kit
- gas station kit
- warehouse props
- abandoned-house props
- generator/workbench/storage/campfire

## P1 — Front-end / multiplayer UI

- final DON'T LOOK BACK logo
- 16:9 title art
- mobile crop
- menu background
- button states/icons
- loading spinner
- warning/save/checkpoint icons
- Ready/Host/Ping icons
- teammate/downed/revive icons
- reconnect icon
- compact mobile layouts

Evacuation UI should remain primarily environmental/HUD text rather than adding a large arcade timer panel.

## P2 — VFX polish

- evacuation dust/debris
- shutter sparks
- Warden core pulse
- Warden appearance distortion
- flashlight dust
- shallow-water ripple
- wet-footstep splash
- pipe leaks
- electrical sparks
- blackout recovery sparks
- Lockdown pulse
- final extraction light bloom
- Darkness dissolve
- Tenant distortion
- cold breath
- campfire smoke/sparks

## Mobile + desktop constraints

- all new evacuation strobes should keep shadows disabled unless proven affordable
- use shared materials/atlases for signage and emergency-light variants
- avoid volumetric evacuation fog as a required gameplay effect
- use low-overdraw particles for dust/sparks
- Warden, Mourner, Crawler and survivor meshes require mobile LODs
- keep decorative conduit collision-free where possible
- use simple collision proxies for shutters/panels/doors/shelves
- avoid 4K textures except hero/menu art
- test all red/orange/green state colors at low phone brightness
- temporary shutters must remain readable without creating visual confusion about permanent routes

## Recommended production order after v0.21

1. Evacuation Override A/F production panels + interaction audio
2. Evacuation strobe + directional signage kit
3. M-01 extraction beacon + final transition audio
4. Temporary evacuation shutter + animation/audio
5. Warden production model + evacuation pursuit animation/audio
6. Isolation Node + Lockdown interlock kit
7. Sector signage + colored conduit kit
8. Hazard VFX/audio pass
9. Mourner production model/animation/audio
10. Crawler production model/animation/audio
11. Survivor production model + co-op animations
12. SYNC panel + temporary safe-light kit
13. Arc ambience layers including evacuation mix
14. Tenant final model/animation
15. Darkness Creature final model/animation
16. Forest sky/sun/moon art pass
17. Exterior production props
18. Front-end branding/UI polish
