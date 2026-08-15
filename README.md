# DON'T LOOK BACK — Godot v0.18.3

First-person survival horror prototype for Godot 4.x with desktop + responsive mobile controls, LAN co-op, host-authoritative horror encounters, survival systems, persistent saves, Journal discoveries, separate Labyrinth/Forest maps, and runtime AI navigation/perception.

## v0.18.3 — Movement + Cabin + Forest Visibility

### Cabin entry fix

The cabin floor is slightly higher than the surrounding forest terrain. The old controller only used `move_and_slide()`, so the player capsule could stop on the floor lip even though the height difference was small.

v0.18.3 adds `MovementSystem`, which owns standing locomotion on both Labyrinth and Forest maps while the existing Player script continues to own survival, inventory, interaction, flashlight and HUD behavior.

Auto-step behavior:
- only works while grounded
- only attempts a step when forward movement is actually blocked
- checks upward clearance before lifting the body
- checks forward clearance from the raised position
- probes the target floor height before stepping
- maximum configured step height is `0.80 m`
- the effective limit is also clamped below half of the player's capsule height
- auto-step is disabled while airborne, dead, downed, in menus, during map loading, and before a co-op session starts

The Forest cabin also gets a small physical entry/porch step so the threshold is easier to cross even before final environment art replaces the placeholder geometry.

### Jump

Desktop:
- `Space` — Jump

Mobile:
- new responsive `JUMP` button

Jump tuning:
- jump velocity: `4.6`
- stamina cost: `8`
- short coyote time: `0.11 s`
- short jump buffer: `0.13 s`

Downed survivors cannot use normal jumping; v0.15 downed crawling remains a separate co-op state.

### Forest visibility

Forest night lighting has been raised without turning the whole forest into protective light.

Changes:
- brighter cool night background
- higher minimum Environment ambient-light energy
- low-cost cool moon-direction fill with shadows disabled
- subtle warm cabin-entry light below the protective-light threshold

The new ambient/moon lighting improves silhouettes of trees, roads, the cabin and landmarks. Darkness Exposure and the Darkness Creature remain dangerous because the added fill is not treated as a normal protective OmniLight safe zone.

### Mobile / desktop

`MobileControls` now uses `mobile_controls_v183.gd`, adding JUMP without removing existing controls. The button uses the same responsive sizing rules as USE/RUN/LIGHT/BATT and is hidden whenever gameplay input is externally blocked.

`MovementSystem` is shared by `main.tscn` and `forest.tscn`, so step/jump behavior does not diverge between maps.

## v0.18.2 retained — Main Menu Cursor

Desktop menus keep `Input.MOUSE_MODE_VISIBLE` while title, Join, Settings, confirmation and pause UI are open. Gameplay restores captured mouse-look.

## v0.18.1 retained — Separate maps

Maps:
- `res://scenes/main.tscn` — opening corridor, Apartment 03, Labyrinth
- `res://scenes/forest.tscn` — The Outside, cabin, forest and exterior landmarks

Leaving the final Labyrinth gate loads Forest through `MapTransitionSystem`. Player survival/inventory state is preserved and the Forest entrance becomes a checkpoint/autosave location.

Co-op map transitions are host-authoritative and late join synchronizes to the host's active map.

Save/Continue stores the active map and migrates older pre-map-split saves.

## AI + horror systems retained

v0.18 AI behavior:
- CHASE
- INVESTIGATE
- SEARCH
- PATROL
- runtime AStar3D waypoint graph
- hearing from walking/sprinting and noisy interactions
- host-authoritative AI in LAN co-op

The Tenant still freezes when watched. Darkness Creature still retreats from protective light.

## Survival systems

Stats:
- Health
- Hunger
- Thirst
- Stamina
- Flashlight Battery
- Darkness Exposure
- Cold Exposure
- Bleeding
- Infection

Resources include Food, Clean/Dirty Water, Medkit, Cloth, Bandage, Wood, Scrap, Fuel Can, Flashlight Battery and Firewood Bundle.

## Controls

Desktop:
- WASD — move / downed crawl
- Mouse — look
- Shift — sprint
- Space — jump
- E — interact / revive
- F — flashlight
- B or 4 — battery
- 1 — food
- 2 — water
- 3 — medical aid
- J — Journal
- K — Save World
- L — Load World while offline
- Esc — pause/menu

Mobile:
- left joystick — move / downed movement
- right swipe — look
- RUN
- JUMP
- USE
- LIGHT
- BATT
- FOOD
- WATER
- MED
- JOURNAL
- MENU

## Testing v0.18.3

Recommended test:
1. Pull latest `main`, open the existing project and press F5.
2. Confirm title-screen cursor still works from v0.18.2.
3. Start gameplay and verify `Space` jumps on desktop.
4. On mobile/editor mobile preview, verify the JUMP button appears and does not overlap USE/RUN.
5. Walk into small floor lips/thresholds; the player should step up automatically instead of stopping.
6. Verify walls/tall obstacles cannot be auto-stepped.
7. Transition to Forest and walk through the cabin entrance repeatedly from different angles.
8. Verify the porch threshold no longer blocks entry.
9. Test Forest at night with flashlight off: terrain/tree silhouettes should be readable, but the area should still feel dark and Darkness Exposure should continue increasing outside real protective light.
10. Test jump/step in two-device co-op and re-test downed crawl/revive.

## Asset status

Production needs are tracked in `ASSET_BACKLOG.md`. v0.18.3 adds requirements for jump/landing animation and SFX, step/foot-placement polish, a real cabin porch/threshold model, and night forest lighting/reference art.

## Current limitations

- Runtime F5 validation must still be performed on the development machine; the assistant environment does not contain the Godot executable.
- Auto-step is a lightweight collision solver, not full procedural foot IK.
- Final character models/animations, production audio, VFX and environment art are still missing.
- Forest/labyrinth navigation remains a hand-authored runtime waypoint graph rather than a baked NavigationMesh.
- Internet matchmaking/NAT traversal is not implemented; co-op remains LAN/IP based.
