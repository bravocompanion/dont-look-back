# DON'T LOOK BACK — Asset Delta v0.22

This file records new/changed production-asset needs introduced by **v0.22 — FLASHLIGHT & LIGHTING FEEL**. Existing requirements in `ASSET_BACKLOG.md` remain active.

## P0 — First-person flashlight presentation

Need a production first-person flashlight setup that can visually support procedural sway without exposing prototype geometry.

Required:

- first-person flashlight model
- first-person survivor hand / forearm rig
- neutral one-hand flashlight grip
- optional two-hand support pose
- flashlight glass/lens material
- flashlight body roughness/metal wear variants
- world/remote-player flashlight version for co-op
- attachment/socket convention shared by survivor outfit variants

Animation requirements:

- idle breathing pose
- walk hand motion compatible with procedural beam sway
- sprint hand motion compatible with stronger procedural sway
- jump takeoff reaction
- landing compression/recovery
- battery replacement animation
- flashlight toggle/raise/lower optional
- damage flinch additive pose optional

Important implementation rule:

- animation should remain low amplitude because code already supplies procedural light sway
- do not bake large camera shake into first-person animation
- hand animation and code motion must be blendable rather than duplicating the same movement

## P0 — Flashlight audio

Need tactile flashlight sounds:

- power switch ON
- power switch OFF
- battery compartment open
- battery remove
- battery insert
- compartment close
- low-battery electrical tick/faint instability
- optional hand/grip cloth movement during sprint

Keep these short and mobile-friendly.

## P0 — Flashlight beam/VFX

Production beam presentation:

- subtle cone/beam texture or cookie
- soft hotspot center
- dirty lens variation optional
- lightweight dust particles visible mainly inside the beam
- low-battery beam instability variant
- mobile version with very low overdraw

Avoid heavy volumetric fog tied to every flashlight on multiplayer clients.

## P0 — Labyrinth dim fixture kit

The v0.22 code now gives dim fixtures subtle independent power drift and fault/evacuation instability. Final fixtures need visual states that match this behavior.

Required fixtures:

- dirty fluorescent strip
- caged maintenance bulb
- compact utility ceiling lamp
- damaged fluorescent strip
- broken/off fixture
- emergency wall fixture

Required states/material variants:

- OFF
- DIM STABLE
- DIM UNSTABLE
- FAULT FLICKER
- EVACUATION PULSE
- CRITICAL INSTABILITY
- PROTECTIVE / SAFE variant kept visually distinct

Normal dim variants must never visually imply a safe zone.

## P0 — Lighting fixture audio

Need spatial light/electrical layers:

- fluorescent hum loop
- ballast buzz
- short flicker click
- unstable electrical chatter
- power sag/down sound
- power recovery sound
- breaker-fault sputter
- evacuation relay pulse

Provide at least 3–4 small variations for repeated flicker events so the maze does not sound identical every time.

## P1 — Safe-light readability

Protective lights should be clearly distinguishable from ordinary dim lighting even at low mobile brightness.

Recommended assets:

- protected green/white industrial lens
- safe-light floor marking/decal
- checkpoint fixture body
- support-light powered state
- subtle stable hum distinct from broken maintenance buzz

Avoid relying only on color because phone displays, accessibility needs, and low brightness can reduce color readability.

## P1 — Mobile optimization

- first-person flashlight model should use a small texture set
- world flashlight needs LOD or simplified remote version
- no realtime shadow on decorative dim lamps
- flashlight shadow quality should be scalable through graphics settings later
- dust/beam VFX need a low-overdraw mobile variant
- reuse shared materials for repeated fixtures
- avoid unique 2K/4K textures for every lamp variant

## Production order after v0.22

1. First-person flashlight + hand rig
2. Idle/walk/sprint/jump/landing hand animation set
3. Flashlight switch + battery replacement audio
4. Dirty fluorescent / caged maintenance fixture family
5. Fault/flicker/emergency fixture material states
6. Spatial electrical hum/flicker audio set
7. Flashlight beam cookie + lightweight dust
8. Protective-light production fixture
9. Remote survivor/world flashlight model + attachment setup
10. Mobile LOD/low-overdraw pass
