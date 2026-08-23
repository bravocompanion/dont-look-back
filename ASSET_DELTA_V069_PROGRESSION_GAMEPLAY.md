# Asset Delta — v0.69 Progression Gameplay Pass

## Mandatory runtime assets

**NONE.**

The v0.69 progression strip, XP bar and feedback toasts are built from native Godot Control nodes and reuse the existing survivor/profile systems.

## Recommended P1 polish

- compact Level / XP frame or badge that remains readable at mobile scale;
- small Talent Point and Stat Point indicators;
- restrained XP tick SFX;
- restrained level-up SFX with no arcade fanfare;
- subtle Knowledge discovered SFX;
- lightweight toast background/edge treatment;
- optional micro-icons for safe water, field treatment, wildlife harvest and fishing milestones;
- optional multiplayer survivor-build badge for lobby/profile presentation.

## Mobile / performance requirements

- XP HUD must stay readable at narrow portrait-equivalent widths without horizontal scrolling;
- no new 3D nodes, dynamic lights, particles or physics are required;
- toast presentation should remain short and non-blocking;
- any future SFX should be local UI audio and voice-limited;
- any future texture set should use one small atlas where practical.

## Existing P0 remains unchanged

1. final survivor base model;
2. 3–4 readable co-op variants;
3. first-person hands/arms;
4. final Tenant model/rig/animations/audio/VFX;
5. final Darkness Creature model/animations/audio/VFX;
6. first-person + world flashlight models;
7. downed/revive/death animation set;
8. concrete/wood/dirt-grass/metal footsteps;
9. core monster audio;
10. production Labyrinth/Mine environment, material and door kits.
