# Asset Delta — Ranger Safe Zone

## Layout terbaru
- Ranger yard: 30 x 30 meter (4x luas blockout 15 x 15 sebelumnya).
- Fence height: 2 meter.
- Front gate opening: sekitar 3 meter.
- Cabin tetap berada di dalam safe zone.

## Production assets yang dibutuhkan
### P0
- Modular wooden fence 2 m: straight 2 m / 4 m, corner, damaged variant, end post.
- Ranger gate 3 m: left/right leaf, hinge/post, latch/lock, open/closed states.
- Ranger cabin exterior + interior production model.
- Cabin collision proxy yang sederhana untuk mobile.
- Yard ground materials: packed dirt, mud, sparse grass, gravel path.
- Ranger base lighting: porch lamp, gate lamp, yard pole lamp.

### P1
- Generator production model + fuel can.
- Storage crates / locker / supply shelf.
- Workbench + research table.
- Evidence board / map board / notes / photographs.
- Radio base station + handheld ranger radio.
- Bed/cot, chair, desk, cabinet, first-aid box.
- Warning / research perimeter signage.

### P1 audio
- Fence/gate wood creak.
- Gate open/close/latch sounds.
- Cabin wood ambience.
- Generator loop/start/stop.
- Forest ambience inside safe yard and outside forest variants.

## Threat/resource rules
Production spawn points for monsters, wildlife, carcasses, blood trails, random loot, and resource caches must remain outside the 30 x 30 m RangerSafeZone. Fixed base infrastructure such as cabin, generator, workbench, radio, storage, evidence board, and cooking equipment may exist inside the yard.

## Performance
- Fence pieces should support batching/instancing.
- Prefer shared materials/texture atlases.
- Add simplified collision shapes rather than per-plank mesh collision.
- Prepare LODs for cabin/fence props visible from the forest, especially for mobile multiplayer.
