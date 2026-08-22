# Asset Delta — v0.64 Wildlife Flee Stability

## Mandatory runtime assets

**NONE.**

v0.64 is a physics/AI correctness pass. Existing procedural deer/wildlife and arrow visuals are sufficient for the fix.

## Recommended P1 wildlife feedback

- deer hit vocalization with restrained panic variation;
- wounded hoof/run loop that matches the real capped flee speed;
- wounded locomotion animation with readable limp/stress instead of animation playback that implies impossible speed;
- short skid/turn animation for obstacle avoidance;
- small blood-impact VFX distinct from the persistent blood trail;
- embedded-arrow pose/attachment polish so one or more arrows remain readable without clipping through the body.

## Mobile / performance constraints

- hoof and wounded audio should be distance-culled and voice-limited;
- blood VFX must remain low-overdraw on Android/Web;
- wounded turn/readability must not depend on motion blur;
- no additional physics bodies should be added solely for embedded-arrow visuals.

## Existing P0 remains unchanged

Final Survivor/co-op variants, FP hands, final Tenant, final Darkness Creature, survivor animation set, monster audio/VFX, FP/world flashlight, four-surface footsteps, and Labyrinth/Mine production environment kits remain higher priority than v0.64 wildlife polish.
