# DON'T LOOK BACK — v0.22 FLASHLIGHT & LIGHTING FEEL

## Goal

Make the first-person flashlight feel hand-held rather than welded to the camera, while keeping camera motion restrained for desktop and mobile comfort.

## Flashlight motion states

### Idle

- continuous low-amplitude breathing sway
- about 0.42 degrees vertical and 0.26 degrees horizontal at the base state
- tiny local position drift
- breathing becomes slightly less stable as stamina/health fall or panic/darkness rises

### Walking

- breathing remains active
- step-driven vertical bob
- horizontal hand sway
- small roll component
- substantially calmer than sprint

### Sprinting

- larger vertical and horizontal beam movement
- stronger roll and local hand-position displacement
- flashlight cone widens slightly while sprinting
- camera itself is not given equivalent large bob, reducing motion sickness

### Looking around

- flashlight has short rotational inertia
- fast mouse/touch turns make the beam lag behind the camera by a few degrees
- lag recenters smoothly rather than snapping
- maximum lag is clamped so the beam remains controllable

### Jump / landing

- takeoff gives a small upward-hand response
- landing gives a short downward flashlight kick based on impact speed
- neither effect rotates the gameplay camera

### Stress response

Procedural micro-instability increases from:

- low stamina
- low health
- flashlight panic
- high darkness exposure

The response is bounded so the flashlight remains usable.

### Mobile

All procedural flashlight movement is automatically scaled to about 74% of desktop amplitude.

This keeps the effect readable on phones without excessive screen-motion discomfort.

## Beam behavior

The active full-battery runtime baseline is:

- SpotLight energy: **6.7**
- range: 13 m
- angle: 28 degrees

`FlashlightMotionSystem` applies the 6.7 energy baseline to the Player at runtime, so the same full-battery output is used in both the Labyrinth and Forest even if an older scene resource still contains the previous prototype value.

v0.22 additionally:

- shortens range gradually below roughly 22% battery
- slightly widens the cone during sprint
- leaves energy/flicker ownership in Player so battery and panic systems do not conflict with the motion controller
- low-battery and panic multipliers scale downward from the new 6.7 full-battery baseline

## Labyrinth light feel

The original Labyrinth dim ambience remains below the protective-light threshold.

v0.22 adds:

- subtle independent power drift between fixtures
- faster instability during breaker/power faults
- stronger unstable pulse during reverse evacuation
- faster response during EVACUATION CRITICAL
- hard upper clamp of 0.098 energy for registered dim ambience

This preserves the core rule:

**A light can help you see without making you safe.**

Protective checkpoint/support/extraction lights remain intentionally brighter and are not converted into dim ambience by this pass.

## Runtime architecture

`FlashlightMotionSystem` is created by the existing `FrontEndSystem` wrapper.

No new autoload entry is required in `project.godot`.

This is deliberate to avoid adding another `project.godot` merge/pull conflict.

## Test checklist

Desktop:

1. Stand still and watch a wall edge — beam should breathe slightly.
2. Confirm a fresh/full battery uses energy 6.7.
3. Walk forward — beam should bob more than idle.
4. Sprint — beam should clearly become less stable without large camera shake.
5. Flick mouse left/right — beam should lag and recover smoothly.
6. Jump — small takeoff motion should appear.
7. Land from a jump — short landing kick should appear.
8. Drain stamina — hand instability should increase subtly.
9. Take damage — instability should increase but remain controllable.
10. Reach low battery — beam range and output should reduce while existing battery flicker still works.
11. Replace the battery — output should return to the 6.7 baseline.
12. Trigger an Archive breaker fault — old-maze dim lights should become much less stable without becoming protective.
13. Reach evacuation — dim lights should pulse differently from the red/orange evacuation strobes.
14. Transition to Forest — full-battery output should remain at the same 6.7 baseline.

Mobile:

1. Repeat idle/walk/sprint with touch controls.
2. Confirm sway is visibly reduced compared with desktop.
3. Swipe camera quickly and confirm short beam inertia.
4. Confirm USE/LIGHT/BATT controls are unaffected.
5. Verify acceptable comfort and performance at phone resolution.

## Runtime validation status

Static code audit completed. Godot executable is not available in the assistant environment, so F5/runtime validation must be performed on the development machine.
