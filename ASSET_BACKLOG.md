# DON'T LOOK BACK — Asset Backlog

Updated for v0.18 AI + Navigation Pass.

The project remains code/procedural-first. v0.18 adds runtime AI navigation, hearing, last-known-position search and host-authoritative interaction noise, which increases the importance of readable character animation, surface audio, spatial interaction SFX and collision-safe environment art.

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

The v0.18 hearing system distinguishes normal movement from sprinting, so the walk/run animation cadence should be clear enough to match different footstep intensities.

### The Tenant

Required:
- rigged humanoid horror model
- idle/freeze pose
- transition into/out of freeze
- slow unseen walk
- panic chase
- turn-left / turn-right or good root/body turning support
- search/listen idle
- investigate walk
- attack
- recoil/retreat
- silhouette-friendly materials

The model needs strong readable stop/freeze behavior because watching The Tenant still immediately stops pursuit movement.

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

v0.18 makes real spatial audio especially valuable because AI now reacts to gameplay noise events.

Required movement set:
- concrete walk footsteps
- concrete sprint footsteps
- wood walk footsteps
- wood sprint footsteps
- dirt/grass walk footsteps
- dirt/grass sprint footsteps
- metal walk footsteps
- metal sprint footsteps
- downed crawl cloth/body movement
- survivor breathing
- sprint breathing
- heartbeat/panic

Required interaction noise set:
- normal door creak/open/close
- locked door rattle
- exit lock/key mechanism
- heavy exit door movement
- generator startup burst
- generator mechanical loop
- generator refuel/can handling
- workbench hammer/scrape
- hand water-pump squeak/clank
- pickup
- crafting completion
- campfire loop

Required monster perception cues:
- Tenant distant movement
- Tenant investigate/search vocal or body cue
- Tenant proximity cue
- Tenant freeze/stop sting kept subtle
- Tenant attack
- Darkness distant whisper/crawl
- Darkness investigate/search cue
- Darkness attack
- Darkness light-recoil cue
- Darkness retreat/dissolve cue

Environment beds:
- indoor electrical hum
- fluorescent flicker
- distant knocks
- labyrinth room tone
- forest day ambience
- forest night ambience
- wind
- distant branch snaps
- cabin ambience
- warehouse interior ambience
- gas-station exterior ambience

Initial production target is now roughly 50–70 one-shot SFX plus 7–10 looping ambience/mechanical beds when menu/network audio is included.

## P0 — Front-end / branding assets

Still immediately needed from v0.17:
- final `DON'T LOOK BACK` logo
- compact/mobile-safe logo variant
- 16:9 center-safe title key art
- portrait/mobile-safe title crop
- dark menu background or subtle looping background plate
- menu panel/frame treatment
- button states: normal / focused / hover / pressed / disabled
- Continue / New Game / Host / Join / Settings icons
- save/autosave/checkpoint icon
- loading/connecting spinner
- destructive confirmation warning icon
- touch-safe MENU icon
- audio/sensitivity/performance/fullscreen settings icons
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

The current waypoint graph was authored around the procedural map dimensions. Production environment replacements should preserve readable walkable clearance or update navigation points at the same time.

Core modular sets:
- labyrinth concrete/plaster walls
- labyrinth floor/ceiling
- apartment wall/floor/door kit
- metal/security door set
- cabin exterior/interior kit
- forest ground/rocks/stumps/branches/tree variants

v0.18 navigation-sensitive props:
- Warehouse shelving with clear aisle width
- pallets/crates that do not silently close a navigation corridor
- Abandoned House furniture with deliberate walk gaps
- House doorway/doorframe modules
- Gas Station pumps/counter/shelving with collision proxies
- water-pump collision proxy
- generator/workbench collision proxies

For complex props, provide simple low-cost collision meshes rather than using detailed render geometry as collision.

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

Animations optional but useful:
- generator pull/start interaction
- workbench craft hand action
- pump handle action
- simple pickup/use hand poses

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

All landmark props need simplified collision and must be tested against monster waypoint routes after integration.

## P1 — Multiplayer UI assets

The v0.15/v0.17 multiplayer UI remains functional but text-based.

Needed:
- ready icon
- host crown/icon
- connection/ping icons
- teammate Health icon
- downed icon
- revive icon
- revive progress visual treatment
- reconnect icon
- player-color/outfit identifier swatches
- lobby/session panel frame/background
- compact mobile variants

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
- stamps/dates/facility logos
- photographs/polaroids

## P2 — AI / environmental VFX

Needed:
- subtle dust kick from sprinting on dry surfaces
- flashlight dust particles
- fog volumes
- cold breath
- blood hit vignette/particles
- bleeding drips/decals
- subtle infection feedback
- campfire sparks/smoke
- generator exhaust
- Darkness dissolve
- Darkness light-recoil wisps
- Tenant shadow distortion
- exterior wind-driven leaves/particles
- subtle visual head/body cue for monster searching/listening if animation alone is insufficient
- performance-safe menu background particles/noise

## Mobile + desktop constraints

All production assets must support both targets:
- use LODs for survivor, monsters, trees and landmark props
- keep skeleton/bone count reasonable for 2–4 co-op survivors plus monsters
- use simple collision proxies for navigation-sensitive props
- avoid excessive transparent materials
- prefer reusable/atlased materials
- reserve 4K textures for true hero assets; most props/environment should use lower resolution
- provide lower-cost material/shadow variants for mobile quality settings
- compress long ambience/mechanical loops appropriately instead of loading excessive uncompressed audio
- keep important spatial one-shot sounds short and reusable
- keep title/key art center-safe for narrow screens
- UI icons should remain readable around 40–64 logical pixels

## Current integration status

Functional but still placeholder-heavy:
- main menu / pause / settings
- co-op session UI
- teammate HUD / revive progress
- remote survivor avatars
- Tenant / Darkness Creature visuals
- AI CHASE / INVESTIGATE / SEARCH / PATROL logic
- labyrinth / apartment / shelter / exterior geometry
- survival item models
- Journal paper visuals
- footsteps / interaction / ambience audio

## Recommended integration order after v0.18

1. Real surface footsteps + door/generator/workbench/pump SFX so AI hearing has matching player feedback
2. Tenant model + freeze/search/investigate/chase animation set
3. Darkness Creature model + crawl/search/light-retreat animation set
4. Survivor model + walk/run/downed/revive animations
5. Front-end logo + title key art + menu SFX
6. Labyrinth material kit + production doors
7. Flashlight/survival pickup models
8. Cabin props
9. Collision-safe forest/House/Gas/Warehouse art
10. Multiplayer UI icon pass
11. VFX/decals and AI presentation polish

A dedicated art/audio integration pass remains required. v0.18 improves behavior and navigation but does not mark the previously skipped production-art/audio milestone as complete.
