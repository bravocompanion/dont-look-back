# DON'T LOOK BACK — Godot v0.6

A first-person survival-horror prototype built for Godot 4.x.

## v0.6 — Labyrinth Expansion
The original hallway is now only the opening section. After Apartment 03 and the locked exit, the player enters a larger dark labyrinth that combines survival resources, Darkness Creatures, emergency lighting, a checkpoint, and a multi-step light puzzle.

### Expanded labyrinth
- The old prototype end wall is removed at runtime.
- A larger 20 x 36 meter labyrinth is generated beyond the Apartment 03 exit.
- The route uses alternating openings, turns, dead ends, and dark pockets.
- Dim emergency lights provide atmosphere but are intentionally too weak to count as protective light.
- Darkness Creatures can still form when DARKNESS Exposure becomes too high.

### Emergency relay puzzle
The final labyrinth gate has no power.

Three emergency relays are placed through the maze:
- Relay A — first maze section
- Relay B — middle section
- Relay C — final section

Press E on each relay to restore it. An activated relay turns on a strong protective OmniLight3D around that section of the maze. When all three relays are active, the final power gate disappears and the exit beacon turns on.

### Checkpoint
A green emergency beacon in the middle of the labyrinth acts as the first runtime checkpoint.

It stores:
- Player position and facing direction
- Health
- Hunger
- Thirst
- Stamina
- Flashlight battery
- Darkness Exposure
- Inventory contents and stack counts
- Flashlight on/off state

After death, press R normally. The scene reloads, but the CheckpointSystem detects the reload and restores the saved state at the emergency beacon. Relay progress is also preserved during that runtime session.

### Survival loot added to the maze
- Flashlight Battery
- Bottled Water
- Canned Food
- Medkit

These are placed on different sides of the zig-zag route, so resource collection can require entering darker pockets rather than simply following the shortest line to the exit.

### Systems retained
- Health-based monster damage
- Hunger and Thirst
- Stamina and Shift sprint
- Flashlight battery and replacement batteries
- DARKNESS Exposure
- Darkness Creature spawning
- The Tenant opening encounter
- Apartment 03 key objective
- Stacked inventory
- Procedural footsteps and distant knocking
- Responsive desktop / narrow-screen survival HUD

## Current gameplay flow
1. Survive The Tenant in the opening hallway.
2. Reach Apartment 03 and collect the exit key and survival resources.
3. Unlock the old exit door.
4. Discover that it leads deeper into the labyrinth instead of directly outside.
5. Manage battery and DARKNESS while navigating the expanded maze.
6. Restore Relay A, Relay B, and Relay C.
7. Reach the emergency beacon checkpoint in the middle section.
8. Collect optional food, water, medicine, and batteries from dark routes.
9. When all relays are online, follow the powered exit beacon.
10. Pass the final gate to complete v0.6.

## Controls
- W A S D — Move
- Mouse — Look
- Shift — Sprint
- E — Interact / pick up / activate relay / unlock
- F — Flashlight on/off
- B or 4 — Replace Flashlight Battery
- 1 — Eat Canned Food
- 2 — Drink Bottled Water
- 3 — Use Medkit
- Esc — Release/capture mouse
- R — Restart after death; restores the checkpoint if one has been reached

## GitHub / Godot update workflow
If the repository is already cloned:
1. Open GitHub Desktop.
2. Select `bravocompanion/dont-look-back`.
3. If GitHub Desktop reports local changes that would be overwritten, discard them only if you did not intentionally edit those files yourself.
4. Fetch origin and Pull origin.
5. Return to the existing Godot project.
6. Press F5.

No external assets or plugins are required. The expanded maze, relay panels, checkpoint beacon, lighting, monsters, and loot are generated from Godot resources and built-in primitives.

## Direction after v0.6
- v0.7 — The Outside: leave the labyrinth, exterior forest/cabin area, shelter and first day/night foundation
- Multiplayer foundation: network-safe survival state, player authority, co-op revive and shared light interactions
- Mobile controls: touch movement/look and survival action buttons on top of the responsive HUD foundation
