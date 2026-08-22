# DON'T LOOK BACK — Asset Backlog

Updated for **v0.57 — Stability / Host Authority / Input Lock**.

Current project state: gameplay/procedural systems are ahead of final production art and audio. v0.57 intentionally adds no mandatory production asset so stability work can land without expanding the asset surface.

Status legend:

- **AVAILABLE** — committed and usable now.
- **PROTOTYPE** — represented procedurally or with temporary content.
- **MISSING** — production asset still required.

---

# P0 — Character / Co-op Readability

## Survivor player

Status: **PROTOTYPE / MISSING production set**

Required:

- one production survivor base model;
- 3–4 clearly readable co-op outfit/color variants;
- first-person arms/hands rig;
- world/remote-player body;
- remote-player flashlight attachment;
- simple mobile LOD/collision representation.

Animation:

- idle;
- walk;
- sprint/run;
- strafe;
- jump/fall/landing;
- hit reaction;
- downed/crawl;
- revive giver/receiver;
- death.

---

# P0 — The Tenant

Status: **PROTOTYPE / MISSING final model + animation/audio/VFX**

Required final model:

- humanoid horror silhouette;
- rig suitable for observation/freeze and panic-driven pursuit;
- mobile LOD;
- simple collision proxy.

Animation/presentation:

- emergence/materialize;
- watched/freeze pose;
- low-panic stalk locomotion;
- medium/high-panic locomotion blend;
- attack/recovery;
- flashlight reaction;
- 3-second banish/dissolve.

Audio/VFX:

- emergence sting;
- movement/body-creak/footstep layer;
- breathing/proximity pressure;
- attack cue/impact;
- flashlight interference/burn reaction;
- banish/death release;
- low-overdraw distortion/dissolve.

Accessibility requirement:

- reaction visuals must support a future Reduce Flashing mode.

---

# P0 — Darkness Creature

Status: **PROTOTYPE / MISSING final production set**

Required:

- final creature model visibly distinct from Tenant;
- darkness emergence/materialization;
- pursuit/attack motion;
- light recoil;
- retreat/dissolve;
- mobile LOD;
- darkness/proximity/attack/light-recoil audio.

Identity rule: production art must reinforce that this creature is about **losing protective light**, not panic/observation.

---

# P0 — Flashlight / First-Person Equipment

Status: **PROTOTYPE / MISSING production models**

Required:

- first-person flashlight model;
- world/remote-player flashlight model;
- switch animation;
- battery replacement animation;
- idle/walk/sprint handling compatible with current procedural motion;
- jump/landing response;
- low-cost beam/dust presentation suitable for mobile.

Audio:

- switch on/off;
- battery insert/remove;
- electrical buzz/flicker variants;
- monster-interference layer.

---

# P0 — Core Environment Kit

## Labyrinth

Status: **PROTOTYPE / MISSING production kit**

Required:

- concrete/plaster/tile wall set;
- floor and ceiling materials;
- normal/roughness maps;
- industrial trims/conduit;
- dirty fluorescent/caged light fixtures;
- safe-light visual language;
- evacuation/fault lighting variants;
- apartment door;
- labyrinth metal/security door;
- exit/security gate.

## Mine

Status: **PARTIAL / PROTOTYPE**

Required production integration/dressing:

- reinforced shaft walls;
- timber/metal support variants;
- mine doors/gates;
- rail/cart/industrial clutter where useful;
- signage and warning decals;
- production light fixtures;
- interaction props matching evidence route.

Use authored scene anchors for gameplay-critical placement instead of baking important coordinates into code.

---

# P0 — Core Audio

Status: **PARTIAL / MISSING**

Footsteps:

- concrete;
- wood;
- dirt/grass;
- metal.

Monster audio:

- Tenant movement/breath/proximity/attack/reaction;
- Darkness emergence/proximity/attack/retreat;
- Warden/Mourner/Crawler as those systems receive production presentation.

Player:

- hurt variants;
- downed/revive feedback;
- death;
- interaction rejects/blocked action may reuse current UI feedback initially.

Pending committed-file targets still noted by the current runtime docs:

- `res://assets/audio/forest_night.mp3`
- `res://assets/audio/draw.mp3`
- `res://assets/audio/shoot.mp3`
- `res://assets/audio/impact.mp3`

---

# P1 — Ranger Cabin / Safe-Zone Production Pass

Status: **PROTOTYPE / MISSING polish**

Required/recommended:

- generator start/idle/failure/repair audio;
- generator production model states if current procedural representation remains temporary;
- campfire loop/extinguish audio;
- powered/unpowered cabin exterior light fixtures;
- protected/exposed shelter status emissive indicator;
- cabin dressing and survival storage props;
- low-cost night readability suitable for mobile.

---

# P1 — Forest Production Pass

Status: **PROTOTYPE / PARTIAL**

Required/recommended:

- final Ranger Cabin exterior/interior dressing;
- Abandoned House production pass;
- Old Gas Station production pass;
- Warehouse production pass;
- Water Pump anomaly dressing;
- tree/foliage variants with mobile LOD;
- terrain/ground material variants;
- fog/rain/storm presentation with performance tiers;
- ambient wildlife/forest audio.

---

# P1 — Hunting / Wildlife

Status: **PROTOTYPE / MISSING production content**

Required/recommended:

- first-person/world Hunting Bow;
- Arrow model;
- draw/release/impact presentation;
- Hunting Knife;
- harvest animation;
- wildlife locomotion;
- hit/flee/death animations;
- wildlife audio;
- low-cost mobile LODs.

---

# P1 — Isolation / Lockdown / Evacuation

Status: **PROTOTYPE / MISSING production kit**

Recommended:

- Maintenance/Flooded/Archive Isolation Node variants;
- active/shutdown/fault states;
- industrial housing/lever/breaker/core bank;
- conduit/warning labels;
- shutdown animation/audio;
- Lockdown interlock cover and release mechanism;
- temporary shutter model + animation/audio;
- evacuation-specific signage/lighting.

---

# P1 — Other Monsters

## Warden

Status: **PROTOTYPE / MISSING production set**

- broad/heavy industrial humanoid silhouette;
- patrol/pursuit/isolated-target acceleration;
- safe-light hesitation;
- attack/recovery;
- evacuation pursuit;
- heavy footsteps/body creak/breath/core pulse/attack audio.

## Mourner / Crawler

Status: **PROTOTYPE / MISSING production set**

Production work should begin only after current horror/authority foundation is stable and their gameplay identity is locked.

---

# P2 — Co-op / Loot Dressing

Status: **MISSING polish variants**

- POI loot-container variants;
- shared supply crates;
- stash variants;
- evidence containers;
- 3–4 player bonus-resource dressing;
- readable interaction emissive/decals that do not rely only on text.

---

# P2 — Narrative / Research Network

Status: **PLANNED**

- survey-team personal items;
- Foreman/miner story dressing;
- T-03 archive props;
- Research Facility routing-terminal production model/UI;
- evidence folders, tapes, samples, signage;
- future Hospital/Museum/Laboratory/Cave asset sets only when those maps enter active production.

---

# v0.57 Asset Delta

New required assets: **NONE**.

New recommended assets: **NONE required by code**.

The update changes stability, input ownership, and host validation. Existing production backlog remains the priority after technical validation.

See `ASSET_DELTA_V057_STABILITY_AUTHORITY.md` for the exact v0.57 validation checklist.
