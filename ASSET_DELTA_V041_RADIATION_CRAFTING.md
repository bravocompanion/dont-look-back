# Asset Delta — v0.41 Radiation Survival + Expanded Crafting

## Runtime status

No external production model/audio is required to boot the v0.41 logic. The current implementation uses procedural Godot geometry for the Anti-Radiation Tower and placeholder box meshes for new salvage resources.

The only new committed UI asset in this update is:
- `assets/ui/hud/icon_radiation.svg`

The existing Forest Night asset is still pending:
- `res://assets/audio/forest_night.mp3`

## P0 production assets

### Anti-Radiation Tower
- Base / anchor assembly.
- 4–6 m mast with structural braces.
- Electrical emitter head / coil.
- Generator power cable and cable connector.
- Control box with powered / no-power emissive states.
- Small warning placard / radiation signage.
- Damaged/offline variant for future failure events.

### Tower VFX
- Low-overdraw powered aura for mobile.
- Richer particle/energy pulse option for desktop.
- Emitter glow and subtle ground pulse.
- Optional outer boundary marker that communicates the 42 m protection radius without rendering a giant transparent dome.

### Player protection gear
- Ranger Raincoat model or clothing layer.
- Raincoat wet/dry material states.
- Radiation Suit model.
- Radiation hood/mask and filter canister.
- Radiation Suit gloves/boots.
- First-person sleeves/gloves where visible.
- Remote-player versions for multiplayer.

### New scavenging props
- Plastic Sheet / folded tarp.
- Rubber roll / gasket bundle.
- Electronics board / electrical control box.
- Lead Plate stack.
- Copper Wire coil.
- Industrial Filter cartridge.

### Crafting / workbench UI
- Survival category icon.
- Protection category icon.
- Weapons category icon.
- Infrastructure category icon.
- Recipe/material icons for the new components.
- Nine-slice workbench panel matching the existing Field Status style.

## P0 audio

- Geiger counter ticks with multiple intensity tiers.
- Radiation warning stinger for Day 3.
- Anti-Radiation Tower power-on sound.
- Tower continuous low electrical hum.
- Tower power-loss / shutdown sound.
- Electrical crackle / emitter pulse layer.
- Crafting: cloth, metal, electrical and heavy-construction sounds.
- Radiation storm/static ambience layer.
- Rain impacts on raincoat and radiation suit.

## P1 production assets

- Irradiated wildlife material variants for deer/rabbit/boar/wolf.
- Radiation-burn / contaminated foliage decals.
- Hazard tape, radiation warning signs and abandoned decontamination props.
- Decontamination shower model and VFX.
- Radiation medicine / injector prop.
- Portable Geiger counter model.
- Tower repair parts / fuse / transformer props.
- Electrical cable routing props around Ranger Base.

## Existing asset debt still active

- Production Tenant model and manual integration.
- Dedicated Forest Tenant/Warden threat assets and eventual spawner content.
- Darkness Creature production model.
- Ranger survivor variants for 2–4 players.
- Wildlife production models, animations, carcasses and blood decals.
- Hunting Bow, Arrow and Hunting Knife production models.
- House / Gas Station / Warehouse / Water Pump production environment kits.
- Old Mine and Research Facility production environment kits.
- Forest / wildlife / monster production SFX.

## Mobile requirements

- Tower aura must have a low-overdraw mobile mode.
- Avoid a full 84 m diameter transparent dome; use emitter pulse plus sparse boundary markers instead.
- Protection suits need reduced material count / texture sizes for mobile.
- Recipe icons should remain readable at approximately 20–28 px.
- Salvage props should use shared atlases/materials where possible.
