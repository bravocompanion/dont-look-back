# Asset Delta — v0.30 Flashlight Curve

## Gameplay lighting update

- Flashlight range remains 65 m.
- Full flashlight energy is now 9.5 while battery is 75–100%.
- Below 75% battery, flashlight energy decreases proportionally with remaining battery.
- Existing low-battery flicker continues below 22%.
- Existing panic flicker remains active.
- Full-darkness ambient floor remains 5%.

## Required new assets

No mandatory new assets are required for this update.

## Optional production assets

- Flashlight lens/cookie texture tuned for the stronger 9.5 beam.
- Subtle beam dust/fog visual for desktop.
- Lightweight/no-particle beam variant for mobile.
- Flashlight world model and first-person model with emissive lens.
- Optional battery-state emissive indicator texture/material.

## Performance note

The existing 65 m spotlight with shadows should be tested on mobile devices. If needed, keep gameplay range at 65 m but disable or reduce flashlight shadows in mobile quality settings rather than reducing beam reach.
