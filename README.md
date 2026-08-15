# DON'T LOOK BACK — Godot v0.4

A first-person survival-horror prototype built for Godot 4.x.

## v0.4 — Survival Foundation
The project is transitioning from a short corridor horror prototype into a survival-horror game. The labyrinth remains the opening chapter, while light, resources, and player condition become long-term systems.

### New survival systems
- Health: 100 maximum health
- The Tenant now damages the player instead of instantly killing them
- The Tenant retreats briefly after landing a hit, giving the player a chance to recover
- Hunger decreases over time
- Thirst decreases faster than hunger
- Starvation/dehydration can eventually damage health
- Stamina system
- Hold Shift to sprint
- Sprint drains stamina and stamina regenerates when resting
- Low hunger/thirst slows stamina recovery
- Critical hunger/thirst reduces movement speed
- Darkness Exposure tracks how long the player remains without protective light
- Flashlight and nearby powered lights reduce Darkness Exposure
- High Darkness Exposure slows stamina recovery
- Inventory now supports stacked resources

### Survival resources
Apartment 03 now contains procedurally spawned resources:
- Canned Food — press 1 to eat; restores Hunger and a small amount of Health
- Bottled Water — press 2 to drink; restores Thirst
- Medkit — press 3 to use; restores Health

The existing Apartment Exit Key still works with the upgraded inventory system.

## Current gameplay flow
1. Enter the labyrinth hallway.
2. Encounter The Tenant.
3. Keep it in sight while moving toward the first door.
4. If it reaches you, you take damage instead of dying instantly.
5. Reach the safe transition.
6. Search Apartment 03 for the exit key and survival resources.
7. Manage Health, Hunger, Thirst, Stamina, and Darkness.
8. Unlock the exit and escape the current prototype.

## Controls
- W A S D — Move
- Mouse — Look
- Shift — Sprint
- E — Interact / pick up / unlock
- F — Flashlight
- 1 — Eat Canned Food
- 2 — Drink Bottled Water
- 3 — Use Medkit
- Esc — Release/capture mouse
- R — Restart after death

## Light philosophy
Light is becoming the central survival mechanic. v0.4 introduces Darkness Exposure and protective-light detection. A later Light & Darkness update will use this value to control monster activity, especially outside the labyrinth.

## Update in Godot
If the repository is already cloned:
1. Open GitHub Desktop.
2. Select `bravocompanion/dont-look-back`.
3. If GitHub Desktop reports local changes that would be overwritten, discard them only if you did not intentionally edit those files yourself.
4. Fetch origin and Pull origin.
5. Return to the existing Godot project.
6. Press F5.

No external assets or plugins are required for the current prototype. Survival pickups, footsteps, environmental knocks, and the current geometry are generated with Godot resources or built-in primitives.

## Direction after v0.4
- v0.5 — Light & Darkness: batteries, light fuel, darkness-driven monster activity
- v0.6 — Labyrinth Expansion: larger opening chapter, loot, healing, checkpoints
- v0.7 — The Outside: first exterior survival area, shelter, day/night foundation
