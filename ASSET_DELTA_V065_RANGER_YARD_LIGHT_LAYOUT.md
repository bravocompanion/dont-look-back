# Asset Delta — v0.65 Ranger Yard Lighting / Front Work Area

## Mandatory runtime assets

**NONE.**

v0.65 uses the existing procedural cabin, campfire, Cooking Rack and Water Boiler. The generator-lighting change is implemented with existing Godot lights and does not require a new texture, mesh, animation or audio file.

## Recommended P1 production assets

### Powered cabin / yard
- cabin ceiling bulb or practical lamp fixture with powered/unpowered emissive variants;
- porch lamp fixture with a readable warm powered state;
- one or two low-cost yard flood/work lamps that visually explain the wider generator light coverage;
- subtle generator electrical hum / relay-on cue;
- subtle light-on transient for cabin + porch, avoiding a harsh flash.

### Front-left campfire work area
- production Cooking Rack mesh with cookware hooks/grate;
- boiling kettle/pot production mesh;
- small preparation table/crate dressing beside the campfire;
- restrained steam VFX while boiling water;
- low-loop fire/cooking ambience that does not mask threat audio.

## Mobile / Web constraints
- keep only the cabin and porch practicals shadow-casting;
- yard/work-area fill lights remain shadowless;
- fill lights are visual-only (`non_protective_light`) so they do not enlarge threat protection beyond the authored Ranger Yard contract;
- avoid large transparent particle sheets for steam/fire dressing.

## Existing P0 unchanged
Final Survivor/co-op variants, FP hands, final Tenant, final Darkness Creature, survivor animation set, FP/world flashlight, four-surface footsteps, monster audio/VFX, and production Mine/Labyrinth environment kits remain pending.
