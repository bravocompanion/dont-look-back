# DON'T LOOK BACK — Godot v0.18.4

First-person survival horror prototype for Godot 4.x with desktop + responsive mobile controls, LAN co-op, host-authoritative horror encounters, survival systems, persistent saves, Journal discoveries, separate Labyrinth/Forest maps, runtime AI navigation/perception, and a dynamic Forest day/night lighting cycle.

## v0.18.4 — Dynamic Sun + Moon Lighting

Forest celestial lighting now follows the existing world clock instead of using a mostly fixed directional light.

Clock behavior:
- around `06:00` the sun reaches the horizon and begins rising
- around `12:00` the sun reaches its highest point and strongest intensity
- around `18:00` the sun returns to the horizon and fades out
- around `00:00` the moon reaches its highest point

The sun is a moving `DirectionalLight3D`:
- its pitch changes with simulated solar elevation
- its yaw moves across the sky through the day
- low sun uses warmer orange/red light
- high sun becomes brighter and more neutral
- sun shadows are enabled only while the sun has meaningful intensity

The moon uses a second moving directional light on the opposite side of the orbit:
- moonlight rises as daylight disappears
- maximum moonlight remains intentionally dim
- moon shadows remain disabled for mobile performance
- moonlight is not an OmniLight and therefore does not become a Darkness protective safe-zone source

Environment lighting also follows the cycle:
- night keeps the cool blue-gray v0.18.3 readability floor
- sunrise/sunset adds a restrained warm twilight tint
- daytime ambient energy increases with the sun
- nighttime receives only a small moon-related ambient lift

The existing `game_minutes`, save/load time state, day counter, cold system and host-synchronized outside time remain the source of truth, so loading a saved Forest world restores the matching sun/moon position for that saved clock time.

## v0.18.3 retained — Movement + Cabin + Forest Visibility

### Cabin entry fix

The cabin floor is slightly higher than the surrounding forest terrain. `MovementSystem` owns standing locomotion on Labyrinth and Forest while Player continues handling survival, inventory, interaction, flashlight and HUD.

Auto-step behavior:
- only while grounded
- only when forward movement is blocked
- verifies upward and forward clearance
- probes destination floor height
- configured maximum `0.80 m`
- effective height is clamped below half of the player capsule
- disabled while airborne, dead, downed, in menus, loading, or before co-op START

The Forest cabin also has a small physical entry/porch step.

### Jump

Desktop:
- `Space` — Jump

Mobile:
- responsive `JUMP` button

Jump tuning:
- velocity `4.6`
- stamina cost `8`
- coyote time `0.11 s`
- jump buffer `0.13 s`

Downed survivors continue using the separate v0.15 crawl controller.

### Forest visibility baseline

Night remains more readable than the earlier pitch-black version through environment ambient lighting and the dim moon fill. v0.18.4 now moves that moon light with the world clock.

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

## Testing v0.18.4

Recommended test:
1. Pull latest `main`, open the existing Godot project and press F5.
2. Continue or reach the Forest map.
3. Watch the Forest lighting while the clock advances; the sun direction should visibly move over time.
4. Around morning/evening verify the directional light becomes lower, weaker and warmer.
5. Around noon verify stronger neutral daylight and more readable tree/landmark shadows.
6. At night verify the sun is effectively off and cool moonlight replaces it at much lower intensity.
7. Verify moonlight does not stop Darkness Exposure by itself and does not repel the Darkness Creature like a real protective OmniLight.
8. Save at one Forest time, reload, and verify the restored clock produces a matching celestial lighting state.
9. Test on mobile and verify night remains readable while moon shadows stay disabled.
10. Re-test cabin entry, jump, auto-step, map transition and two-device co-op after the lighting change.

## Asset status

Production needs are tracked in `ASSET_BACKLOG.md`.

v0.18.4 adds priority needs for a visible sun/moon sky presentation, sunrise/day/dusk/night sky gradients or procedural sky material, cloud layers, and lighting-reference art that keeps the gameplay distinction between ambient celestial light and true protective lights.

## Current limitations

- Runtime F5 validation must still be performed on the development machine; the assistant environment does not contain the Godot executable.
- The dynamic sun/moon currently affects directional/environment lighting but does not yet render a final visible sun disc, moon disc, stars or production sky/cloud system.
- Moon shadows are intentionally disabled for performance.
- Auto-step remains a lightweight collision solver, not procedural foot IK.
- Final character models/animations, production audio, VFX and environment art are still missing.
- Forest/labyrinth navigation remains a hand-authored runtime waypoint graph rather than a baked NavigationMesh.
- Internet matchmaking/NAT traversal is not implemented; co-op remains LAN/IP based.
