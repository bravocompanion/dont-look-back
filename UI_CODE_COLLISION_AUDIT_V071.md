# v0.71 — UI / Code Collision Audit

## Scope
Audit seluruh HUD/modal yang paling sering aktif bersamaan setelah v0.70, dengan fokus pada desktop/mobile layout, gameplay input ownership, dan wrapper/autoload yang memodifikasi state yang sama.

## Confirmed UI collisions found

### Progression feedback vs top survival status
v0.69 progression strip dimulai di Y=8, sedangkan canonical survival status bar menempati area paling atas. Keduanya benar-benar overlap.

### Progression toast vs primary objective
Toast v0.69 memakai Y=48/54 sementara canonical primary objective berada langsung di bawah status bar. Area keduanya overlap pada mobile dan desktop.

### Progression intel vs objective
v0.70 contextual intel mulai sekitar Y=92/98. Canonical objective masih berada pada area tersebut, terutama desktop.

### Mobile MENU vs top status
FrontEnd mobile MENU sebelumnya berada di Y=12 dan menutup bagian kanan top survival status.

## Confirmed code ownership collision found

### Inventory vs MovementSystem
Legacy Inventory menonaktifkan `Player.set_physics_process(false)`, tetapi locomotion runtime sekarang dimiliki oleh `MovementSystem` autoload. `GameplayInputLock` lama tidak mendaftarkan Inventory, sehingga membuka Inventory tidak menjamin MovementSystem berhenti.

v0.71 menghapus ownership Player physics/process dari Inventory dan memindahkan modal authority ke `GameplayInputLock`.

### Shared MobileControls external boolean
Inventory dan Progression Menu sama-sama menulis `MobileControls.set_external_blocked(true/false)`. Karena state itu boolean tunggal tanpa owner/reference count, satu menu dapat me-release block milik state lain pada transisi frame yang buruk.

v0.71 menghapus direct MobileControls ownership dari Inventory dan Progression Menu. MobileControls v184 sudah membaca `GameplayInputLock`, sehingga modal gameplay sekarang memakai central lock. FrontEnd tetap mempertahankan mobile block untuk pre-session/lobby state yang bukan modal gameplay biasa.

## v0.71 solution

### UIRuntimeCoordinator
New autoload `ui_runtime_coordinator_v71.gd` menjadi single geometry source untuk:
- top status reserve,
- progression XP/toast lane,
- BAG / MENU / PROG quick-button row,
- primary objective,
- contextual progression intel.

### Compact/mobile layout
1. Status: Y 5–51
2. Progression XP **or toast**: Y 58–94
3. BAG / MENU / PROG: Y 102–146
4. Objective: Y 154–198
5. Context intel: Y 206–256

Toast menggunakan rectangle yang sama dengan XP strip, sehingga keduanya tidak pernah menambah dua baris sekaligus.

### Desktop layout
- status tetap di top bar,
- objective menggunakan sisi kiri di bawah status,
- progression strip/toast menggunakan sisi kanan pada baris yang sama,
- contextual intel berada di bawah progression pada sisi kanan.

## Central modal ownership
`gameplay_input_lock_v71.gd` sekarang mencakup:
- Journal,
- Crafting,
- Shared Stash,
- Field Status,
- Inventory runtime,
- Progression Menu,
- FrontEnd.

Inventory dan Progression tetap acquire manual reason ketika dibuka untuk same-frame safety, kemudian release reason ketika ditutup.

## Compatibility
Unchanged:
- Level 1–30,
- progression save schema version 68,
- local progression profile path,
- v0.69 XP milestones,
- v0.70 talent intelligence,
- v0.67 weight inventory behavior,
- multiplayer authority,
- Tenant/Darkness/light contracts,
- canonical map/world state.

## Regression
`tests/ui_code_collision_regression_v71.gd` validates geometry and ownership at:
- 1280×720 desktop,
- 800×600 desktop,
- 430×800 mobile,
- 360×640 mobile.

It also verifies central lock coverage, Inventory ownership cleanup, Progression Menu ownership cleanup, toast lane replacement, mobile intel line clamp, save/profile compatibility, and active runtime wiring.
