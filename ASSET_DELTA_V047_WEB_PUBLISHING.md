# Asset Delta — v0.47 Web Publishing Foundation

## New mandatory production assets

None.

v0.47 is a build/deployment infrastructure update. It does not require new models, textures, icons, animation, or audio to function.

## Existing assets that now matter for Web export size

The Cloudflare Pages pipeline enforces the platform's 25 MiB maximum for each generated static asset. As production content grows, prioritize Web-friendly asset budgets:

- compress large texture sources and avoid shipping unused high-resolution variants;
- prefer appropriately compressed `.ogg` audio for long ambience/music when practical;
- keep mobile/desktop visual assets reusable instead of duplicating equivalent large textures;
- verify imported mesh/material data does not unnecessarily inflate the Web `.pck`;
- keep optional large media outside the core Web pack if it is not needed at startup.

## Existing pending assets unchanged

- production first-person/world Hunting Bow model and draw/release animation set;
- production Arrow model and impact/break/recovery SFX;
- final wildlife models/rigs/hit reactions;
- production Tenant/Darkness Creature/survivor assets;
- `res://assets/audio/forest_night.mp3` remains pending unless supplied separately.

## Publishing-specific QA

After GitHub Actions generates a Web artifact, validate in desktop and mobile browsers:

- menu fits viewport;
- touch controls fit phone/tablet viewport;
- mouse capture works after browser interaction;
- WebGL rendering and flashlight remain readable;
- Inventory/Workbench/Stash icons load;
- audio starts correctly after user gesture;
- single-player Forest gameplay can enter and run;
- no generated `.wasm`, `.pck`, or other static file exceeds the Cloudflare Pages limit.

Browser multiplayer is not part of the v0.47 asset delta; the current ENet transport requires a future WebSocket/WebRTC networking pass.
