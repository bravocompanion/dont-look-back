# Asset Delta — v0.63 Light Contract / Threat Ownership

## Mandatory runtime assets

**NONE.**

v0.63 is a gameplay/authority pass. Existing procedural lights, flashlight, Tenant, and Darkness prototypes are sufficient to execute the new rules.

## Recommended P1 production assets

### Protective-light readability

- one consistent emissive language for **protective world lights** across Forest, Mine, Labyrinth, and Research Facility;
- powered / unpowered fixture variants that remain readable on mobile;
- subtle safe-light activation/deactivation audio;
- low-cost light-volume edge/falloff presentation where players need to judge whether they are actually protected;
- optional iconography for `WORLD LIGHT PROTECTED` vs flashlight-only protection in debug/accessibility UI.

### Darkness Creature

- production light-recoil animation;
- short light-contact hiss/burn cue;
- retreat/dissolve tail that clearly communicates the end of HUNT and start of RECOVERY;
- mobile-friendly low-overdraw dissolve/VFX.

### The Tenant

- flashlight-contact reaction that does **not** look like a safe-zone shield;
- world-light avoidance/freeze presentation distinct from Darkness recoil;
- proximity audio that can continue outside the protected world-light boundary without falsely implying safety.

## Accessibility / mobile constraints

- do not communicate protection only through rapid flashing;
- protective vs cosmetic lights need shape/audio/value differences that survive low brightness and small mobile screens;
- future Reduce Flashing mode must preserve protection readability without strobing.

## Not added in v0.63

Bandage receives no new animation/SFX requirement yet. Runtime Player currently has no real bleeding state/API, so a timed Bandage action is intentionally deferred rather than implemented as fake HP healing.

## Existing P0 remains unchanged

Production Survivor variants, FP hands, final Tenant, final Darkness Creature, FP/world flashlight, downed/revive/death animation, four-surface footsteps, monster audio, and Labyrinth/Mine environment production kits remain higher priority than v0.63-specific polish.
