# Asset Delta — v0.67 Weight Inventory

## Mandatory runtime assets

**NONE.**

The weight system is data/UI/locomotion logic and reuses the existing inventory interface and item representations.

## Recommended P1 polish

- small backpack/weight HUD icon for LOADED / HEAVY / OVERWEIGHT states;
- production survivor backpack/rucksack model with desktop/mobile-friendly LOD;
- restrained pack/gear rustle loop when heavily loaded;
- heavier breathing variation while sprinting in HEAVY state;
- optional loaded locomotion animation layer that does not change collision or authority;
- consistent item weight icon/typography in Inventory and Stash screens.

## Mobile / performance requirements

- no physics bodies are added by the carry system;
- carry weight is derived from existing inventory dictionaries and refreshed at low frequency for HUD presentation;
- weight readability must fit narrow mobile inventory rows without horizontal scrolling;
- audio polish must be voice-limited and distance-independent because it belongs only to the local survivor.

## Existing P0 remains unchanged

Final survivor/co-op variants, FP hands, final Tenant, final Darkness Creature, survivor animation set, monster audio/VFX, FP/world flashlight, four-surface footsteps, and Labyrinth/Mine production environment kits remain higher priority than weight-system polish.
