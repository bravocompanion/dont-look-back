# DON'T LOOK BACK — Godot v0.8

A first-person survival-horror prototype built for Godot 4.x.

## v0.8 — Shelter & Crafting
The cabin introduced in v0.7 is now a functional survival base instead of a permanent free safe zone. Fuel, fire, crafting, storage, and sleeping are all part of surviving the outdoor night.

### Generator fuel
- The shelter generator now has a real fuel supply that decreases while it runs.
- One Fuel Can adds roughly half of the current maximum tank.
- Interacting with a running generator uses another Fuel Can to refuel it.
- When fuel reaches zero, the cabin and porch lights shut off automatically.
- Powered cabin lights remain protective light against Darkness creatures.
- Generator state survives normal scene reloads during the current play session.

### Campfire
A campfire is placed outside the cabin.

- Loose Wood can be burned directly for a shorter duration.
- Crafted Firewood Bundles burn much longer.
- A lit campfire produces protective light.
- Standing near it rapidly lowers Cold Exposure.
- Fire duration appears on the responsive Shelter HUD.

### Gathering and crafting
New outdoor resources:
- Wood
- Scrap
- Additional reserve Fuel Can

The cabin now contains a workbench with two simple recipes. Each interaction performs the displayed recipe and then switches to the next recipe, so the system works with both keyboard interaction and future single-button mobile interaction.

Recipes:
- 2 Wood → Firewood Bundle
- 1 Wood + 2 Scrap → Flashlight Battery

### Storage chest
The shelter now has persistent session storage.

The chest alternates between two interaction modes:
- STORE — moves one survival supply from player inventory into the chest.
- TAKE — moves one stored supply back to player inventory.

The mode changes after each interaction and is shown in the interaction prompt. Key/story items are not included in automatic shelter storage.

### Sleeping
The cabin now contains a bed.

Sleeping is available during the night/very early morning. To sleep safely until 07:00, either the generator or campfire must contain enough remaining fuel to cover the night.

A successful sleep:
- Advances time to 07:00.
- Consumes the required generator/campfire fuel.
- Restores Stamina.
- Clears Darkness Exposure and Cold Exposure.
- Restores a small amount of Health if Hunger and Thirst are healthy enough.
- Consumes Hunger and Thirst according to sleep duration.
- Removes an active Darkness Creature.
- Saves the shelter checkpoint again.

### Responsive Shelter HUD
A second lightweight status line appears outdoors:
- Generator fuel percentage
- Campfire fuel percentage
- Number of items in shelter storage

On narrow/mobile-sized viewports it automatically switches to a compact `GEN / FIRE / BOX` display.

### Existing survival systems retained
- Health and non-instant monster damage
- Hunger and Thirst
- Stamina and sprint
- Flashlight battery
- Darkness Exposure
- Darkness Creature encounters
- Cold Exposure
- Day/night cycle
- Labyrinth checkpoints
- Emergency relay puzzle
- Outdoor cabin and forest

## Current gameplay flow
1. Begin in the horror labyrinth and survive The Tenant.
2. Search Apartment 03.
3. Restore all emergency relays in the expanded labyrinth.
4. Exit into the forest.
5. Gather Fuel, Food, Water, Batteries, Wood, and Scrap.
6. Power the cabin generator before darkness becomes dangerous.
7. Use the workbench to craft Firewood Bundles or replacement batteries.
8. Use the storage chest to protect spare survival supplies.
9. Keep the generator or campfire fueled through the night.
10. Sleep safely until morning when enough light fuel is available.
11. Repeat the explore → gather → return → prepare → survive loop.

## Controls
- W A S D — Move
- Mouse — Look
- Shift — Sprint
- E — Interact / pick up / activate / craft / store / sleep
- F — Flashlight on/off
- B or 4 — Replace Flashlight Battery
- 1 — Eat Canned Food
- 2 — Drink Bottled Water
- 3 — Use Medkit
- Esc — Release/capture mouse
- R — Restart after death; an active checkpoint is restored automatically

## Mobile/desktop direction
Gameplay interactions in v0.8 intentionally use the same single Interact action instead of requiring modifier keys for crafting or storage. HUD layouts continue to adapt to narrow viewports. Full on-screen movement/look/action controls are still a later implementation step.

## Update in Godot
If the repository is already cloned:
1. Open GitHub Desktop.
2. Select `bravocompanion/dont-look-back`.
3. If local changes would be overwritten, discard them only when you did not intentionally edit those files yourself.
4. Fetch origin and Pull origin.
5. Return to the existing Godot project.
6. Press F5.

No external art/audio packs are required for the current prototype. Current environments, interactables, monsters, pickups, and survival devices use Godot resources or built-in primitives.

## Direction after v0.8
- v0.9 — Exterior Expansion: abandoned buildings, water source, more loot routes, stronger night encounters
- Multiplayer foundation: host/join flow, authority-safe player state, synchronized pickups and shared shelter power
- Mobile controls: touch movement/look plus responsive Interact/Sprint/Flashlight/Inventory actions
