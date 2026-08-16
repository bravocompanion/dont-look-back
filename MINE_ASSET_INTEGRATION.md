# Integrasi Mine Asset Pack — Godot

Pack `Mine.rar` diintegrasikan sebagai art layer untuk Labyrinth Arc 1 tanpa mengganti collision, objective, save, atau authority multiplayer yang sudah berjalan.

## Runtime asset

- `assets/environment/mine/models/godot/Mines_Runtime.dae` — subset prop yang benar-benar dipakai oleh build runtime.
- `assets/environment/mine/models/godot/Mines_Modu_Runtime.dae` — subset modular runtime: elevator, door, button, rail, cable, wood support, dan metal beam.
- `assets/environment/mine/textures/` — 36 texture runtime yang direlink ke DAE; ukuran 128–256 px agar aman untuk mobile.

Godot runtime memakai DAE yang sudah direlink ke texture relatif. Arsip/source lengkap tetap dipertahankan pada paket `HorrorGame_Mine_Godot_Integration_v1.0.zip`, termasuk model sumber dan dokumentasi inventaris asset.

## Mapping game

### M-01 Maintenance
Generator, fuel can, barrels, wooden crates, shovel, pickaxe, mining helmet, fence, cable, dan wood support.

### F-02 Flooded Service
Mine wagon, rail, barrels, gravel/rocks, lantern, dan overhead cable.

### A-03 Archive
Locker, shelving, crates, tray, medical box, TNT, detonator, cable detonator, dan metal beam.

### L-04 Lockdown / extraction
Elevator, elevator door, elevator button, fence, box, dan rock debris.

Mine lamp mesh dipasang di sepanjang Arc 1 sebagai visual fixture saja. Realtime light tetap memakai lighting system existing agar mobile tidak terkena tambahan dynamic-light cost.

## Multiplayer

`MineAssetSystem` bersifat visual/deterministik dan berjalan lokal di setiap peer. Tidak ada state gameplay baru yang perlu disinkronkan. Objective, pickup, final exit, save/load, dan authority tetap memakai sistem existing.

## Mobile / desktop

- Tidak menambah shadowed realtime light.
- Tidak menambah collision dari imported mesh; collision existing tetap authoritative.
- Imported runtime scene dipakai sebagai shared mesh/material resource.
- Prop visual dinonaktifkan dari processing setelah dibuat.

## Asset yang masih dibutuhkan

P0 yang belum ditutup Mine pack:

- The Tenant production model + animation/reaction/dissolve.
- Darkness Creature production model + animation.
- Survivor player rig + variasi 2–4 pemain.
- First-person/world flashlight model + hand animation.
- Footstep SFX per surface.
- Monster/Tenant SFX + ambience tambang.
- Warden production model/animation/audio.
- Sector signage/decals M-01, F-02, A-03, L-04.

Mine pack menutup sebagian besar kebutuhan prop/environment industrial: rail, wood support, mine lighting fixture, generator, elevator, locker, medical box, fuel can, crates/barrels, wagon, tools, TNT/detonator, rocks/gravel, fence, dan cables.
