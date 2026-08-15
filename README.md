# DON'T LOOK BACK — Godot v0.7

A first-person survival-horror prototype built for Godot 4.x.

## v0.7 — The Outside
The labyrinth is now the opening chapter rather than the end of the prototype. After restoring all three emergency relays and passing the final power gate, the player exits into the first outdoor survival region with the same Health, Hunger, Thirst, Stamina, Battery, Darkness, and inventory state.

### New outdoor region
- Large exterior forest test zone connected to the labyrinth ending.
- Old road leading away from the underground exit.
- First cabin/shelter base.
- Trees, boundaries, dark exploration routes, and scattered survival loot built from Godot primitives.
- The previous labyrinth ending screen is replaced by a seamless transition into the outside area.

### Day and night foundation
- Time begins in the late afternoon at approximately 16:30.
- A full in-game day currently takes about 12 real minutes for testing.
- Daylight, dusk/dawn, and night change the environment background and ambient lighting.
- Daylight acts as protective light outdoors.
- At night, natural protection disappears and Darkness Exposure becomes dangerous again.
- The existing Darkness Creature system therefore becomes much more important after sunset.
- Desktop HUD shows day number, time, phase, and Cold Exposure.
- Narrow/mobile-sized HUD uses a compact time + Cold display.

### Cold Exposure
- Cold rises outdoors at dusk and especially at night.
- Daylight gradually reduces Cold.
- A powered shelter reduces Cold much faster.
- High Cold drains Stamina.
- Maximum Cold eventually damages Health through exposure.

### First shelter
The cabin contains a generator that begins without fuel.

To secure the shelter:
1. Explore outside and find the Fuel Can.
2. Return to the cabin.
3. Look at the generator and press E.
4. The generator consumes the Fuel Can.
5. Interior and porch lights turn on.
6. The powered cabin becomes a protective-light zone.
7. A new checkpoint is saved inside the shelter.

If the player dies after powering the cabin, the existing checkpoint system restores the survival state at the shelter.

### New outside loot
- Fuel Can
- Flashlight Battery
- Bottled Water
- Canned Food
- Medkit

### Survival systems retained
- Health and non-instant monster damage
- Hunger
- Thirst
- Stamina and sprint
- Flashlight battery and replacement batteries
- Darkness Exposure
- Darkness Creature encounters
- Stacked inventory
- Canned Food / Bottled Water / Medkit use
- Labyrinth checkpoint
- Three-relay light puzzle

## Current gameplay flow
1. Begin in the original horror corridor.
2. Survive The Tenant.
3. Search Apartment 03 for the key and resources.
4. Enter the expanded labyrinth.
5. Restore Relay A, Relay B, and Relay C.
6. Use the emergency beacon checkpoint.
7. Pass the final powered gate.
8. Exit into the forest.
9. Find the cabin and Fuel Can before night.
10. Power the shelter generator.
11. Use the cabin light as the first survival base while managing Cold, Darkness, Health, Hunger, Thirst, and Battery.

## Controls
- W A S D — Move
- Mouse — Look
- Shift — Sprint
- E — Interact / pick up / activate
- F — Flashlight on/off
- B or 4 — Replace Flashlight Battery
- 1 — Eat Canned Food
- 2 — Drink Bottled Water
- 3 — Use Medkit
- Esc — Release/capture mouse
- R — Restart after death; an active checkpoint is restored automatically

## Responsive direction
The HUD already switches to a compact layout on narrow viewports. v0.7 also makes the new outdoor time/cold status responsive. Full touch controls and multiplayer-safe input are still future work; desktop keyboard/mouse remains the current playable control scheme.

## Update in Godot
If the repository is already cloned:
1. Open GitHub Desktop.
2. Select `bravocompanion/dont-look-back`.
3. If GitHub Desktop reports local changes that would be overwritten, discard them only when you did not intentionally edit those files yourself.
4. Fetch origin and Pull origin.
5. Return to the existing Godot project.
6. Press F5.

No external art/audio packs are required for the current prototype. The current world, monsters, shelter, relay devices, pickups, footsteps, and environmental audio use Godot resources or built-in primitives.

## Direction after v0.7
- v0.8 — Shelter & Crafting: storage, campfire, simple recipes, generator fuel duration, sleep/save interaction
- Multiplayer foundation: authority-safe player stats, synchronized pickups, co-op light protection, host/join flow
- Exterior expansion: abandoned structures, larger loot routes, water sources, and stronger night encounters
