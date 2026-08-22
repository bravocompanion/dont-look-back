# DON'T LOOK BACK — Asset Backlog

Updated for **v0.60 — Shelter Authority / Native Build Foundation / Regression Smoke**.

Gameplay/procedural systems are still ahead of final production art/audio. v0.60 adds **no mandatory runtime asset**, but native distribution now makes app-identity packaging assets a visible production need.

Status:

- **AVAILABLE** — committed and usable.
- **PROTOTYPE** — procedural/temporary representation exists.
- **MISSING** — production asset still required.

---

# P0 — Survivor / Co-op Readability

Status: **PROTOTYPE / MISSING production set**

Required:

- one final survivor base model;
- 3–4 clearly readable co-op outfit/color variants;
- first-person arms/hands rig;
- world/remote-player body;
- remote flashlight attachment;
- mobile LOD/collision proxy.

Animation:

- idle/walk/sprint/strafe;
- jump/fall/landing;
- hit reaction;
- downed/crawl;
- revive giver/receiver;
- death.

---

# P0 — The Tenant

Status: **PROTOTYPE / MISSING final production set**

Required:

- final humanoid horror model + rig;
- watched/freeze pose;
- emergence/materialize;
- low-panic stalk locomotion;
- high-panic pursuit;
- attack/recovery;
- flashlight reaction;
- banish/dissolve;
- mobile LOD/collision proxy.

Audio/VFX:

- emergence sting;
- movement/body-creak/footstep layer;
- breathing/proximity pressure;
- attack cue/impact;
- flashlight interference/burn;
- banish release;
- low-overdraw distortion compatible with future Reduce Flashing mode.

---

# P0 — Darkness Creature

Status: **PROTOTYPE / MISSING final production set**

Required:

- final model clearly distinct from Tenant;
- darkness emergence;
- pursuit/attack motion;
- light recoil;
- retreat/dissolve;
- mobile LOD;
- emergence/proximity/attack/light-recoil audio.

Identity must communicate **loss of protective light**, not panic/observation.

---

# P0 — Flashlight / First-Person Equipment

Status: **PROTOTYPE / MISSING production models**

Required:

- first-person flashlight;
- world/remote-player flashlight;
- switch animation;
- battery replacement animation;
- idle/walk/sprint handling;
- low-cost beam/dust presentation for mobile.

Audio:

- switch on/off;
- battery insert/remove;
- buzz/flicker variants;
- monster-interference layer.

---

# P0 — Core Environment Kit

## Labyrinth

Status: **PROTOTYPE / MISSING production kit**

- concrete/plaster/tile wall set;
- floor/ceiling materials;
- normal/roughness maps;
- industrial trim/conduit;
- dirty fluorescent/caged fixtures;
- safe-light language;
- fault/evacuation lighting variants;
- apartment/labyrinth/security/exit door set.

## Mine

Status: **PARTIAL / PROTOTYPE**

- reinforced shaft walls;
- timber/metal supports;
- mine gates/doors;
- rails/carts/industrial clutter;
- warning decals/signage;
- production support lights;
- UPPER/DEEP routing consoles;
- powered/unpowered indicators;
- stabilized Water Sample junction-light variant.

Gameplay-critical placement should move toward authored scene anchors rather than hard-coded coordinates.

---

# P0 — Core Audio

Status: **PARTIAL / MISSING**

Footsteps:

- concrete;
- wood;
- dirt/grass;
- metal.

Monster/player:

- Tenant movement/breath/proximity/attack/reaction;
- Darkness emergence/proximity/attack/retreat;
- player hurt/downed/revive/death.

Existing pending file targets:

- `res://assets/audio/forest_night.mp3`
- `res://assets/audio/draw.mp3`
- `res://assets/audio/shoot.mp3`
- `res://assets/audio/impact.mp3`

---

# P1 — Ranger Cabin / Shelter

Status: **PROTOTYPE / MISSING polish**

- generator start/idle/failure/repair audio;
- production generator states;
- campfire loop/extinguish audio;
- powered/unpowered cabin exterior fixtures;
- protected/exposed status emissive;
- cabin survival/storage dressing;
- v0.60 shelter transaction accepted/rejected feedback.

Network feedback should stay subtle and diegetic; do not turn shelter interaction into an intrusive online-service UI.

---

# P1 — Forest / Investigation

Status: **PROTOTYPE / PARTIAL**

- final Ranger Cabin dressing;
- Abandoned House pass;
- Old Gas Station pass;
- Warehouse pass;
- Water Pump anomaly dressing;
- Ranger Case Board production model/presentation;
- evidence-added and clue-synthesis audio;
- foliage/terrain variants with mobile LOD;
- weather/fog/rain performance tiers;
- ambient wildlife/forest audio.

---

# P1 — Consumable Interaction

Status: **MISSING / HUD fallback active**

- first-person medkit treatment animation + SFX;
- food handling/eating animation + SFX;
- water drinking animation + SFX;
- interrupted-treatment cue;
- timing aligned to vulnerable gameplay channels.

---

# P1 — Mine Power Routing

Status: **PROTOTYPE**

- industrial UPPER/DEEP console meshes;
- lever/switch animation;
- powered/unpowered emissive states;
- support-light fixture model;
- relay click / transformer thunk;
- circuit hum variants;
- stabilized junction-light production pass.

---

# P1 — Native App Identity

Status: **MISSING production packaging**

Newly relevant in v0.60:

- Android high-resolution launcher icon;
- Android adaptive foreground;
- Android adaptive background;
- Android monochrome/themed icon;
- Windows `.ico`;
- Linux app/desktop PNG icon;
- optional lightweight splash/loading art.

Debug/native CI may use engine/project fallback icons. Final beta/public distribution should not.

---

# P1 — Hunting / Wildlife

Status: **PROTOTYPE / MISSING**

- FP/world Hunting Bow;
- Arrow model;
- draw/release/impact presentation;
- Hunting Knife;
- harvest animation;
- wildlife locomotion/hit/flee/death;
- wildlife audio;
- mobile LODs.

---

# P1 — Labyrinth Isolation / Lockdown

Status: **PROTOTYPE / MISSING production kit**

- Maintenance/Flooded/Archive control variants;
- active/shutdown/fault states;
- lever/breaker/core bank;
- conduit/warning labels;
- shutdown animation/audio;
- Lockdown interlock/release;
- shutters/signage/evacuation lighting.

---

# P2 — Co-op / Loot Dressing

Status: **MISSING polish variants**

- POI loot containers;
- shared supply crates;
- stash variants;
- evidence containers;
- 3–4 player bonus-resource dressing;
- readable interaction emissive/decals.

---

# P2 — Narrative / Research Network

Status: **PLANNED**

- survey-team personal items;
- Foreman/miner story props;
- T-03 archive props;
- Research Facility routing-terminal production UI/model;
- evidence folders/tapes/samples/signage;
- Hospital/Museum/Laboratory/Cave sets only after those maps enter active production.

---

# v0.60 Asset Delta

New mandatory runtime assets: **NONE**.

New recommended:

- P1 Android launcher/adaptive/monochrome icon set;
- P1 Windows/Linux app identity icons;
- P1 shelter authority accepted/rejected/repair confirmation feedback.

Existing P0 character/monster/flashlight/environment/audio production work remains higher priority than new v0.60-specific presentation.

See `ASSET_DELTA_V060_AUTHORITY_NATIVE_TESTS.md` for validation details.
