# DON'T LOOK BACK — Asset Backlog

Updated for v0.18.4 Dynamic Sun + Moon Lighting.

The project remains code/procedural-first. v0.18.4 adds a clock-driven Forest sun/moon cycle on top of v0.18.3 jump, auto-step, cabin-entry and night-visibility work. Production art/audio should now support readable sunrise/day/dusk/night transitions without weakening the horror-light rules.

## P0 — New needs from v0.18.4

Dynamic sky / celestial presentation:
- visible sun disc or lightweight procedural sun representation
- visible moon disc with horror-appropriate size/brightness
- sunrise sky gradient/reference
- clear daytime sky gradient/reference
- warm dusk/sunset gradient/reference
- deep night sky gradient/reference
- optional stars layer for night
- 2–4 lightweight cloud variants or procedural cloud layer
- cloud tint variants for dawn/day/dusk/night
- mobile-safe sky material with minimal overdraw
- optional subtle moon halo that does not imply a safe zone

Lighting reference targets:
- sunrise around 06:00: low warm directional light
- noon around 12:00: strongest neutral daylight
- sunset around 18:00: low warm light fading out
- midnight around 00:00: cool dim moonlight
- powered shelter/campfire/flashlight must remain visually stronger and clearly different from moonlight

Important gameplay constraint:
- sun/daylight may support the existing daytime protective behavior
- moonlight and general Environment ambient light must remain atmospheric/readability lighting only
- moonlight must not visually read like a monster-repelling safe zone

## P0 — Movement / cabin needs from v0.18.3

Character movement:
- survivor jump takeoff animation
- airborne/fall pose
- landing animation
- short/low-step foot placement animation or animation blend
- optional procedural foot-IK target support later

Movement audio:
- jump exertion/breath cue
- soft landing
- hard landing variant for future fall-damage support
- wood porch/threshold footstep
- cloth/gear movement while airborne/landing

Cabin entrance:
- believable porch/entry-step model replacing the current procedural box
- worn wood/plank material
- threshold/door-sill piece with simple collision proxy
- small exterior cabin fixture for the current dim entrance light

Forest presentation:
- tree silhouettes readable across changing sun/moon angles
- fog layers that do not crush visibility on mobile
- subtle reflective/wet material variants for road/rocks where useful

## P0 — Character assets

### Survivor
- 1 rigged survivor base mesh
- 3–4 outfit/material variants for 2–4 players
- first-person hands/arms
- world flashlight attachment
- backpack/utility attachment points

Animation set:
- idle
- walk
- run
- jump takeoff
- airborne/fall
- land
- start/stop transitions
- strafe/turn
- downed idle
- downed crawl forward/back/strafe
- revive teammate
- being revived/stand-up
- hit reaction
- death/team-wipe pose

### The Tenant
- rigged humanoid horror model
- idle/freeze pose
- freeze transition
- unseen walk
- panic chase
- turn support
- search/listen idle
- investigate walk
- attack
- recoil/retreat

### Darkness Creature
- distinct non-Tenant silhouette
- idle/crawl
- directional turn
- investigate/search
- attack
- recoil from light
- retreat-from-light
- dissolve/disappear

## P0 — Horror / movement audio

Movement:
- concrete walk + sprint
- wood walk + sprint
- dirt/grass walk + sprint
- metal walk + sprint
- jump exertion
- soft/hard landing
- downed crawl body/cloth movement
- breathing / sprint breathing
- heartbeat/panic

Interactions:
- normal door open/close
- locked rattle
- exit lock/key
- heavy exit door
- generator start/loop/refuel
- workbench hammer/scrape
- water-pump squeak/clank
- pickup/crafting
- campfire loop

Monster cues:
- Tenant distant movement
- Tenant investigate/search
- Tenant proximity/freeze/attack
- Darkness whisper/crawl
- Darkness investigate/search
- Darkness attack/light recoil/retreat

Ambience:
- labyrinth room tone
- fluorescent/electrical hum
- forest dawn ambience variation
- forest day ambience
- forest dusk ambience variation
- forest night ambience
- wind
- branch snaps
- cabin ambience
- warehouse ambience
- gas-station ambience
- Labyrinth → Forest transition bridge/stinger

## P0 — Environment / navigation-safe art

Core sets:
- labyrinth wall/floor/ceiling modules
- emergency/maintenance light fixtures
- apartment kit
- security/metal doors
- cabin exterior/interior + porch
- forest terrain/tree/rock/stump/branch variants
- Forest entrance blocker/terrain transition

Navigation-sensitive props need simple collision proxies:
- Warehouse shelves/pallets/crates
- Abandoned House furniture/doorframes
- Gas Station pumps/counter/shelves
- generator/workbench
- hand water pump
- cabin porch and threshold

Reusable materials:
- clean/dirty concrete
- painted plaster
- tile
- aged wood
- rusty metal
- asphalt
- dirt/grass
- corrugated roof
- grime/blood/water-stain decals

## P0 — Front-end / loading

- final DON'T LOOK BACK logo
- mobile-safe logo
- 16:9 title key art
- portrait/narrow crop
- menu background/panel treatment
- button states
- Continue/New Game/Host/Join/Settings icons
- save/checkpoint icon
- loading/connecting spinner
- warning icon
- MENU icon
- app/adaptive icon + splash
- THE OUTSIDE loading plate

Front-end audio:
- focus/select/back
- warning
- save/autosave
- connection success/failure
- Ready/Unready/Start/Reconnect
- map transition stinger

## P1 — Survival props

- flashlight FP/world model
- generator
- campfire
- boiling pot
- workbench
- storage chest
- bed/table/chairs
- fuel can
- battery
- canned food
- clean/dirty water containers
- medkit
- bandage
- cloth
- scrap
- wood
- hand pump

## P1 — Exterior landmark props

Gas Station:
- pumps
- canopy/sign
- counter/shelving
- broken fridge/freezer
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

## P1 — Multiplayer / Journal UI

Multiplayer:
- ready/host/ping icons
- teammate health/downed/revive icons
- revive progress treatment
- reconnect icon
- player-color swatches
- lobby/session panel
- compact mobile variants

Journal:
- handwritten note
- maintenance memo
- receipt
- warning sheet
- ledger
- service card
- diary page
- torn/damaged variants
- optional photos/polaroids

## P2 — VFX / polish

- landing dust by surface
- flashlight dust
- fog volumes
- cold breath
- blood hit/bleeding decals
- infection feedback
- campfire sparks/smoke
- generator exhaust
- Darkness dissolve/light recoil
- Tenant shadow distortion
- wind-driven leaves
- loading fade/grain
- subtle dawn/dusk volumetric haze if performance allows
- cloud shadow treatment only if mobile budget allows

## Mobile + desktop constraints

- use one low-cost sky solution across desktop/mobile where possible
- avoid heavy volumetric clouds on mobile
- moon shadow remains optional/off on mobile
- sun shadow quality should be scalable later through graphics settings
- preserve night readability on low-brightness mobile displays
- avoid making ambient celestial light as strong as protective lights
- keep movement buttons readable and separated on narrow screens
- jump/landing animation must remain readable on remote co-op survivors
- use LODs for characters, monsters and vegetation
- use low-cost collision proxies
- keep transparency/overdraw limited
- reserve 4K textures for hero assets only

## Recommended integration order after v0.18.4

1. Production sky gradient + sun/moon discs + light cloud layer
2. Real footsteps + jump/landing + interaction SFX
3. Survivor model with walk/run/jump/downed/revive animations
4. Tenant final model + freeze/search/chase animation
5. Darkness final model + crawl/search/light-retreat
6. Labyrinth fixture/material/door pass
7. Cabin porch/threshold + shelter props
8. Forest vegetation/fog/day-night presentation pass
9. Branded title/loading art
10. Gas Station/House/Warehouse props
11. Multiplayer UI + VFX polish
