# Deep Audit — v0.64 Deer / Wildlife Flee Stability

## Reported reproduction

Deer appears to run extremely fast and rotate/circle after being shot twice.

## Confirmed runtime chain

- `SurvivalSystem` attaches the Ranger Forest survival runtime.
- v0.63 runtime ultimately loads `wildlife_animal_v53.gd`.
- Wildlife is simulated only by offline/host authority. Network clients spawn `remote_controlled` animals and interpolate host state.
- Bow projectile collision/damage is also host-authoritative while online.

## Findings

### 1. Primary root cause — embedded recoverable arrows were physics obstacles

`forest_arrow_projectile_v46.gd` calls the parent `resolve_impact()` before attaching an intact arrow to living wildlife.

The parent makes a recoverable arrow a `StaticBody3D` on collision layer 1 and enables its recovery collision shape. The arrow then follows the animal every frame as if embedded.

Wildlife is a `CharacterBody3D` using normal world collision on layer/mask 1. This allows the moving deer to collide with the static physics body that is visually attached to itself.

Result:

1. deer attempts wounded flee;
2. embedded arrow moves with deer;
3. deer collides/slides against that arrow collider;
4. wounded steering tries to correct away from the hunter;
5. repeated slide/correction creates rotation, orbit/ping-pong and apparent speed bursts;
6. a second intact embedded arrow makes the feedback loop substantially worse.

### 2. Why the problem is especially visible after two full-power shots

Current deer health is 150 HP. Current maximum full-draw bow damage is 72.

Two maximum hits deal 144 total damage, leaving the deer alive at 6 HP. Each non-lethal hit refreshes the 3-second wounded flee response.

Therefore the second hit is the exact state where:

- the deer is still alive;
- wounded flee is refreshed;
- one or potentially two recoverable arrow bodies may be following it;
- collision correction pressure is highest.

v0.64 deliberately does **not** change this damage balance.

### 3. Secondary instability — collision correction could replace flee heading too aggressively

v0.53 already hard-caps deer horizontal speed at 2.64 m/s, so there is no intentional second-hit speed multiplier stack.

However, after `move_and_slide()`, the inherited wounded code may immediately replace the next flee direction when collision sliding reduced distance from the shooter. Near trees, rocks, fences or an embedded-arrow collider, this can create fast alternating headings even though numerical velocity remains capped.

The rapid direction changes can visually read as a speed burst because the body rotates and slides over short arcs every physics frame.

### 4. No evidence of one projectile applying damage twice

Authoritative arrow simulation sets `flight_active = false` before invoking `on_arrow_projectile_hit()`. Damage processing is host-only. The audited path therefore does not show a single arrow repeatedly applying hunting damage after impact.

### 5. Multiplayer ownership is already single-authority for wildlife

The host/offline authority simulates wildlife. Online clients configure wildlife as `remote_controlled` and do not execute local wildlife physics; they interpolate host transforms. The reported issue is therefore not caused by host and client both running deer locomotion.

## v0.64 fix

### Embedded arrows

New `forest_arrow_projectile_v64.gd`:

- attached recoverable arrows use interaction-only collision layer 2;
- interaction ray can still recover them;
- normal wildlife/player movement does not treat them as world obstacles;
- an explicit physics collision exception is added between arrow and attached wildlife in the impact frame, covering the deferred-layer transition.

### Wounded steering

New `wildlife_animal_v64.gd`:

- repeat hits refresh wound duration but never stack flee speed;
- previous flee heading is briefly locked after a repeat hit;
- heading turn rate is bounded;
- body yaw turn rate is bounded;
- obstacle avoidance chooses the better wall tangent and locks it briefly instead of re-solving left/right every frame;
- horizontal velocity is still clamped to the existing species cap before and after `move_and_slide()`.

## Balance intentionally unchanged

- Deer max HP: 150
- Deer base speed: 2.2 m/s
- Wounded multiplier: 1.20
- Deer hard cap: 2.64 m/s
- Maximum full-draw damage: 72
- Wounded flee duration per non-lethal hit: 3 seconds

## Manual verification matrix

1. One full-power hit on deer.
2. Two full-power hits on the same deer — primary reproduction.
3. Two recoverable arrows embedded in the same living deer.
4. Second hit while deer is already turning around a tree.
5. Hit next to a fence / Ranger Yard boundary.
6. Three hits / lethal transition and corpse pose.
7. Repeat hit from approximately the same direction.
8. Repeat hit from the opposite side.
9. Host + one client, host shoots deer twice.
10. Host + one client, client shoots deer twice.
11. Two peers shoot the same deer close together.
12. Verify remote deer interpolation does not exceed the same apparent speed cap.
13. Android touch bow draw/release.
14. Web and native desktop builds.

Automated scene regression covers runtime wiring and contracts, but real two-shot physics behavior still requires the above interactive Godot test matrix.
