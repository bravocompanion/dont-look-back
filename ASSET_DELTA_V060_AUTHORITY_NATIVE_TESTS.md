# DON'T LOOK BACK — Asset Delta v0.60

## Multiplayer Authority / Native Builds / Regression Smoke

v0.60 adalah infrastructure + multiplayer-integrity pass. Tidak ada map, monster, atau weapon baru.

## New mandatory production assets

**NONE.**

Semua perubahan gameplay v0.60 berjalan dengan asset/procedural presentation yang sudah ada.

## New recommended assets

### P1 — Native app identity / packaging

Status: **MISSING production polish**

- Android high-resolution launcher icon;
- Android adaptive icon foreground;
- Android adaptive icon background;
- Android monochrome icon untuk launcher yang mendukung themed icons;
- Windows `.ico` production icon;
- Linux desktop/app PNG icon;
- optional splash/loading art yang tetap ringan untuk mobile.

Godot masih dapat memakai fallback icon sehingga asset di atas tidak memblokir CI/debug build, tetapi wajib dibereskan sebelum beta/public distribution.

### P1 — Shelter authority feedback

Status: **MISSING / text fallback available**

- subtle accepted-transaction click/confirmation SFX;
- rejected/resource-missing UI cue;
- generator repair shared confirmation cue;
- campfire/generator network interaction feedback yang tidak terasa seperti menu online.

Gameplay tidak boleh menunggu audio ini; HUD objective text tetap menjadi fallback.

## Existing P0 production assets still pending

- final Survivor base model + 3–4 readable co-op variants;
- first-person arms/hands rig;
- remote/world survivor body;
- FP + world flashlight models;
- survivor hit/downed/revive/death animation set;
- final The Tenant model, rig, freeze/stalk/chase/attack/light-reaction/banish presentation;
- final Darkness Creature model, light-recoil/retreat/dissolve presentation;
- core monster movement/proximity/attack audio;
- footsteps: concrete, wood, dirt/grass, metal;
- production Labyrinth material/environment kit;
- production Mine support/industrial dressing;
- apartment/labyrinth/security/exit door set.

## Existing P1 production assets still pending

- Ranger generator start/idle/failure/repair audio;
- campfire loop/extinguish audio;
- cabin powered/unpowered exterior fixtures;
- Ranger Case Board production presentation;
- consumable-use animation/audio;
- Mine UPPER/DEEP routing-console and support-light production kit;
- Hunting Bow / Arrow / Hunting Knife production set;
- wildlife animation/audio;
- Labyrinth isolation/lockdown interaction production kit;
- post-major-encounter recovery ambience.

## v0.60 validation checklist

1. Remote client Fuel Can is not removed before host acceptance.
2. Remote client Wood/Firewood Bundle is not removed before host acceptance.
3. Remote client generator repair consumes exactly 2 Scrap + 1 Electronics after host acceptance.
4. Duplicate shelter requests cannot spend the same mirrored resource twice.
5. Shelter request is rejected outside interaction range or while downed.
6. Legacy shelter RPC cannot bypass the v0.60 transaction path.
7. Inventory changes from normal gameplay are mirrored before shelter transaction processing.
8. Forest, Mine, Labyrinth, and Research Facility pass headless scene smoke.
9. Windows Desktop release export succeeds.
10. Linux Desktop release export succeeds.
11. Android Debug APK export succeeds in CI.
12. Android Release preset exists but production signing credentials remain external to Git.
13. Desktop/mobile HUD and touch controls do not regress.

## Asset conclusion

v0.60 adds **0 mandatory runtime assets**.

The only new production needs are packaging identity assets and optional shelter network feedback. Existing character/monster/environment/audio P0 work remains much more important than creating new v0.60-specific art.
