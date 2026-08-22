# DON'T LOOK BACK — Godot v0.60

First-person 2–4 player co-op survival horror for Godot 4.x with Ranger-first investigation, survival pressure, shared world progression, responsive desktop/mobile controls, persistent checkpoint snapshots, and host-owned multiplayer state where it matters most.

## Current build — v0.60 SHELTER AUTHORITY / NATIVE BUILD FOUNDATION

v0.60 does not add a new map or monster. It hardens co-op shelter spending, adds native export presets, and introduces an automated canonical-scene regression smoke so later gameplay updates have a stronger safety net.

### v0.60 changes

- Remote clients no longer consume Fuel/Wood/repair materials before host acceptance.
- Client inventory changes are mirrored to the host with ordered revisions.
- Pending inventory diffs are flushed before a shelter transaction.
- Host validates shelter target/range, downed state, current shelter state, and required resources.
- Host consumes the mirrored resource, mutates generator/campfire state, then sends authoritative touched-item counts back to the client.
- Generator repair can now use the same authoritative remote transaction path.
- Legacy v0.57 shelter RPC mutation is rejected so normal v0.60 clients cannot bypass the new transaction path.
- Added export presets: Web, Windows Desktop, Linux Desktop, Android Debug, Android Release.
- Android native target is arm64 and includes network permissions needed by native multiplayer.
- Added `tests/scene_regression_smoke.gd` for Forest, Mine, Labyrinth, Research Facility and key save/checkpoint/authority contracts.
- Added `.github/workflows/native-regression.yml` to export Linux release, Windows release, and Android Debug APK.
- Main menu/version now reports v0.60.

Authority limitation: the first remote inventory snapshot is still supplied by the peer. v0.60 prevents normal-client shelter double-spend/races and makes shelter mutation ordering host-owned, but it is not a competitive anti-cheat inventory server.

See `ASSET_DELTA_V060_AUTHORITY_NATIVE_TESTS.md` for asset impact and runtime validation.

## Canonical campaign route

1. **Ranger Forest** — stabilize the cabin/shelter and investigate the missing survey team.
2. **Abandoned House / Old Gas Station** — collect the opening clues in either order.
3. **Ranger Case Board** — synthesize Survey Manifest + Radio Trace.
4. **Warehouse** — recover the Maintenance Map.
5. **Water Pump** — optional anomaly evidence; grants stabilized Mine junction light.
6. **Old Mine** — choose UPPER/DEEP support-light routing and recover the Facility Access Badge.
7. **Labyrinth / Facility Level 03** — restore relays/systems, survive Lockdown, use checkpoint safe lamps.
8. **Restricted Research Facility** — inspect the routing terminal and reveal future anomaly routes.

Future Hospital, Museum, Laboratory, Cave, and other anomaly nodes remain deferred until the current authority/platform/gameplay foundation is stable.

## Core gameplay loop

**Prepare → Investigate → Expose yourself to danger → Recover evidence/resources → Survive the encounter → Unlock a deeper anomaly.**

Every survival system should create a horror decision. Systems that only create administration should be simplified rather than expanded.

## Horror identities

### The Tenant

Identity: **panic + observation**.

- stillness/panic rules can trigger the encounter;
- watched/freeze behavior remains core;
- panic increases pursuit pressure;
- flashlight contact can banish it after the existing hold requirement.

Do not turn Tenant into a generic sprinting enemy.

### Darkness Creature

Identity: **fear of losing protective light**.

- Darkness Exposure and loss of safe light drive the threat;
- light is the main counter;
- visual/audio identity must remain clearly different from Tenant.

### Pacing

Tenant and Darkness Creature use the major-threat budget introduced in v0.58. A completed major encounter creates RECOVERY space before another major encounter starts.

## Investigation

The current investigation rule is:

- important clues may be found in more than one order;
- collecting evidence is not always enough — important clues can require synthesis;
- optional evidence should provide tactical value, information, safety, or shortcuts;
- shared evidence progression is host-validated by scene/target/distance/state.

## Survival

Primary horror pressure:

- Health
- Flashlight Battery
- Darkness Exposure
- Panic

Secondary expedition pressure:

- Stamina
- Bleeding
- Temperature
- Radiation

Background survival:

- Hunger
- Thirst
- Infection

FOOD/WATER/MED use vulnerable timed actions rather than instant resolution. Movement/action input is blocked through the central gameplay-input lock while these actions or gameplay menus are active.

## Ranger Yard / shelter authority

Ranger Yard is protected only while generator or campfire protection is active.

v0.60 remote shelter transaction flow:

1. client inventory mutations are mirrored to host with a revision;
2. client flushes any pending inventory diff;
3. client requests generator fuel, campfire fuel, or repair;
4. host verifies the player is alive/not downed and physically near the correct equipment;
5. host verifies the current shelter state and required mirrored resource count;
6. host consumes the resource in its ledger;
7. host changes shared shelter state;
8. host returns authoritative counts for the consumed items;
9. client corrects its local inventory to the host result.

The client does not remove the shelter resource before acceptance.

The shared stash UI remains host-controlled in current co-op. Making every inventory acquisition/transfer fully server-owned is still a later hardening step.

## Checkpoint / finite-loot semantics

v0.59 checkpoint behavior remains canonical:

- checkpoint is a time snapshot, not only a transform;
- pre-checkpoint finite claims stay claimed;
- post-checkpoint finite claims roll back and respawn;
- corresponding post-checkpoint inventory also rolls back;
- each co-op peer restores its own checkpoint inventory/stats;
- shared world/progression/shelter/Arc 1/Mine power state rolls back together;
- normal map transitions do not trigger old checkpoint restores.

## Multiplayer

Target: **2–4 survivors**.

Current shared/host-owned areas include:

- world/objective state;
- primary monster state/damage for the main co-op horror systems;
- downed/revive/team wipe;
- host-led map transitions;
- finite pickup claims;
- evidence progression validation;
- Labyrinth relay validation;
- Mine power routing;
- v0.60 shelter resource transaction ordering/mutation.

Co-op difficulty should scale through separation, simultaneous decisions, rescue pressure, and resource demand — not monster HP inflation.

## Controls

Desktop:

- WASD — move
- Mouse — look
- Shift — sprint
- Space — jump
- E — interact/use
- F — flashlight
- B / 4 — battery
- 1 — food
- 2 — water
- 3 — medkit
- J — Journal
- M — co-op UI
- K — save
- L — load
- Esc — context/menu

Mobile:

- left joystick — move
- right swipe — look
- RUN / JUMP / USE / LIGHT / BATT / FOOD / WATER / MED
- JOURNAL / MENU

Viewport target remains 1280×720 with `canvas_items` stretch and `gl_compatibility` on desktop/mobile.

## Export / CI status

Committed presets:

- `Web`
- `Windows Desktop`
- `Linux Desktop`
- `Android Debug`
- `Android Release`

Godot command-line export is supported through named export presets. Windows uses `.exe`, Linux commonly uses `.x86_64`, and Android uses `.apk`. Android desktop-host setup requires JDK 17 and a configured Android SDK; the v0.60 native workflow provisions/validates that CI environment. Production Android release signing credentials are intentionally not stored in Git.

Web deploy remains handled by `.github/workflows/deploy-cloudflare-pages.yml`.

Native/regression validation is handled by `.github/workflows/native-regression.yml`.

## Regression smoke

`tests/scene_regression_smoke.gd` boots:

- Forest
- Mine
- Labyrinth
- Research Facility

It checks player/runtime anchors and key contracts for:

- NetworkManager v0.60 shelter authority;
- CheckpointSystem v0.59 wipe restore;
- SaveSystem checkpoint snapshot API;
- Mine power persistence API;
- required export preset names.

This is the first regression layer, not a replacement for manual host + 1/3 client and real Android testing.

## Current priorities after v0.60

1. validate shelter authority on host + 1 and host + 3 clients;
2. extend authoritative inventory ownership beyond shelter transactions where public-Internet hardening requires it;
3. make Shared Stash remote transfers host-transactional instead of host-only;
4. add automated checkpoint/finite-loot transaction tests, not only scene smoke;
5. add Android real-device performance/safe-area profiling;
6. deepen Labyrinth stages so each changes a gameplay rule;
7. add 3–4 player split/regroup objective pressure;
8. give Research Facility a real payoff encounter/choice;
9. consolidate monster brain/navigation/motor/network ownership;
10. replace recursive light discovery with authored protection/light registry;
11. production asset pass before major content expansion.

## Asset status

v0.60 adds **no mandatory runtime asset**.

New recommended production work:

- Android launcher/adaptive/monochrome icons;
- Windows `.ico` and Linux app icon;
- shelter transaction accepted/rejected SFX/UI feedback.

Existing P0 character/monster/flashlight/footstep/environment production assets remain higher priority. See `ASSET_DELTA_V060_AUTHORITY_NATIVE_TESTS.md` and `ASSET_BACKLOG.md`.

## Workflow

**ChatGPT → GitHub → Godot**

GitHub is the source-of-truth code layer. CI verifies parser/build/regression contracts; desktop and Android runtime playtests in Godot remain required before treating an update as release-ready.
