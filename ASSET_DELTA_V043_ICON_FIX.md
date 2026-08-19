# Asset Delta — v0.43 Stable Item Icon Fix

## What changed

v0.43 does not generate or introduce new icon artwork. It fixes how the existing item atlas is delivered to runtime and how Inventory / Workbench / Shared Stash consume it.

The v0.42 embedded GDScript base64 pipeline (`scripts/icon_data/item_icon_data_00.gd` through `_12.gd`) has been removed from the active tree. Those large scripts were replaced by a one-shot binary atlas pipeline under `assets/ui/items/`.

Active item-icon data:
- `assets/ui/items/item_icons_v43.part00`
- `assets/ui/items/item_icons_v43.part01`
- `assets/ui/items/item_icons_v43.part02`
- `assets/ui/items/item_icons_v43.part03`
- `assets/ui/items/item_icons_v43.part04`
- `assets/ui/items/item_icons_v43.part05`
- `assets/ui/items/item_icons_v43.part06`
- `assets/ui/items/item_icons_v43.part07`

The eight parts reconstruct the existing 448x336 PNG atlas exactly once at startup. `ItemIconRegistry` caches each `AtlasTexture`; it no longer retries PNG decoding every UI refresh.

## Active UI consumers

- Inventory: `inventory_menu_system_v43.gd`
- Ranger Workbench: `crafting_system_v43.gd`
- Shared Stash: `stash_menu_system_v43.gd`
- Registry: `item_icon_registry_v43.gd`

Unknown future item IDs use one fallback cell and are reported only once per ID instead of spamming warnings every refresh.

## Existing icon coverage

Current gameplay item IDs covered include food, water, medicine, flashlight battery, generator fuel, wood, scrap, cloth, plastic sheet, rubber, electronics, lead plate, copper wire, filter, hunting/fishing materials, bow/arrows/knife/rod, Raincoat, Radiation Suit, Workbench, Stash, Generator, Campfire, Anti-Radiation Tower, evidence/map/badge utility icons and several special UI icons.

## No new required art for v0.43

No new model, texture, animation, VFX or audio asset is required specifically for this bug fix.

Future non-duplicate icon gaps remain outside this fix: deer, rabbit, boar, wolf, carcass, blood trail, fishing spot/bite, downed/revive, locked/unlocked route, facility terminal and several investigation evidence-state icons.

## Existing pending asset debt

- `res://assets/audio/forest_night.mp3` is still pending for the Forest 20:00–05:00 ambience system.
- Production Anti-Radiation Tower, Raincoat, Radiation Suit, wildlife, monster and environment assets remain as documented in earlier asset deltas.

## QA

After pulling v0.43, fully close and reopen Godot so the editor drops references to the deleted `scripts/icon_data/*.gd` files. Run F5 and verify:

1. Inventory rows show icons.
2. Workbench recipes show icons and do not continuously recreate/reapply them.
3. Shared Stash rows show matching icons.
4. Debugger does not continuously repeat icon decode/parser errors.
5. Startup output should contain at most one atlas-ready message plus at most one fallback message for each genuinely unmapped future item ID.
