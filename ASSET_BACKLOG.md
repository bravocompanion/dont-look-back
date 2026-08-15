# DON'T LOOK BACK — Asset Backlog

Updated for v0.17 Main Menu / Game Flow.

The project is still code/procedural-first. v0.17 now has a functional responsive front end, pause menu, save summary, direct Host/Join flow, and local settings, but the menu and most of the game still use Godot primitives/text controls rather than production art.

## P0 — Front-end / branding assets

v0.17 makes these assets immediately useful rather than future-only.

Required:
- final `DON'T LOOK BACK` logo
- compact/mobile-safe logo variant
- title-screen key art, 16:9 with center-safe composition
- portrait-safe/mobile crop of the key art
- dark menu background treatment or subtle looping background plate
- menu panel/frame treatment
- button states: normal / focused / hover / pressed / disabled
- Continue / New Game / Host / Join / Settings icons
- Save / autosave / checkpoint icon
- loading / connecting spinner
- warning icon for destructive New Game confirmation
- pause/menu icon suitable for touch controls
- settings icons for audio, sensitivity, performance/FPS, fullscreen
- app icon + Android adaptive icon
- splash screen

Audio needed for the front end:
- menu move/focus
- menu select
- back/cancel
- confirmation warning
- save/autosave
- network connecting
- connection success
- connection failure
- Ready / Unready / Start / Reconnect cues

## P0 — Character assets

### Survivor base character
Needed for co-op readability, v0.15 downed/revive, and future animation integration.

Required:
- 1 rigged survivor base mesh
- 3–4 outfit/material variants for 2–4 players
- first-person hands/arms or compatible first-person rig
- world flashlight attachment point
- backpack/utility attachment points

Animation set:
- idle
- walk
- run
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
- unseen walk
- panic chase
- attack
- recoil/retreat
- silhouette-friendly materials

### Darkness Creature
Required:
- separate creature silhouette
- crawl/move
- attack
- retreat-from-light
- dissolve/disappear

## P0 — Core horror audio

Current prototype audio is still mostly procedural/minimal. Production audio remains one of the highest-impact upgrades.

Required first pass:
- concrete footsteps
- wood footsteps
- dirt/grass footsteps
- metal footsteps
- player breathing
- sprint breathing
- heartbeat/panic
- damage / bleeding reactions
- downed breathing
- revive start / loop / complete
- door open / close / locked rattle
- pickup
- crafting
- generator start / loop / stop
- campfire loop
- indoor electrical hum
- fluorescent flicker
- distant knocks
- forest day ambience
- forest night ambience
- wind
- distant branch snaps
- Tenant proximity cue
- Tenant movement / attack
- Darkness Creature whisper/crawl/attack/retreat
- Journal open/page cue

Initial target: roughly 40–55 one-shot SFX plus 5–8 looping ambience beds, including the v0.17 menu/network cues.

## P0 — Core environment art

Required modular sets:
- labyrinth concrete/plaster wall pieces
- labyrinth floor and ceiling modules
- apartment wall/floor/door kit
- metal/security door set
- cabin exterior/interior kit
- forest ground, rock, stump, branch and tree variants

Recommended reusable material library:
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

## P1 — Exterior landmark props

### Gas station
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

### Abandoned house
- damaged furniture
- cabinets
- broken doors/windows
- curtains
- household debris

## P1 — Multiplayer UI assets

The v0.15/v0.17 multiplayer UI is functional but text-based.

Needed:
- ready icon
- host crown/icon
- connection/ping icon set
- teammate health icon
- downed icon
- revive icon
- revive progress visual treatment
- reconnect icon
- player-color swatches / outfit identifiers
- lobby/session panel frame/background
- readable mobile versions of the same icons

## P1 — Journal assets

Needed variants:
- handwritten note
- maintenance memo
- receipt
- warning sheet
- ledger page
- water-pump service card
- diary/notebook page
- damaged/torn paper variants

Optional later:
- inspectable handwriting textures
- stamps, dates and facility logos
- photographs / polaroids

## P2 — VFX and polish

Needed:
- flashlight dust particles
- subtle fog volumes
- cold breath
- blood hit vignette/particles
- bleeding drips/decals
- infection visual feedback kept subtle
- campfire sparks/smoke
- generator exhaust
- Darkness Creature dissolve
- Tenant shadow distortion
- exterior wind-driven particles/leaves
- subtle menu background particles/noise if performance-safe

## Mobile constraints for all assets

Production assets must support both mobile and desktop:
- keep title/key art center-safe for narrow/portrait crops
- provide compact UI/icon variants rather than shrinking desktop art blindly
- prefer reusable trim/material sets instead of unique textures for every wall
- use LODs for survivor/monster/tree meshes
- keep transparent materials limited
- atlas small props/UI where practical
- avoid excessive 4K textures; reserve high resolution for hero assets
- provide lower-cost material/shadow variants for mobile quality settings
- UI icons should remain readable around 40–64 logical pixels

## Current integration status

Functional but still placeholder-heavy:
- main menu / pause menu / settings
- co-op session UI
- teammate HUD / revive progress
- survivor remote avatars
- Tenant / Darkness Creature visuals
- labyrinth / apartment / shelter / exterior geometry
- survival item models
- Journal paper visuals
- ambience and interaction audio

## Next recommended asset integration order

1. Front-end logo + title key art + menu SFX
2. Survivor model + downed/revive animation set
3. The Tenant model/animation
4. Core footsteps + monster/audio ambience
5. Labyrinth material kit + doors
6. Flashlight and survival pickup models
7. Cabin props
8. Forest vegetation/rocks
9. Gas-station / warehouse props
10. Multiplayer UI icon pass
11. VFX and decals

A dedicated art/audio integration pass is still required; v0.17 does not pretend the skipped v0.16 production-art milestone has been completed.
