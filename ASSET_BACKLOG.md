# DON'T LOOK BACK — Asset Backlog

Updated for v0.15 Multiplayer Polish.

The project is still code/procedural-first. Most environment geometry, survivor avatars, loot, and UI use runtime primitives or text-only controls. This backlog tracks the production assets needed as gameplay systems mature.

## P0 — Character assets

### Survivor base character
Needed for co-op readability and v0.15 downed/revive gameplay.

Required:
- 1 rigged survivor base mesh
- 3–4 outfit/material variants for 2–4 players
- first-person hands/arms or a compatible first-person rig
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

## P0 — Audio

Current prototype audio is mostly procedural or minimal. Production audio is a major priority for horror readability.

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
- Save/autosave cue
- lobby ready/unready/start/reconnect UI cues

Initial target: roughly 35–50 one-shot SFX plus 5–8 looping ambience beds.

## P1 — Shelter and world props

Needed:
- generator
- campfire stones/logs
- cooking/boiling pot
- workbench
- storage chest
- bed
- table/chairs
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

## P1 — v0.15 multiplayer UI assets

The current v0.15 UI works with Godot controls and text. Final art should add:
- ready icon
- host crown/icon
- connection/ping icon set
- teammate health icon
- downed icon
- revive icon
- revive progress treatment
- reconnect icon
- player-color swatches / outfit identifiers
- lobby panel frame/background
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

## P2 — Menu / branding

Needed for the future front-end pass:
- DON'T LOOK BACK logo
- title-screen background/key art
- New Game / Continue / Host / Join button treatment
- loading indicator
- save-slot artwork
- settings icons
- app icon / Android adaptive icon
- splash screen

## Mobile constraints for all assets

Production assets should be authored with mobile and desktop in mind:
- prefer reusable trim/material sets instead of unique textures for every wall
- use LODs for survivor/monster/tree meshes
- keep transparent materials limited
- atlas small props/UI where practical
- avoid excessive 4K textures; reserve high resolution for hero assets
- provide lower-cost material/shadow variants for mobile quality settings

## Next asset integration target

v0.16 should begin replacing the highest-impact placeholders in this order:
1. survivor + downed/revive animation set
2. The Tenant model/animation
3. core footsteps + monster/audio ambience
4. labyrinth material kit + doors
5. flashlight and survival pickup models
6. cabin props
7. forest vegetation/rocks
8. gas-station / warehouse props
9. multiplayer UI icon pass
10. VFX and decals
