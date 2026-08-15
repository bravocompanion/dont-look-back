# DON'T LOOK BACK — Godot v0.3

A first-person horror prototype built for Godot 4.x.

## v0.3 — Apartment 03
This version expands the original hallway chase into a small exploration objective.

### Playable features
- WASD first-person movement and mouse look
- F toggles flashlight
- E interacts with doors and items
- The Tenant still moves only while it is not being watched
- Panic system and unstable flashlight at high panic
- The first chase ends after the player reaches the safe side of the first door
- First explorable apartment room: Apartment 03
- Interactable Apartment Exit Key
- Three-slot inventory HUD
- Locked exit door that requires the key
- Key is consumed when the exit is unlocked
- Procedurally generated player footstep sounds
- Procedurally generated distant environmental knocks
- Non-lethal room hallucination scare with light flicker
- Extended hallway and final escape section
- R restarts after being caught

## v0.3 gameplay flow
1. Move down the hallway.
2. The Tenant appears behind you.
3. Keep it in sight while opening and passing the first door.
4. Once through the safe transition, search Apartment 03.
5. Entering the apartment triggers a non-lethal hallucination.
6. Find the Apartment Exit Key on the table and press E to pick it up.
7. Return to the hallway.
8. Use the key on the locked exit door.
9. Pass through the door and reach the final trigger.

## Controls
- W A S D — Move
- Mouse — Look
- E — Interact / pick up / unlock
- F — Flashlight
- Esc — Release/capture mouse
- R — Restart after being caught

## Update in Godot
If the repository is already cloned:
1. Open GitHub Desktop.
2. Select `bravocompanion/dont-look-back`.
3. Fetch origin and Pull origin.
4. Return to the same Godot project.
5. Press F5.

No external assets or plugins are required. Geometry, scare figures, the key, footsteps, and ambient knocks are generated with Godot resources or built-in primitives.

## Core rule
**If you stop watching The Tenant, it moves.**

v0.3 adds a second kind of tension after the chase: entering an apparently safe room and searching it while the environment behaves incorrectly.

## GitHub workflow
This repository remains the main source for the game. Future versions should continue to be applied here so the local Godot project only needs a normal Git pull.

## Recommended v0.4
- Horror Director with randomized scare selection
- Flashlight battery and replacement batteries
- More apartment rooms
- Notes/story fragments
- Better monster navigation for multi-room spaces
- Save/checkpoint system
- Main menu and settings
