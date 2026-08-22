# Asset Delta v0.53 — Wildlife Hard Speed Caps / Bow Sway

## Runtime changes

- Wildlife now has absolute horizontal movement caps in every authoritative AI state, not only wounded flee.
- Caps are enforced before movement, after collision sliding, and during multiplayer remote interpolation.
- Deer maximum horizontal speed: 2.64 m/s.
- Rabbit maximum horizontal speed: 3.36 m/s.
- Boar maximum horizontal speed: 3.00 m/s.
- Wolf maximum horizontal speed: 3.60 m/s.
- Wounded flee remains a 3-second response at +20% base movement speed, still bounded by the same species cap.
- Passive Deer/Rabbit proximity flee stays at base speed after the wound response.
- Hostile Wolf/Boar chase multipliers can request higher speed internally, but final movement is clamped to the species cap.
- Remote wildlife movement is step-limited by the same cap so network corrections cannot produce visual speed bursts.
- Bow draw sway now uses 150% stationary, 200% walking, and 350% sprinting amplitude relative to the original stationary draw sway.
- Sway still uses one smooth procedural camera layer; the 50% jump impulse and 30% full-draw zoom remain.
- v0.52 lying carcasses, Hunting Knife harvest, carcass claims, embedded arrows, bow audio hooks, and v0.51 Tenant night/light rules remain unchanged.

## Required new assets

None. v0.53 is a runtime/feel tuning update.

## Production assets still recommended

- Rigged Deer, Rabbit, Boar, and Wolf models with proper locomotion speeds matching gameplay caps.
- Walk/run/wounded-run animation sets whose root-motion or playback speed can be synchronized to the runtime cap.
- Per-species hit reaction and death/fall animations.
- Carcass/dead idle pose and Hunting Knife harvest animation.
- Bow first-person/world models plus draw/release animations.
- Flesh hit, death, harvest, bow draw/release, and arrow impact audio/VFX.
- Existing pending `res://assets/audio/draw.mp3`, `shoot.mp3`, `impact.mp3`, and `forest_night.mp3` if not yet added.

## QA

1. Shoot a Deer without killing it and verify horizontal movement never exceeds 2.64 m/s.
2. After 3 seconds, Deer must drop back to its normal 2.20 m/s movement behavior.
3. Repeat near trees/rocks and verify collision sliding cannot create a speed burst or orbit.
4. Verify Rabbit never exceeds 3.36 m/s, Boar 3.00 m/s, and Wolf 3.60 m/s.
5. In co-op, verify remote wildlife corrections also respect the same visual speed caps.
6. Verify v0.52 carcasses still fall, remain harvestable, and do not block player movement.
7. Draw the bow while stationary, walking, and sprinting and verify clear 150% / 200% / 350% sway tiers without oscillator jitter.
8. Verify release/cancel restores camera offsets/FOV normally.
