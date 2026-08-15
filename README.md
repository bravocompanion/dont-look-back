# DON'T LOOK BACK — Godot v0.2

A small first-person horror prototype built for Godot 4.x.

## v0.2 — The Tenant
This version turns the original shadow scare into an actual gameplay threat.

### Playable features
- WASD first-person movement
- Mouse look
- F toggles flashlight
- E interacts with the hallway door
- Dark hallway made only from built-in Godot geometry
- Encounter now starts earlier, before the door
- The Tenant spawns behind the player
- The Tenant moves toward the player while it is not being watched
- Looking directly at The Tenant freezes it
- Solid geometry can block line of sight, so staring through the closed door does not freeze it
- Panic meter rises while the stalker closes in
- High panic causes unstable flashlight brightness
- Red panic overlay increases with danger
- The Tenant becomes faster at high panic
- Getting caught shows a death screen
- R restarts after being caught
- Reaching the end stops the stalker and completes v0.2

## Open/update in Godot
If you already cloned v0.1:
1. Open the local `dont-look-back` repository folder in GitHub Desktop or Git.
2. Pull the latest changes from `main`.
3. Open the same project in Godot.
4. Press **F5**.

For a new PC:
1. Clone `bravocompanion/dont-look-back`.
2. Open Godot 4.x.
3. Choose **Import** in Project Manager.
4. Select `project.godot` from the cloned folder.
5. Choose **Import & Edit**.
6. Press **F5**.

No external assets or plugins are required.

## Controls
- W A S D — Move
- Mouse — Look
- E — Interact
- F — Flashlight
- Esc — Release/capture mouse
- R — Restart after being caught

## Core rule
**If you stop watching The Tenant, it moves.**

You need to manage your view while moving down the hallway and opening the door. The goal of v0.2 is to test whether this rule creates enough tension before expanding the environment.

## GitHub workflow
This repository is the main source for the game. Future versions should be applied here so Godot only needs a normal Git pull instead of a new ZIP/project import.

## Recommended v0.3
- First explorable apartment room
- Key/item pickup system
- Small inventory
- Locked-door objective
- Environmental audio and footsteps
- Additional non-lethal horror events
