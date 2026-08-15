# DON'T LOOK BACK — Asset Backlog

Updated for v0.18.1 Labyrinth Lighting + Separate Forest Map.

The project remains code/procedural-first. v0.18.1 separates Labyrinth and Forest into different scenes and adds a functional loading transition. It also improves labyrinth readability with non-protective dim ambience lights. Production assets should now respect map boundaries, loading presentation, AI navigation clearance, mobile performance, and horror-light readability.

## P0 — v0.18.1 map-transition + labyrinth-light assets

Immediately useful:
- low-power labyrinth emergency/maintenance light fixture
- 2–3 fixture variations: intact, dirty, broken/flickering
- emissive material variants for OFF / DIM / POWERED states
- subtle ceiling/wall light stain or grime decal around fixtures
- Forest entrance terrain/tree-line/fence art to replace the current procedural back-boundary wall
- Forest entrance landmark treatment so the new map spawn feels intentional
- `THE OUTSIDE` loading-screen/key-art plate
- center-safe 16:9 loading composition
- mobile-safe narrow/portrait crop
- loading spinner/progress treatment
- optional small Labyrinth/Forest map-name icons

Transition audio:
- labyrinth exit mechanical/door tail
- short transition stinger
- low loading ambience bed or wind bridge
- Forest arrival wind/branch sting

Important lighting constraint:
- dim labyrinth fixtures are atmosphere/readability lights, not safe-zone lights
- relay lights remain the stronger visual/protective language
- production emissive intensity should preserve this distinction on both mobile and desktop

## P0 — AI character animation / presentation

### Survivor base character

Required:
- 1 rigged survivor base mesh
- 3–4 outfit/material variants for 2–4 players
- first-person hands/arms or compatible first-person rig
- world flashlight attachment
- backpack/utility attachment points

Animation set:
- idle
- walk
- run
- stop/start transitions
- directional turn / strafe
- crouch/downed idle
- downed crawl forward/back/strafe
- revive teammate
- being revived / stand-up
- hit reaction
- death/team-wipe pose

### The Tenant

Required:
- rigged humanoid horror model
- idle/freeze pose
- transition into/out of freeze
- slow unseen walk
- panic chase
- turn-left / turn-right or good body-turn support
- search/listen idle
- investigate walk
- attack
- recoil/retreat
- silhouette-friendly materials

### Darkness Creature

Required:
- distinct non-Tenant silhouette
- idle crouch/crawl
- crawl locomotion
- directional turn
- investigate/search motion
- attack
- recoil from light
- sustained retreat-from-light
- dissolve/disappear

## P0 — AI / horror audio

Movement set:
- concrete walk + sprint footsteps
- wood walk + sprint footsteps
- dirt/grass walk + sprint footsteps
- metal walk + sprint footsteps
- downed crawl cloth/body movement
- survivor breathing
- sprint breathing
- heartbeat/panic

Interaction noise set:
- normal door creak/open/close
- locked door rattle
- exit lock/key mechanism
- heavy exit door movement
- generator startup burst
- generator loop
- generator refuel/can handling
- workbench hammer/scrape
- hand-pump squeak/clank
- pickup
- crafting completion
- campfire loop

Monster perception cues:
- Tenant distant movement
- Tenant investigate/search cue
- Tenant proximity cue
- Tenant freeze/stop cue
- Tenant attack
- Darkness distant whisper/crawl
- Darkness investigate/search cue
- Darkness attack
- Darkness light-recoil cue
- Darkness retreat/dissolve cue

Environment beds:
- indoor electrical hum
- fluorescent flicker
- labyrinth room tone
- distant knocks
- forest day ambience
- forest night ambience
- wind
- distant branch snaps
- cabin ambience
- warehouse interior ambience
- gas-station exterior ambience

Production target remains roughly 50–70 one-shot SFX plus 7–10 looping ambience/mechanical beds, now including the Labyrinth → Forest transition.

## P0 — Front-end / branding

Required:
- final `DON'T LOOK BACK` logo
- compact/mobile-safe logo
- 16:9 center-safe title key art
- portrait/mobile-safe crop
- dark menu background or looping background plate
- menu panel/frame treatment
- button states: normal / focused / hover / pressed / disabled
- Continue / New Game / Host / Join / Settings icons
- save/autosave/checkpoint icon
- loading/connecting spinner
- warning icon
- touch-safe MENU icon
- settings icons
- app icon + Android adaptive icon
- splash screen

Front-end audio:
- focus/move
- select
- back/cancel
- warning confirmation
- save/autosave
- connecting
- connection success/failure
- Ready / Unready / Start / Reconnect

## P0 — Collision-safe environment art

The runtime waypoint graph is now map-specific. Production replacement geometry must preserve walkable clearance inside each scene.

Core modular sets:
- labyrinth concrete/plaster walls
- labyrinth floor/ceiling
- labyrinth light-fixture modules
- apartment wall/floor/door kit
- metal/security door set
- cabin exterior/interior kit
- forest ground/rocks/stumps/branches/tree variants
- believable Forest entrance blocker/terrain transition

Navigation-sensitive props:
- Warehouse shelving with clear aisle widths
- pallets/crates that do not silently close navigation corridors
- Abandoned House furniture with deliberate walk gaps
- House doorframes
- Gas Station pumps/counter/shelving with collision proxies
- water-pump collision proxy
- generator/workbench collision proxies

Use simple low-cost collision meshes instead of detailed render geometry for complex props.

Reusable material library:
- clean concrete
- dirty concrete
- painted plaster
- tile
- aged wood
- rusty metal
- asphalt
- dirt/grass
- corrugated roof metal
- grime/blood/water-stain decals

## P1 — Survival / shelter props

Needed:
- generator
- campfire stones/logs
- cooking/boiling pot
- workbench
- storage chest
- bed
- table/chairs
- flashlight first-person/world model
- fuel can
- flashlight battery
- canned food
- clean-water bottle
- dirty-water container
- medkit
- bandage
- cloth bundle
- scrap
- wood bundle
- hand water pump

Useful interaction animation:
- generator pull/start
- workbench craft hands
- pump handle
- pickup/use hand poses

## P1 — Exterior landmark props

### Gas Station
- fuel pumps
- canopy/sign
- counter
- shelving
- broken refrigerator/freezer
- road signage
- trash/debris

### Warehouse
- pallet variants
- industrial shelving
- crates
- barrels
- hanging lamps
- warning signs

### Abandoned House
- damaged furniture
- cabinets
- broken doors/windows
- curtains
- household debris

All landmark props need simplified collision and should be tested against Forest navigation after integration.

## P1 — Multiplayer UI

Needed:
- ready icon
- host crown/icon
- connection/ping icons
- teammate Health icon
- downed icon
- revive icon
- revive progress treatment
- reconnect icon
- player-color/outfit swatches
- lobby/session frame/background
- compact mobile variants
- optional `SYNCING MAP` status icon for scene synchronization

## P1 — Journal assets

Needed:
- handwritten note
- maintenance memo
- receipt
- warning sheet
- ledger page
- water-pump service card
- diary/notebook page
- damaged/torn paper variants

Optional:
- handwriting textures
- stamps/dates/facility logos
- photographs/polaroids

## P2 — VFX / polish

Needed:
- subtle dust from sprinting
- flashlight dust
- fog volumes
- cold breath
- blood hit vignette/particles
- bleeding decals
- subtle infection feedback
- campfire sparks/smoke
- generator exhaust
- Darkness dissolve
- Darkness light-recoil wisps
- Tenant shadow distortion
- exterior wind-driven leaves/particles
- subtle AI search/listen visual cue if animation alone is insufficient
- transition fade/grain treatment for map loading

## Mobile + desktop constraints

All production assets must support both targets:
- loading/key art must be center-safe for desktop and narrow mobile screens
- keep dim labyrinth lighting readable on low-brightness mobile displays without converting it into bright safe lighting
- use LODs for survivor, monsters, trees and landmark props
- keep skeleton/bone counts reasonable for 2–4 survivors plus monsters
- use simple collision proxies for navigation-sensitive props
- avoid excessive transparent materials
- prefer reusable/atlased materials
- reserve 4K textures for hero assets
- provide lower-cost shadow/material variants for mobile
- compress long ambience/mechanical loops appropriately
- keep important spatial one-shots short and reusable
- UI icons should remain readable around 40–64 logical pixels

## Current integration status

Functional but placeholder-heavy:
- main menu / pause / settings
- Labyrinth → Forest loading screen
- separate `main.tscn` / `forest.tscn` map flow
- co-op session UI
- teammate HUD / revive progress
- remote survivor avatars
- Tenant / Darkness Creature visuals
- AI CHASE / INVESTIGATE / SEARCH / PATROL
- labyrinth / apartment / shelter / exterior geometry
- labyrinth dim-light fixtures are currently invisible runtime light nodes
- Forest entrance boundary is procedural placeholder geometry
- survival item models
- Journal paper visuals
- footsteps / interaction / ambience audio

## Recommended integration order after v0.18.1

1. Labyrinth fixture model + concrete/material pass while preserving dim unsafe lighting
2. Real surface footsteps + door/generator/workbench/pump/transition SFX
3. Tenant model + freeze/search/investigate/chase animations
4. Darkness Creature model + crawl/search/light-retreat animations
5. Survivor model + walk/run/downed/revive animations
6. Branded title + `THE OUTSIDE` loading key art
7. Production doors + flashlight/survival pickups
8. Cabin props
9. Collision-safe Forest/House/Gas/Warehouse art + Forest entrance blocker
10. Multiplayer UI icon pass
11. VFX/decals and AI presentation polish

A dedicated art/audio integration pass remains required. v0.18.1 improves structure, visibility and map loading but does not mark production art/audio as complete.
