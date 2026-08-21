# Asset Delta — v0.45 Hold-to-Draw Bow

## Implemented without new required assets
- Hold left mouse to draw bow; release to fire.
- Mobile HOLD HUNT button uses press/release behavior.
- Draw power affects projectile speed, effective range, stamina cost and damage.
- Small procedural aiming sway while drawing, with stronger sway when holding past full draw.
- Draw HUD shows power, damage preview and range preview.
- Physical projectile and v0.44 80% recovery / 20% break behavior retained.
- Wildlife now uses real HP pools: Rabbit 45, Deer 150, Wolf 190, Boar 260.
- Hit feedback reports remaining HP and actual impact damage.

## Production P0 assets recommended
- First-person hunting bow model with string and nocked-arrow sockets.
- World/remote-player bow model for multiplayer.
- Draw-start, draw-loop, full-draw tension and release animations.
- Arrow nock/release animation and hand poses.
- Bow string creak/tension loop with pitch/intensity layers.
- Bow release / string snap SFX.
- Arrow fly-by / whistle SFX.
- Existing v0.44 wood, dirt, metal impact SFX, break SFX and pickup SFX remain needed.

## P1 polish
- Bow draw hand tremor animation driven by sway strength.
- Full-draw breathing / stamina feedback.
- Wildlife hit reaction animation proportional to damage.
- Wildlife wounded locomotion animation and richer blood-trail VFX.
- Optional animal health debugging overlay for development only; production HUD should not expose enemy HP unless design later requires it.

## Existing pending asset
- `res://assets/audio/forest_night.mp3` remains pending for the Forest 20:00–05:00 ambience system.
