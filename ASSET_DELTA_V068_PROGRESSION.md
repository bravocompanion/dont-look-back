# Asset Delta — v0.68 Major Survivor Progression

## Mandatory runtime assets

**NONE.**

The complete first implementation uses generated Godot Control UI, text and existing game assets. Leveling, stats, talents and knowledge therefore do not block desktop, Android or Web builds on new art/audio.

## Recommended P1 UI assets

- 5 core-stat icons: Endurance, Fitness, Fortitude, Focus, Dexterity;
- 4 talent-tree icons: Survival, Scout, Technician, Investigator;
- 6 Knowledge-category icons: Survival, Technology, Wildlife, World, Threat, Anomaly;
- small XP/progression badge and compact progress-frame treatment;
- talent rank pip / node-state sprites readable at mobile scale;
- a small generic knowledge-discovered glyph;
- optional co-op survivor build badge/portrait overlays for later lobby presentation.

## Recommended P1 audio

- restrained level-up confirmation SFX;
- short talent-unlock SFX;
- subtle knowledge-discovered cue;
- optional page/tab movement sound for the Progression menu.

These cues should remain quieter than threat, proximity, generator and survival-critical audio.

## Recommended P1 animation / presentation

- subtle UI pulse on level-up and talent unlock;
- optional survivor rucksack/gear presentation continuing the v0.67 weight-system visual language;
- optional loaded-locomotion layer remains useful, but progression must not require new locomotion assets.

Avoid large RPG-style particle bursts or full-screen celebratory effects; they conflict with the horror tone.

## Mobile / Web requirements

- primary icon silhouette remains readable around 48–64 px;
- interactive allocation buttons retain at least ~44 px touch targets;
- no animated talent-tree shaders;
- no particle-heavy level-up effect;
- no additional dynamic 3D lights/shadows required;
- progression UI must remain vertically scrollable with no required horizontal scrolling.

## Existing P0 remains unchanged

Higher-priority production assets remain:
- final survivor base model and 3–4 readable co-op variants;
- first-person arms/hands;
- final Tenant model/rig/animations/audio/VFX;
- final Darkness Creature model/animations/audio/VFX;
- first-person + world flashlight;
- downed/revive/death animation coverage;
- concrete/wood/dirt-grass/metal footsteps;
- core monster audio;
- production Labyrinth/Mine environment, door and material kits.
