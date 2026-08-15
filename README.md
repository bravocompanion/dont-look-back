# DON'T LOOK BACK — Godot v0.5

A first-person survival-horror prototype built for Godot 4.x.

## v0.5 — Light & Darkness
Light is now a survival resource rather than a cosmetic tool. The opening labyrinth still introduces The Tenant, while the second phase begins testing the long-term rule for the game: darkness itself can create danger.

### Flashlight battery
- Flashlight battery starts at 100%.
- The battery drains only while the flashlight is turned on.
- Low battery causes unstable brightness and flickering.
- At 0%, the flashlight switches off automatically.
- Replacement batteries are physical loot items.
- Press B or 4 to replace the current flashlight battery.
- Replacing a battery consumes one Flashlight Battery from the inventory.

### Darkness system
- DARKNESS Exposure still increases when the player has no protective light.
- Flashlight and nearby powered world lights reduce DARKNESS.
- The new Darkness Director watches exposure after the first chase area.
- At high DARKNESS, a Darkness Creature can form near the player.
- The Darkness Creature damages Health rather than killing instantly.
- Turning on a working flashlight or reaching a powered light makes the creature retreat and disappear.
- Spawn attempts use physics checks to prefer open, walkable locations near the player.

### The Tenant
The Tenant remains the unique monster of the labyrinth opening:
- It advances while the player is not watching it.
- It deals damage instead of instant death.
- Panic still destabilizes flashlight brightness.
- Its panic effect now combines with the flashlight battery system instead of overriding battery state.

### Survival systems retained from v0.4
- Health
- Hunger
- Thirst
- Stamina and sprint
- Stacked inventory
- Canned Food
- Bottled Water
- Medkit
- Apartment Exit Key

### New loot
Apartment 03/current survival area contains:
- 2 x Flashlight Battery
- Canned Food
- Bottled Water
- Medkit
- Apartment Exit Key

## Current gameplay flow
1. Enter the labyrinth hallway.
2. Encounter The Tenant.
3. Keep it in sight while moving toward the first door.
4. Survive hits using the Health system.
5. Reach the safe transition.
6. Search Apartment 03 for resources and the exit key.
7. Manage flashlight battery and DARKNESS Exposure.
8. Remaining in darkness too long can cause a Darkness Creature to appear.
9. Use light to force the creature away.
10. Unlock the exit and escape the current prototype.

## Controls
- W A S D — Move
- Mouse — Look
- Shift — Sprint
- E — Interact / pick up / unlock
- F — Flashlight on/off
- B or 4 — Replace Flashlight Battery
- 1 — Eat Canned Food
- 2 — Drink Bottled Water
- 3 — Use Medkit
- Esc — Release/capture mouse
- R — Restart after death

## Responsive HUD
The survival HUD uses anchored layouts and automatically switches to a compact arrangement on narrow screens. Desktop keeps the full control guide visible; narrow/mobile-sized layouts reduce text size and hide the desktop control legend to avoid overlap.

## Update in Godot
If the repository is already cloned:
1. Open GitHub Desktop.
2. Select `bravocompanion/dont-look-back`.
3. If GitHub Desktop reports local changes that would be overwritten, discard them only if you did not intentionally edit those files yourself.
4. Fetch origin and Pull origin.
5. Return to the existing Godot project.
6. Press F5.

No external assets or plugins are required for the current prototype. Monsters, survival pickups, footsteps, environmental knocks, and current geometry are built from Godot resources or built-in primitives.

## Direction after v0.5
- v0.6 — Labyrinth Expansion: a larger opening chapter, more loot routes, healing decisions, checkpoints, and stronger light puzzles
- Multiplayer foundation: authority/network-safe player state and co-op survival synchronization
- v0.7 — The Outside: first exterior survival area, shelter, stronger light dependency, and day/night foundation
