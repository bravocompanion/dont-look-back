# Deep Audit — Forest Falloff v0.74.2

## Scope

Audit fokus pada kasus pemain jatuh/keluar dari Forest setelah terrain v0.74/v0.74.1, termasuk solo, mobile/desktop, return dari Old Mine, dan multiplayer.

## Root causes ditemukan

### 1. World-readiness Forest salah

`MapTransitionSystem v2` menganggap Forest siap hanya jika `OutsideWorld/ForestGround` ada.

Masalahnya: `ForestGround` lama hanya menutup area cabin, sementara spawn return dari Old Mine adalah sekitar `(-94, 0.92, -334)`. Jadi pemain dapat ditempatkan di deep forest sebelum `ForestTerrainV74` dan collision expanded-map selesai dibuat.

Perbaikan:

- `map_transition_system_v3.gd`
- Forest baru dianggap siap jika:
  - `ForestTerrainV74` ada,
  - `TerrainCollision` aktif,
  - `TerrainSafetyUnderlayV742` ada,
  - `UnderlayCollision` aktif.

### 2. Locomotion bukan dimiliki `Player._physics_process()`

`MovementSystem` mematikan physics process Player lalu menjalankan `move_and_slide()` dari autoload.

Akibatnya, proteksi yang hanya bergantung pada Player atau timing map terpisah bukan titik kontrol paling kuat.

Perbaikan:

- `movement_system_v44.gd`
- Setelah inherited locomotion selesai menjalankan `move_and_slide()`, sistem langsung memanggil `ForestWorldExpansion.enforce_player_safety_v742(player)`.
- Jalur ini sama untuk desktop dan mobile.

### 3. Recovery v0.74.1 terlalu bergantung pada Y absolut

v0.74.1 memakai emergency threshold sekitar `Y=-5.2`. Ini bisa membiarkan pemain terlihat jatuh cukup jauh sebelum recovery dan tidak langsung mendeteksi penetrasi terrain pada bukit/lereng.

Perbaikan:

- v0.74.2 membandingkan origin pemain terhadap `sample_terrain_height_v74(x,z) + half_player_height`.
- Jika pemain turun terlalu jauh di bawah permukaan yang seharusnya, recovery terjadi segera.
- Global emergency Y tetap dipertahankan sebagai fallback terakhir.

### 4. Boundary wall tidak cukup sebagai satu-satunya containment

Walau v0.74.1 sudah memakai dinding 24 m, collision edge masih tidak boleh menjadi single point of failure.

Perbaikan:

- hard horizontal clamp di dalam map bounds setelah locomotion,
- velocity outward dibatalkan saat clamp terjadi,
- physical boundary wall tetap dipertahankan sebagai lapisan normal pertama.

### 5. Terrain trimesh perlu hardening

Perbaikan:

- `ForestTerrainV74` collision layer/mask dibuat eksplisit,
- `ConcavePolygonShape3D.backface_collision = true`,
- ditambahkan underlay collision tak terlihat di bawah legal terrain minimum.

Underlay tidak dipakai untuk berjalan normal. Fungsinya hanya sebagai final catch jika trimesh contact gagal.

### 6. Multiplayer menerima transform Forest yang sudah invalid

Host sebelumnya hanya memvalidasi finite transform dan maksimum perubahan langkah. Transform pertama atau transform yang masih memenuhi step limit dapat tetap berada di luar/bawah Forest.

Perbaikan:

- `network_manager_v61.gd`
- host menolak Forest transform yang:
  - melewati map bounds,
  - terlalu jauh di bawah sampled terrain,
  - terlalu tinggi secara tidak masuk akal dari terrain.

## Defense layers v0.74.2

1. Terrain collision utama.
2. Backface collision pada terrain.
3. Boundary StaticBody 24 m.
4. Post-`move_and_slide()` hard clamp.
5. Terrain-relative fall detection.
6. Last-known-safe recovery.
7. Invisible safety underlay.
8. Transition readiness gate.
9. Multiplayer remote-transform validation.

## Automated regression

File: `tests/forest_falloff_regression_v742.gd`

Test mencakup:

- expanded terrain ready,
- terrain collision aktif,
- backface collision aktif,
- underlay aktif,
- edge kiri,
- edge kanan,
- edge dekat,
- edge jauh,
- vertical fall recovery,
- deep mine-return spawn,
- MovementSystem integration,
- MapTransitionSystem integration,
- NetworkManager integration.

Workflow native regression memakai Godot 4.7.2 dan sekarang menjalankan test ini sebelum native exports.

## Runtime test matrix yang tetap perlu dicek di perangkat

- Solo desktop: sprint + jump ke empat sisi map.
- Solo desktop: kembali dari Old Mine ke Forest.
- Mobile: analog movement terus ditekan ke boundary sambil sprint/jump.
- Host: kembali dari mine lalu bergerak di Warehouse/Mine area.
- Client: join host saat host berada di Forest deep zone.
- Client: bergerak ke boundary dan cek remote avatar pada host.
- Stress: spam jump di lereng, lembah, dan sambungan trail.

## Asset impact

Tidak ada asset baru wajib. Semua perubahan v0.74.2 berupa runtime physics, transition gating, locomotion containment, network validation, dan automated regression.
