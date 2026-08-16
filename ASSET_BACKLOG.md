# DON'T LOOK BACK — Asset Backlog

Updated for **v0.19 — ARC 1: THE LABYRINTH**.

The project is still code/procedural-first. v0.19 adds a large lower Labyrinth, two new enemy archetypes, more objective props, 24+ additional dim-light points across the old/new maze, flooded/archive/lockdown sectors, and a final stabilization holdout. Production art/audio now needs to catch up with the gameplay depth.

## P0 — New needs from v0.19 Arc 1

### The Mourner

Need a final monster distinct from The Tenant:
- tall narrow humanoid silhouette
- rigged body
- damaged/maintenance-worker visual language optional
- strong readable head/shoulder silhouette in dim light
- low-cost LOD for mobile

Animations:
- idle/listen
- slow stalk
- investigate noise
- light-slow reaction
- turn left/right
- short attack
- hit/contact follow-through
- search idle

Audio:
- distant dragging footstep
- cloth/body creak
- listen/investigate cue
- close breathing/moan
- attack impact
- light discomfort cue

### The Crawler

Need a final low-profile creature clearly different from Tenant/Mourner/Darkness Creature:
- quadruped or distorted crawling humanoid
- low silhouette that remains visible near floor-level dim lamps
- rig suitable for fast directional turns
- mobile LOD

Animations:
- crawl idle
- slow crawl
- fast pursuit crawl
- light retreat/hesitation
- turn-in-place
- attack lunge
- search/sniff/listen

Audio:
- hand/claw contact on concrete
- fast crawl loop
- stop/listen cue
- lunge/attack cue
- light retreat hiss

### Arc 1 environment kit

Maintenance Wing:
- modular concrete wall segments
- exposed conduit/cable trays
- fuse-box variants A/B/C
- maintenance signs/numbers
- pipe clusters
- rust/water stains
- ceiling maintenance fixtures
- damaged utility doors

Flooded Service:
- shallow-water floor material
- wet concrete variants
- pipe network
- pressure valve wheel + body
- drainage grates
- leaking-pipe VFX
- puddle/water decals
- warning signage
- small debris props

Archive:
- archive shelf modules with simple collision proxies
- document boxes
- broken cabinets
- breaker panels A/B/C
- maintenance tags showing B → A → C
- papers/folders/debris
- numbered aisle signs

Lockdown:
- final control console
- industrial pillars
- heavy security bulkhead/gate
- alarm light fixtures
- emergency signs
- final exit/security door
- powered final-beacon fixture
- cable/power-core props

### Arc 1 lighting

Dim maintenance fixtures:
- intact dim fixture
- dirty/yellowed fixture
- broken fixture
- flickering fixture
- cage light
- wall-mounted emergency lamp

Material/emissive states:
- OFF
- DIM AMBIENT
- FAULT/FLICKER
- SAFE/POWERED
- LOCKDOWN PULSE

Important gameplay rule:
- normal Arc ambient lamps must visually remain weaker than flashlight, relay lights and safe checkpoint lamps
- dim fixture art must not imply monster protection
- safe lamps need a clearly stronger color/intensity language

### Arc 1 interaction props

Need final models for:
- Fuse Box A/B/C
- Pressure Valve A/B
- Archive Breaker A/B/C
- Lockdown Console
- checkpoint/safe-light pillar
- gate/bulkhead modules

Interaction animation/audio:
- fuse insertion/switch clunk
- valve wheel turn + pipe pressure
- breaker toggle
- wrong breaker electrical fault
- blackout alarm
- gate release/heavy metal movement
- Lockdown console startup
- 2-minute stabilization alarm loop with intensity variants
- stabilization complete cue

### Arc 1 ambience

Need layered loops/stingers:
- lower-labyrinth room tone
- Maintenance electrical hum
- Flooded Service drip/pipe ambience
- distant water movement
- Archive low ventilation/hum
- paper/shelf settling noises
- Lockdown machinery loop
- emergency alarm pulse
- blackout electrical failure
- final gate release
- transition sting into The Outside

## P0 — Core character assets retained

### Survivor
- 1 rigged survivor base mesh
- 3–4 outfit/material variants for 2–4 players
- first-person hands/arms
- world flashlight attachment
- backpack/utility attachment points

Animations:
- idle
- walk/run
- jump takeoff
- airborne/fall
- landing
- strafe/turn
- downed idle/crawl
- revive teammate
- being revived
- hit reaction
- death/team-wipe pose

### The Tenant
- rigged humanoid horror model
- freeze pose + transition
- unseen walk
- panic chase
- search/listen
- investigate
- attack
- turn support

### Darkness Creature
- unique non-humanoid/non-Tenant silhouette
- idle/crawl
- investigate/search
- attack
- light recoil
- retreat
- disappear/dissolve

## P0 — Movement / horror audio retained

Footsteps:
- concrete walk + sprint
- wet concrete
- metal
- wood
- dirt/grass
- landing variants
- jump exertion
- downed crawl

Player:
- breathing
- sprint breathing
- heartbeat/panic
- damage/bleeding
- revive/downed

Core interactions:
- normal door
- locked door rattle
- heavy exit door
- pickup
- crafting
- generator
- workbench
- water pump
- campfire

## P0 — Environment materials

Reusable sets:
- clean concrete
- dirty concrete
- wet concrete
- painted plaster
- tile
- rusty metal
- dark structural metal
- aged wood
- asphalt
- dirt/grass
- grime/blood/water-stain decals
- warning paint/stripe decals

Recommended Labyrinth texture strategy:
- use reusable tileable materials rather than unique textures per wall
- 1K/2K sources with mobile-scalable imports
- normal + roughness maps where they materially improve readability
- decals for variation instead of many unique materials

## P0 — Forest / celestial presentation retained

- visible sun disc
- visible moon disc
- dawn/day/dusk/night sky gradients or lightweight procedural sky
- stars optional
- 2–4 cloud variants / low-cost cloud layer
- day/night cloud tint
- mobile-safe sky material
- subtle moon halo
- tree silhouettes readable at night
- fog that does not crush mobile visibility

## P0 — Front-end / loading retained

- final DON'T LOOK BACK logo
- 16:9 title key art
- mobile/portrait crop
- menu background
- button states
- Continue/New Game/Host/Join/Settings icons
- save/checkpoint icon
- loading spinner
- warning icon
- MENU icon
- app icon/splash
- THE OUTSIDE loading plate

Audio:
- focus/select/back
- warning
- save/autosave
- connection success/failure
- Ready/Start/Reconnect
- map transition sting

## P1 — Survival props

- flashlight FP/world model
- battery
- canned food
- bottled water / dirty water
- medkit
- bandage
- cloth
- fuel can
- wood
- scrap
- generator
- campfire
- boiling pot
- workbench
- storage chest
- bed/table/chairs
- hand water pump

## P1 — Exterior landmark props

Cabin:
- porch/entry step
- threshold
- exterior light fixture
- interior furniture
- generator/shelter props

Gas Station:
- pumps
- canopy/sign
- counter/shelving
- broken fridge
- signs/debris

Warehouse:
- pallets
- shelves
- crates/barrels
- lamps
- warning signs

Abandoned House:
- damaged furniture
- cabinets
- broken doors/windows
- curtains/debris

All navigation-sensitive props need simple collision proxies.

## P1 — Journal / multiplayer UI

Journal paper variants:
- maintenance route sheet
- breaker tag
- lockdown procedure
- handwritten note
- receipt
- ledger
- warning sheet
- diary page
- torn/damaged variants

Multiplayer UI:
- Ready/Host/Ping icons
- teammate HP/downed/revive icons
- revive progress treatment
- reconnect icon
- player color swatches
- compact mobile layouts

## P2 — VFX / polish

Arc 1:
- electrical fault sparks
- blackout flicker
- pipe steam/leak
- shallow-water ripple
- wet-footstep splash
- lockdown alarm pulse
- final gate dust/debris
- Mourner subtle shadow distortion
- Crawler floor dust/scrape

Global:
- flashlight dust
- fog volumes
- cold breath
- blood/bleeding decals
- infection feedback
- campfire sparks/smoke
- generator exhaust
- Darkness dissolve/light recoil
- Tenant shadow distortion
- wind-driven leaves
- loading fade/grain

## Mobile + desktop constraints

- Arc 1 lamps should use low-cost OmniLights; most dim lamps should keep shadows off
- limit overlapping realtime lights on mobile
- enemy final meshes need LODs
- prefer one skeleton/skin material budget per monster where possible
- use simple collision proxies for shelves, pipes and gates
- minimize transparent flooded-water overdraw
- keep dim-lamp readability on low-brightness phone displays
- keep objective controls large/readable enough for first-person mobile interaction
- keep co-op remote survivor + four Arc enemies within mobile draw-call budget
- avoid 4K textures except hero/menu art

## Recommended production order after v0.19

1. Arc 1 dim fixture + concrete/metal material kit
2. Mourner model + core stalk/listen/attack animations
3. Crawler model + crawl/light-retreat/attack animations
4. Arc objective props: fuse/valve/breaker/console
5. Arc audio pass: ambience, switches, alarms, enemy cues
6. Survivor final model + movement/downed/revive animations
7. Tenant final model + animation pass
8. Darkness Creature final model + animation pass
9. Archive/Flooded/Lockdown environment props
10. Forest sky/sun/moon art pass
11. Cabin/exterior landmark production props
12. Front-end branding + multiplayer UI polish
